"""config.py — Parametres de l'application via pydantic-settings.

Les variables sont chargees depuis le fichier .env (dev) ou depuis les
variables d'environnement (prod Railway/Render).
"""

from __future__ import annotations

from functools import lru_cache
from typing import List

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configuration globale de l'API ExamBoost."""

    # ─── Base de donnees ────────────────────────────────────────────
    # Defaut : SQLite local. En prod, surchargee par la variable d'env.
    DATABASE_URL: str = "sqlite:///./examboost.db"

    @field_validator("DATABASE_URL", mode="before")
    @classmethod
    def _validate_db_url(cls, v):
        """Rejet des URLs non-SQLAlchemy (ex: env sandbox 'file:...').

        Si la valeur fournie ne commence pas par un scheme SQLAlchemy
        reconnu, on retombe sur le SQLite local par defaut. Cela evite
        un crash au demarrage dans les environnements ou DATABASE_URL est
        definie pour un autre runtime.
        """
        if isinstance(v, str):
            v = v.strip()
            valid_prefixes = (
                "sqlite://",
                "postgresql://",
                "postgresql+psycopg://",
                "mysql://",
                "mysql+pymysql://",
                "oracle://",
                "mssql://",
            )
            if v and not v.startswith(valid_prefixes):
                # URL invalide -> fallback silencieux vers SQLite local
                return "sqlite:///./examboost.db"
        return v

    # ─── Securite JWT ───────────────────────────────────────────────
    SECRET_KEY: str = "change-me-in-production-please-use-a-32-char-min-secret"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 jours

    # ─── CORS ───────────────────────────────────────────────────────
    # Accepte soit une liste JSON, soit une chaine separee par virgules
    CORS_ORIGINS: List[str] = ["*"]

    # ─── Admin par defaut ───────────────────────────────────────────
    ADMIN_EMAIL: str = "admin@examboost.tg"

    # ─── Parametres BKT par defaut ──────────────────────────────────
    BKT_P_LEARN: float = 0.20
    BKT_P_SLIP: float = 0.10
    BKT_P_GUESS: float = 0.20
    BKT_MASTERY_THRESHOLD: float = 0.85

    # ─── Seuil de donnees pour activer XGBoost ──────────────────────
    MIN_RESPONSES_FOR_ML: int = 100

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    @field_validator("CORS_ORIGINS", mode="before")
    @classmethod
    def _parse_cors(cls, v):
        """Accepte une liste JSON ou une chaine separee par virgules."""
        if isinstance(v, str):
            v = v.strip()
            if v.startswith("["):
                import json

                return json.loads(v)
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v


@lru_cache()
def get_settings() -> Settings:
    """Retourne une instance unique de Settings (cachee)."""
    return Settings()


settings = get_settings()
