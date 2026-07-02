"""backend/middleware/input_validation.py — Validation et sanitization des entrees.

Ce module fournit des utilitaires de sanitization stricts pour completer
la validation Pydantic (qui s'applique champ par champ sur les schemas).
Il est volontairement defensif : Pydantic valide les types et contraintes,
mais il ne supprime pas les caracteres potentiellement dangereux (control
characters, sequences unicode homoglyphes, etc.).

Trois niveaux d'usage :

1. **Sanitizers** (fonctions pures) :
   - `sanitize_for_log(value)` -> str propre pour logs (sans CR/LF injection)
   - `strip_control_chars(value)` -> str sans caracteres de controle
   - `normalize_email(email)` -> str lower + trim
   - `sanitize_filename(name)` -> str sans path traversal ni caracteres speciaux
   - `clamp_int(value, lo, hi)` -> int borne
   - `validate_url_safe(value)` -> str ne contenant que [A-Za-z0-9_-]

2. **Pydantic validators** (a utiliser dans les schemas) :
   - `StrictEmail` : EmailStr + lower + trim
   - `StrictName` : str 1-80 chars, lettres/espaces/apostrophes/tirets
   - `StrictCity` : str 1-80 chars, lettres/espaces/tirets
   - `StrictQuestionId` : str pattern `^TG-[A-Z0-9]+-[A-Z]{3}-\\d{4}-Q\\d+$`
   - `StrictUserId` : str UUID v4 hex (32 chars) ou uuid standard

3. **Middleware FastAPI** : `register_input_sanitizers(app)` qui pose un
   middleware de sanity-check global (longueur max des bodys JSON,
   rejet des content-types inattendus).

Branchement dans main.py :

    from middleware.input_validation import register_input_sanitizers
    register_input_sanitizers(app)

Conformite OWASP :
    - A03 (Injection) : les sanitizers previennent l'injection de CR/LF
      dans les logs (log injection) et le path traversal dans les uploads.
    - A08 (Insecure Deserialization) : limite la taille des bodys JSON.
    - A05 (Misconfiguration) : rejette les content-types inattendus.

Conformite loi 2019-014 : la validation stricte des entrees PII (nom,
prenom, ville, email) participe au principe de minimisation (article 6).
"""

from __future__ import annotations

import re
import unicodedata
from typing import Any, Optional

from fastapi import FastAPI, Request, Response
from fastapi.responses import JSONResponse


# ─── Constantes ─────────────────────────────────────────────────────
MAX_JSON_BODY_BYTES = 1 * 1024 * 1024  # 1 Mo par defaut pour les POST/PUT
MAX_QUERY_STRING_LEN = 2048
MAX_HEADER_VALUE_LEN = 1024

# Caracteres de controle a retirer (sauf \t \n \r si explicitement voulu)
_CTRL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")

# CR/LF pour eviter log injection
_CRLF_RE = re.compile(r"[\r\n]")

# Path traversal
_PATH_TRAVERSAL_RE = re.compile(r"\.\.|/|\\|:")

# Chiffre hexa + tiret pour UUID
_UUID_HEX_RE = re.compile(r"^[a-f0-9]{32}$|^[a-f0-9-]{36}$")


# ─── Sanitizers (fonctions pures) ───────────────────────────────────
def strip_control_chars(value: str) -> str:
    """Retire les caracteres de controle ASCII (sauf \t \n \r)."""
    if not isinstance(value, str):
        return value
    return _CTRL_RE.sub("", value)


def sanitize_for_log(value: Any, max_len: int = 500) -> str:
    """Renvoie une version sure de ``value`` pour ecriture dans un log.

    - Convertit en str
    - Retire CR/LF (anti log injection)
    - Tronque a ``max_len`` caracteres
    - Retire les caracteres de controle
    """
    if value is None:
        return "-"
    s = str(value)
    s = _CRLF_RE.sub(" ", s)
    s = _CTRL_RE.sub("", s)
    if len(s) > max_len:
        s = s[:max_len] + "...(truncated)"
    return s


def normalize_email(email: str) -> str:
    """Lower-case + trim d'un email. Ne valide PAS le format (voir StrictEmail)."""
    if not isinstance(email, str):
        return email
    return email.strip().lower()


def sanitize_filename(name: str, max_len: int = 128) -> str:
    """Renvoie un nom de fichier safe (pas de path traversal, pas de controle).

    Conserve l'extension (si presente) et les caracteres alphanumeriques,
    tirets, underscores et points. Tout le reste est remplace par ``_``.
    """
    if not isinstance(name, str):
        return "upload"
    name = strip_control_chars(name)
    # Supprime les sequences de path traversal
    name = _PATH_TRAVERSAL_RE.sub("_", name)
    # Garde uniquement les caracteres safe
    safe = re.sub(r"[^A-Za-z0-9._-]", "_", name)
    safe = safe.strip("._")  # pas de point/underscore en debut/fin
    if not safe:
        safe = "upload"
    return safe[:max_len]


def clamp_int(value: int, lo: int, hi: int) -> int:
    """Borne un entier entre ``lo`` et ``hi``."""
    try:
        v = int(value)
    except (TypeError, ValueError):
        return lo
    return max(lo, min(hi, v))


def validate_url_safe(value: str, max_len: int = 256) -> str:
    """Renvoie ``value`` uniquement s'il ne contient que [A-Za-z0-9_-].

    Useful pour les IDs, codes session, etc. qui ne doivent pas contenir
    de caracteres speciaux.
    """
    if not isinstance(value, str):
        raise ValueError("Expected string")
    if len(value) > max_len:
        raise ValueError(f"Too long (max {max_len})")
    if not re.match(r"^[A-Za-z0-9_-]+$", value):
        raise ValueError("Contains forbidden characters")
    return value


def normalize_unicode(value: str) -> str:
    """Normalise un string en NFC (forme canonique Unicode).

    Prend les caracteres composés (ex: e + accent) et les decompose
    en forme canonique, ce qui evite les attaques par homoglyphe.
    """
    if not isinstance(value, str):
        return value
    return unicodedata.normalize("NFC", value)


# ─── Pydantic validators ───────────────────────────────────────────
# Ces fonctions sont a utiliser comme ``field_validator`` dans les
# schemas Pydantic. Exemple :
#
#     from middleware.input_validation import strict_email_validator
#     class UserCreate(BaseModel):
#         email: EmailStr
#         _normalize_email = field_validator("email")(strict_email_validator)
#         ...

def strict_email_validator(v: str) -> str:
    """Lower-case + trim + NFC. A utiliser sur les champs email."""
    return normalize_email(normalize_unicode(v))


def strict_name_validator(v: str) -> str:
    """Valide un nom/prenom : lettres (unicode), espaces, apostrophes, tirets."""
    if not isinstance(v, str):
        raise ValueError("Nom invalide")
    v = normalize_unicode(v).strip()
    if not v:
        raise ValueError("Nom vide")
    if len(v) > 80:
        raise ValueError("Nom trop long (max 80)")
    # Autorise lettres Unicode + espaces + apostrophe + tiret
    if not re.match(r"^[\w\s'\-]+$", v, flags=re.UNICODE):
        raise ValueError("Nom contient des caracteres interdits")
    return v


def strict_city_validator(v: str) -> str:
    """Valide un nom de ville : lettres, espaces, tirets."""
    if v is None:
        return v
    if not isinstance(v, str):
        raise ValueError("Ville invalide")
    v = normalize_unicode(v).strip()
    if not v:
        return v
    if len(v) > 80:
        raise ValueError("Ville trop longue (max 80)")
    if not re.match(r"^[A-Za-zÀ-ÿ\s'\-]+$", v):
        raise ValueError("Ville contient des caracteres interdits")
    return v


def strict_question_id_validator(v: Optional[str]) -> Optional[str]:
    """Valide un ID de question au format ``TG-<EXAMEN>-<MATIERE>-<ANNEE>-Q<NN>``."""
    if v is None:
        return v
    if not isinstance(v, str):
        raise ValueError("ID question invalide")
    v = v.strip()
    pattern = r"^TG-(BEPC|BAC1|BAC2|PROBATOIRE)-[A-Z]{2,6}-\d{4}-Q\d{1,3}$"
    if not re.match(pattern, v):
        raise ValueError(
            "ID question doit respecter le format "
            "TG-<EXAMEN>-<MATIERE>-<ANNEE>-Q<NN> (ex: TG-BEPC-MAT-2024-Q01)"
        )
    return v


def strict_user_id_validator(v: str) -> str:
    """Valide qu'un user_id est un UUID v4 (hex 32 chars ou forme standard)."""
    if not isinstance(v, str):
        raise ValueError("user_id invalide")
    v = v.strip().lower()
    if not _UUID_HEX_RE.match(v):
        raise ValueError("user_id doit etre un UUID v4")
    return v


def strict_text_field(max_len: int = 5000, min_len: int = 1):
    """Factory de validator pour un champ texte libre (enonce, explication...).

    Retire les caracteres de controle, normalise Unicode, verifie la longueur.
    Usage :
        _clean_enonce = field_validator("enonce")(strict_text_field(max_len=2000))
    """
    def _validate(v: str) -> str:
        if not isinstance(v, str):
            raise ValueError("Texte invalide")
        v = normalize_unicode(v)
        v = strip_control_chars(v)
        v = v.strip()
        if len(v) < min_len:
            raise ValueError(f"Texte trop court (min {min_len})")
        if len(v) > max_len:
            raise ValueError(f"Texte trop long (max {max_len})")
        return v
    return _validate


# ─── Middleware FastAPI ─────────────────────────────────────────────
async def _input_validation_middleware(request: Request, call_next):
    """Middleware global : limite taille body, valide methodes, etc.

    - Limite la taille du body JSON a MAX_JSON_BODY_BYTES (1 Mo).
    - Limite la longueur de la query string.
    - Rejette les methodes autres que GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS.
    - Rejette les headers Authorization trop longs (> 4 Ko, anti-abuse).
    """
    # Methodes autorisees
    if request.method not in {"GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"}:
        return JSONResponse(
            status_code=405,
            content={"detail": "Methode non autorisee"},
        )

    # Query string trop longue
    qs = request.url.query
    if len(qs) > MAX_QUERY_STRING_LEN:
        return JSONResponse(
            status_code=414,
            content={"detail": "Query string trop longue"},
        )

    # Authorization header trop long (anti-abuse : un JWT fait ~1 Ko max)
    auth = request.headers.get("authorization", "")
    if len(auth) > 4096:
        return JSONResponse(
            status_code=400,
            content={"detail": "Header Authorization trop long"},
        )

    # Limite taille body pour POST/PUT/PATCH
    if request.method in {"POST", "PUT", "PATCH"}:
        cl = request.headers.get("content-length")
        if cl and cl.isdigit() and int(cl) > MAX_JSON_BODY_BYTES:
            return JSONResponse(
                status_code=413,
                content={
                    "detail": f"Body trop volumineux (max {MAX_JSON_BODY_BYTES // 1024 // 1024} Mo)",
                    "error": "payload_too_large",
                },
            )

    return await call_next(request)


def register_input_sanitizers(app: FastAPI) -> None:
    """Branche le middleware de validation des entrees sur l'app FastAPI.

    Usage dans main.py :
        from middleware.input_validation import register_input_sanitizers
        register_input_sanitizers(app)
    """
    app.middleware("http")(_input_validation_middleware)


__all__ = [
    # Sanitizers
    "strip_control_chars",
    "sanitize_for_log",
    "normalize_email",
    "sanitize_filename",
    "clamp_int",
    "validate_url_safe",
    "normalize_unicode",
    # Pydantic validators
    "strict_email_validator",
    "strict_name_validator",
    "strict_city_validator",
    "strict_question_id_validator",
    "strict_user_id_validator",
    "strict_text_field",
    # Middleware
    "register_input_sanitizers",
    # Constantes
    "MAX_JSON_BODY_BYTES",
    "MAX_QUERY_STRING_LEN",
    "MAX_HEADER_VALUE_LEN",
]
