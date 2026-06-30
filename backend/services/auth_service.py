"""services/auth_service.py — JWT + hashing de mots de passe.

Utilise python-jose pour les JWT. Pour le hashing, on essaie d'abord
``bcrypt`` directement (plus robuste face aux evolutions de la lib),
avec un fallback sur ``passlib[bcrypt]``.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer


# ─── Hashing (bcrypt direct, plus robuste que passlib face a bcrypt 5.x) ──
try:
    import bcrypt as _bcrypt

    def hash_password(plain: str) -> str:
        """Hashe un mot de passe en clair (bcrypt)."""
        pw = plain.encode("utf-8")
        # Tronque a 72 bytes (limite bcrypt) — OpenBSD spec
        pw = pw[:72]
        return _bcrypt.hashpw(pw, _bcrypt.gensalt()).decode("utf-8")

    def verify_password(plain: str, hashed: str) -> bool:
        """Verifie qu'un mot de passe correspond au hash stocke."""
        try:
            pw = plain.encode("utf-8")[:72]
            return _bcrypt.checkpw(pw, hashed.encode("utf-8"))
        except Exception:
            return False

except ImportError:  # pragma: no cover - fallback passlib
    from passlib.context import CryptContext

    _pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

    def hash_password(plain: str) -> str:
        return _pwd_context.hash(plain)

    def verify_password(plain: str, hashed: str) -> bool:
        try:
            return _pwd_context.verify(plain, hashed)
        except Exception:
            return False


# ─── Configuration ───────────────────────────────────────────────────
from config import settings  # noqa: E402


# ─── JWT ─────────────────────────────────────────────────────────────
def create_access_token(
    subject: str,
    extra_claims: Optional[dict] = None,
    expires_minutes: Optional[int] = None,
) -> str:
    """Genere un JWT signe pour ``subject`` (en general le user_id)."""
    expire_minutes = expires_minutes or settings.ACCESS_TOKEN_EXPIRE_MINUTES
    expire = datetime.now(timezone.utc) + timedelta(minutes=expire_minutes)

    payload: dict = {
        "sub": subject,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "access",
    }
    if extra_claims:
        payload.update(extra_claims)

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def decode_access_token(token: str) -> Optional[dict]:
    """Decode et verifie un JWT. Retourne le payload ou None si invalide."""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        return payload
    except JWTError:
        return None


# ─── OAuth2 (pour le bouton "Authorize" de Swagger) ──────────────────
# tokenUrl relatif — FastAPI le gere bien en local comme en prod
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login", auto_error=False)
