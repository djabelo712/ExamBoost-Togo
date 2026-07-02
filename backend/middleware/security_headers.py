"""middleware/security_headers.py — Headers de securite HTTP.

Ajoute les headers recommandes par OWASP et l'ANSSI sur toutes les
reponses sortantes :
    - Strict-Transport-Security   (HSTS, prod uniquement)
    - X-Content-Type-Options: nosniff
    - X-Frame-Options: DENY
    - Referrer-Policy: strict-origin-when-cross-origin
    - Content-Security-Policy (CSP restrictive pour une API JSON)
    - Permissions-Policy (desactive camera, mic, geolocation, etc.)
    - Cross-Origin-Opener-Policy: same-origin
    - Cross-Origin-Resource-Policy: same-origin
    - Cache-Control: no-store sur les reponses JSON authentifiees

Branchement dans main.py (a faire par l'agent de wiring) :

    from middleware.security_headers import SecurityHeadersMiddleware
    app.add_middleware(SecurityHeadersMiddleware)

L'activation de HSTS est conditionnee a la variable d'env ``ENV=prod``
(ou ``HSTS_ENABLED=true``) pour eviter de bloquer les devs locaux en
HTTP. CSP est volontairement maximale (``default-src 'none'``) car
l'API ne sert que du JSON — aucun script, style, image ou iframe n'est
legitime. Si un futur endpoint doit servir du HTML, l'exclure via le
parametre ``csp_exceptions`` du middleware.

References :
    - OWASP Secure Headers Project : https://owasp.org/www-project-secure-headers/
    - ANSSI : Guide d'hygiene informatique, recommandation 35
    - MDN : https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Conformite loi 2019-014 Togo : HSTS + CSP participe a la protection
des donnees en transit (article 9).
"""

from __future__ import annotations

import os
from typing import Iterable, Optional

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response


# ─── Helpers ────────────────────────────────────────────────────────
def _is_prod() -> bool:
    """Detected si on tourne en production.

    On regarde ENV / APP_ENV / HSTS_ENABLED. En prod, HSTS est actif.
    En dev / test, HSTS est desactive (sinon le navigateur bloquerait
    localhost en HTTP pendant max-age secondes).
    """
    env = os.getenv("ENV", os.getenv("APP_ENV", "dev")).lower()
    if env in ("prod", "production"):
        return True
    return os.getenv("HSTS_ENABLED", "false").lower() in ("1", "true", "yes")


def _is_html_response(resp: Response) -> bool:
    """Detecte une reponse HTML (pour adapter la CSP)."""
    content_type = resp.headers.get("content-type", "")
    return "text/html" in content_type.lower()


# ─── CSP ────────────────────────────────────────────────────────────
# Pour une API JSON pure : CSP maximale. Aucune source autorisee.
CSP_API_DEFAULT = (
    "default-src 'none'; "
    "frame-ancestors 'none'; "
    "base-uri 'none'; "
    "form-action 'none'"
)

# Si un endpoint sert du HTML (Swagger UI en dev par ex.), on assouplit
# uniquement en dev. En prod, /docs est desactive (voir F-21).
CSP_HTML_DEV = (
    "default-src 'self'; "
    "img-src 'self' data:; "
    "style-src 'self' 'unsafe-inline'; "
    "script-src 'self' 'unsafe-inline'; "
    "frame-ancestors 'none'; "
    "base-uri 'none'; "
    "form-action 'none'"
)


# ─── Middleware ─────────────────────────────────────────────────────
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Ajoute les headers de securite OWASP sur chaque reponse.

    Parameters
    ----------
    csp_exceptions : Iterable[str] | None
        Paths pour lesquels on n'applique PAS la CSP restrictive
        (ex: ``{"/docs", "/redoc"}``). Defaults to None.
    hsts_max_age : int
        Duree HSTS en secondes (defaut 2 ans, recommande ANSSI).
    """

    def __init__(
        self,
        app,
        csp_exceptions: Optional[Iterable[str]] = None,
        hsts_max_age: int = 63072000,  # 2 ans
    ) -> None:
        super().__init__(app)
        self._exceptions = set(csp_exceptions or ())
        self._hsts_max_age = hsts_max_age

    async def dispatch(self, request: Request, call_next) -> Response:
        response = await call_next(request)

        # Headers universels (dev + prod)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "geolocation=(), microphone=(), camera=(), "
            "payment=(), usb=(), magnetometer=(), gyroscope=()"
        )
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
        # Masquer le serveur (anti-fingerprinting)
        response.headers["Server"] = "ExamBoost-API"
        response.headers.pop("X-Powered-By", None)

        # HSTS (prod uniquement — en dev on est en HTTP, HSTS bloquerait)
        if _is_prod():
            response.headers["Strict-Transport-Security"] = (
                f"max-age={self._hsts_max_age}; includeSubDomains; preload"
            )

        # CSP : restrictive par defaut. Exception pour les paths declares.
        path = request.url.path
        if path in self._exceptions:
            # Pas de CSP sur les paths exclus (ex: Swagger UI)
            pass
        elif _is_html_response(response) and not _is_prod():
            response.headers["Content-Security-Policy"] = CSP_HTML_DEV
        else:
            response.headers["Content-Security-Policy"] = CSP_API_DEFAULT

        # Cache-Control : no-store sur les reponses JSON authentifiees
        # (anti-cache de donnees personnelles sur un terminal partage).
        # On n'applique pas sur /health (cacheable) ni sur les GET publics
        # de la banque de questions (cacheable).
        auth_header = request.headers.get("authorization", "")
        content_type = response.headers.get("content-type", "")
        if auth_header.startswith("Bearer ") and "json" in content_type.lower():
            response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, private"
            response.headers["Pragma"] = "no-cache"
            response.headers["Expires"] = "0"

        return response


# ─── Helper pour branchement manuel (alternative au add_middleware) ─
def add_security_headers(
    app,
    csp_exceptions: Optional[Iterable[str]] = None,
    hsts_max_age: int = 63072000,
) -> None:
    """Ajoute le middleware a l'app FastAPI.

    Usage :
        from middleware.security_headers import add_security_headers
        add_security_headers(app, csp_exceptions={"/docs", "/redoc"})
    """
    app.add_middleware(
        SecurityHeadersMiddleware,
        csp_exceptions=csp_exceptions,
        hsts_max_age=hsts_max_age,
    )


__all__ = ["SecurityHeadersMiddleware", "add_security_headers"]
