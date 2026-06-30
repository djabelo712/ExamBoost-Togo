"""routers/auth.py — Authentification (register / login / me).

JWT via python-jose, hashing bcrypt via passlib.
"""

from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from config import settings
from database import get_db
from models import schemas
from models.db_models import User
from services import auth_service


router = APIRouter()


def _to_user_out(user: User) -> schemas.UserOut:
    """Convertit l'ORM User en schema UserOut."""
    return schemas.UserOut(
        id=user.id,
        email=user.email,
        nom=user.nom,
        prenom=user.prenom,
        niveau_scolaire=user.niveau_scolaire,
        serie=user.serie,
        etablissement=user.etablissement,
        ville=user.ville,
        date_inscription=user.date_inscription,
        theta_irt=user.theta_irt,
        total_sessions=user.total_sessions,
        total_questions_answered=user.total_questions_answered,
        bkt_maitrise=user.bkt_maitrise or {},
    )


# ─── Dependency : utilisateur courant ────────────────────────────────
def get_current_user(
    token: Optional[str] = Depends(auth_service.oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Dependance FastAPI qui verifie le JWT et renvoie l'User ORM."""
    credentials_exc = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide ou absent",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not token:
        raise credentials_exc

    payload = auth_service.decode_access_token(token)
    if payload is None:
        raise credentials_exc

    user_id = payload.get("sub")
    if not user_id:
        raise credentials_exc

    user = db.get(User, user_id)
    if user is None:
        raise credentials_exc
    return user


def get_admin_user(user: User = Depends(get_current_user)) -> User:
    """Restriction aux administrateurs."""
    if not user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acces reserve aux administrateurs",
        )
    return user


# ─── Routes ──────────────────────────────────────────────────────────
@router.post(
    "/register",
    response_model=schemas.Token,
    status_code=status.HTTP_201_CREATED,
    summary="Inscription d'un nouvel eleve",
)
def register(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    """Cree un compte eleve et renvoie un JWT immediat.

    Le premier compte cree devient automatiquement admin (pratique pour
    le bootstrap en dev). En production, on force ``ADMIN_EMAIL`` depuis
    l'environnement.
    """
    # Email deja pris ?
    existing = db.execute(
        select(User).where(User.email == payload.email.lower())
    ).scalar_one_or_none()
    if existing is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Un compte existe deja avec cet email",
        )

    is_admin = (db.execute(select(User)).first() is None) or (
        payload.email.lower() == settings.ADMIN_EMAIL.lower()
    )

    user = User(
        email=payload.email.lower(),
        password_hash=auth_service.hash_password(payload.password),
        nom=payload.nom,
        prenom=payload.prenom,
        niveau_scolaire=payload.niveau_scolaire,
        serie=payload.serie,
        etablissement=payload.etablissement,
        ville=payload.ville,
        is_admin=is_admin,
        bkt_maitrise={},
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = auth_service.create_access_token(
        subject=user.id,
        extra_claims={"email": user.email, "is_admin": user.is_admin},
    )
    return schemas.Token(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        user=_to_user_out(user),
    )


@router.post(
    "/login",
    response_model=schemas.Token,
    summary="Connexion eleve",
)
def login(payload: schemas.UserLogin, db: Session = Depends(get_db)):
    """Authentifie un eleve et renvoie un JWT."""
    user = db.execute(
        select(User).where(User.email == payload.email.lower())
    ).scalar_one_or_none()

    if user is None or not auth_service.verify_password(
        payload.password, user.password_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = auth_service.create_access_token(
        subject=user.id,
        extra_claims={"email": user.email, "is_admin": user.is_admin},
    )
    return schemas.Token(
        access_token=token,
        token_type="bearer",
        user_id=user.id,
        user=_to_user_out(user),
    )


@router.get(
    "/me",
    response_model=schemas.UserOut,
    summary="Profil de l'utilisateur courant",
)
def me(user: User = Depends(get_current_user)):
    """Retourne le profil complet de l'utilisateur authentifie."""
    return _to_user_out(user)
