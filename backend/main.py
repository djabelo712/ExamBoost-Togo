"""main.py — Point d'entree FastAPI de l'API ExamBoost Togo.

Lance en local : ``uvicorn main:app --reload``
Swagger UI : http://localhost:8000/docs
ReDoc      : http://localhost:8000/redoc
"""

from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import settings
from database import init_db
from routers import auth, predict, questions, sessions


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Cree les tables au demarrage et tente un seed leger."""
    init_db()
    # Tentative de seed silencieux si la base est vide
    try:
        from scripts.seed_db import seed_if_empty

        seed_if_empty()
    except Exception:
        # En echec (ex: scripts non disponibles en prod), on continue
        pass
    yield


app = FastAPI(
    title="ExamBoost Togo API",
    description=(
        "API backend d'ExamBoost Togo — preparation intelligente aux "
        "examens nationaux (BEPC, BAC1, BAC2). Inclut IRT 3PL, BKT, "
        "SM-2 et prediction XGBoost du score attendu a l'examen."
    ),
    version="0.1.0",
    contact={
        "name": "ExamBoost Togo",
        "url": "https://github.com/djabelo712/ExamBoost-Togo",
    },
    license_info={"name": "MIT"},
    lifespan=lifespan,
    openapi_tags=[
        {"name": "auth", "description": "Authentification JWT (register/login/me)"},
        {"name": "questions", "description": "Banque de questions (BEPC/BAC)"},
        {"name": "sessions", "description": "Sessions de revision (SM-2 + BKT)"},
        {"name": "predict", "description": "Prediction du score / risque de decrochage"},
    ],
)

# ─── CORS ────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Routes ──────────────────────────────────────────────────────────
@app.get("/health", tags=["meta"], summary="Healthcheck")
def health() -> dict:
    """Healthcheck simple pour Railway/Render."""
    return {"status": "ok", "service": "examboost-backend", "version": "0.1.0"}


@app.get("/", tags=["meta"], summary="Racine de l'API")
def root() -> dict:
    """Redirige vers la documentation Swagger."""
    return {
        "name": "ExamBoost Togo API",
        "docs": "/docs",
        "redoc": "/redoc",
        "openapi": "/openapi.json",
    }


app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(questions.router, prefix="/questions", tags=["questions"])
app.include_router(sessions.router, prefix="/sessions", tags=["sessions"])
app.include_router(predict.router, tags=["predict"])
