"""
Wrapper Mistral pour la generation de questions BEPC/BAC.

Utilise le SDK `mistralai` avec le modele `mistral-large-latest`. Le client :
    - applique le meme system prompt "professeur togolais" que les autres LLM
    - demande une reponse JSON strict
    - gere les retry avec backoff exponentiel (max 3 essais)
    - respecte un rate limit conservateur (50 req/min)
    - estime et logge le cout de chaque appel

Usage:
    from llm_clients.mistral_client import MistralClient
    client = MistralClient()
    questions = await client.generate_questions(prompt_text, count=20)
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import time
from typing import Any, Dict, List, Optional

try:
    from mistralai import Mistral  # type: ignore
    from mistralai.models import SDKError  # type: ignore
    _MISTRAL_AVAILABLE = True
except ImportError:  # pragma: no cover
    Mistral = None  # type: ignore
    SDKError = Exception  # type: ignore
    _MISTRAL_AVAILABLE = False

logger = logging.getLogger(__name__)


# ─── Constantes ───────────────────────────────────────────────────────────

DEFAULT_MODEL: str = os.getenv("MISTRAL_MODEL", "mistral-large-latest")

SYSTEM_PROMPT: str = (
    "Tu es un professeur togolais experimente qui cree des questions "
    "d'examen BEPC et BAC (series A, B, C, D, F) pour le compte du programme "
    "ExamBoost Togo. Tu respectes le programme officiel du Ministere de "
    "l'Enseignement Primaire, Secondaire et Technique (MEPST) du Togo. "
    "Tu reponds UNIQUEMENT avec un objet JSON valide contenant une cle "
    "'questions' qui est un tableau, sans texte autour, sans markdown, "
    "sans commentaire."
)

MAX_OUTPUT_TOKENS: int = 8192
RATE_LIMIT_DELAY_S: float = 1.2
MAX_RETRIES: int = 3
INITIAL_BACKOFF_S: float = 2.0
BACKOFF_MULTIPLIER: float = 2.0

# Tarification Mistral Large (USD / 1K tokens) - a maintenir a jour.
COST_PER_1K_INPUT: float = 0.002
COST_PER_1K_OUTPUT: float = 0.006


# ─── Client ───────────────────────────────────────────────────────────────


class MistralClient:
    """Client async Mistral pour generer des questions JSON.

    Attributes:
        api_key: cle API (depuis MISTRAL_API_KEY).
        model: modele utilise (defaut: mistral-large-latest).
        _client: instance Mistral (lazy init).
        _last_call: timestamp du dernier appel (pour rate limit).
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = DEFAULT_MODEL,
    ) -> None:
        self.api_key: Optional[str] = api_key or os.getenv("MISTRAL_API_KEY")
        self.model: str = model
        self._client: Optional[Any] = None
        self._last_call: float = 0.0

    # ── Initialisation paresseuse ────────────────────────────────────────

    def _get_client(self) -> Any:
        """Initialise et retourne le client Mistral.

        Raises:
            RuntimeError: si `mistralai` n'est pas installe ou cle absente.
        """
        if not _MISTRAL_AVAILABLE:
            raise RuntimeError(
                "Le package 'mistralai' n'est pas installe. "
                "Installez-le via : pip install mistralai"
            )
        if not self.api_key:
            raise RuntimeError(
                "MISTRAL_API_KEY manquant. Ajoutez-le dans le fichier "
                "data_pipeline/.env ou exportez la variable d'environnement."
            )
        if self._client is None:
            self._client = Mistral(api_key=self.api_key)
        return self._client

    # ── Rate limiting ────────────────────────────────────────────────────

    async def _respect_rate_limit(self) -> None:
        """Attend si necessaire pour respecter le rate limit Mistral."""
        now = time.monotonic()
        elapsed = now - self._last_call
        if elapsed < RATE_LIMIT_DELAY_S:
            await asyncio.sleep(RATE_LIMIT_DELAY_S - elapsed)
        self._last_call = time.monotonic()

    # ── Retry avec backoff exponentiel ───────────────────────────────────

    async def _call_with_retry(self, prompt: str) -> Dict[str, Any]:
        """Appelle l'API Mistral avec retry sur erreurs transitoires.

        Args:
            prompt: prompt utilisateur complet.

        Returns:
            Dict avec cles: content (str), input_tokens (int), output_tokens (int).

        Raises:
            RuntimeError: si toutes les tentatives echouent.
        """
        client = self._get_client()
        last_exc: Optional[Exception] = None
        backoff = INITIAL_BACKOFF_S

        for attempt in range(1, MAX_RETRIES + 1):
            await self._respect_rate_limit()
            try:
                # Le SDK Mistral expose chat.complete_async (async) ou
                # chat.complete (sync). On utilise l'API async.
                response = await client.chat.complete_async(
                    model=self.model,
                    messages=[
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": prompt},
                    ],
                    temperature=0.4,
                    max_tokens=MAX_OUTPUT_TOKENS,
                    response_format={"type": "json_object"},
                )
                content = ""
                if response and response.choices:
                    content = response.choices[0].message.content or ""
                usage = getattr(response, "usage", None)
                input_tokens = getattr(usage, "prompt_tokens", 0) or 0
                output_tokens = getattr(usage, "completion_tokens", 0) or 0
                logger.info(
                    "Mistral OK (model=%s, in=%d tok, out=%d tok, cout~$%.4f)",
                    self.model,
                    input_tokens,
                    output_tokens,
                    self._estimate_cost(input_tokens, output_tokens),
                )
                return {
                    "content": content,
                    "input_tokens": input_tokens,
                    "output_tokens": output_tokens,
                }
            except SDKError as exc:
                # Peut inclure 429 rate limit.
                last_exc = exc
                status = getattr(exc, "status_code", None)
                if status == 429:
                    wait = backoff * 2
                    logger.warning(
                        "Mistral rate limite (essai %d/%d), attente %.1fs",
                        attempt, MAX_RETRIES, wait,
                    )
                else:
                    wait = backoff
                    logger.warning(
                        "Mistral SDKError essai %d/%d (status=%s): %s",
                        attempt, MAX_RETRIES, status, exc,
                    )
                await asyncio.sleep(wait)
                backoff *= BACKOFF_MULTIPLIER
            except Exception as exc:  # noqa: BLE001
                last_exc = exc
                logger.warning(
                    "Mistral erreur inattendue essai %d/%d: %s",
                    attempt, MAX_RETRIES, exc,
                )
                await asyncio.sleep(backoff)
                backoff *= BACKOFF_MULTIPLIER

        raise RuntimeError(
            f"Echec Mistral apres {MAX_RETRIES} essais. Derniere erreur: {last_exc}"
        )

    # ── Estimation cout ──────────────────────────────────────────────────

    @staticmethod
    def _estimate_cost(input_tokens: int, output_tokens: int) -> float:
        """Estime le cout USD d'un appel Mistral.

        Args:
            input_tokens: tokens consommes en entree.
            output_tokens: tokens produits en sortie.

        Returns:
            Cout estime en USD (float).
        """
        return (
            input_tokens / 1000.0 * COST_PER_1K_INPUT
            + output_tokens / 1000.0 * COST_PER_1K_OUTPUT
        )

    # ── Parsing ──────────────────────────────────────────────────────────

    @staticmethod
    def _parse_questions(content: str) -> List[Dict[str, Any]]:
        """Extrait la liste de questions depuis la reponse brute Mistral.

        Args:
            content: texte retourne par Mistral.

        Returns:
            Liste de dicts de questions (vide si parsing echoue).
        """
        if not content:
            return []
        text = content.strip()
        if text.startswith("["):
            try:
                parsed = json.loads(text)
                if isinstance(parsed, list):
                    return [q for q in parsed if isinstance(q, dict)]
            except json.JSONDecodeError:
                pass
        try:
            parsed = json.loads(text)
            if isinstance(parsed, dict):
                for key in ("questions", "items", "data"):
                    if isinstance(parsed.get(key), list):
                        return [q for q in parsed[key] if isinstance(q, dict)]
                if "enonce" in parsed:
                    return [parsed]
        except json.JSONDecodeError:
            pass
        match = re.search(r"\[\s*\{.*\}\s*\]", text, flags=re.DOTALL)
        if match:
            try:
                parsed = json.loads(match.group(0))
                if isinstance(parsed, list):
                    return [q for q in parsed if isinstance(q, dict)]
            except json.JSONDecodeError:
                pass
        logger.warning(
            "Mistral: echec parsing JSON (%d chars), retour vide", len(content)
        )
        return []

    # ── API publique ─────────────────────────────────────────────────────

    async def generate_questions(
        self,
        prompt: str,
        count: int = 30,
    ) -> List[Dict[str, Any]]:
        """Genere `count` questions via Mistral Large.

        Args:
            prompt: prompt utilisateur complet (template formate).
            count: nombre de questions attendues (transmis au LLM).

        Returns:
            Liste de dicts de questions au format ExamBoost. Liste vide si
            la cle API est absente ou si toutes les tentatives echouent.
        """
        if not self.api_key:
            logger.warning(
                "Mistral: MISTRAL_API_KEY absent, skip generation"
            )
            return []

        final_prompt = prompt.replace("{count}", str(count))
        try:
            result = await self._call_with_retry(final_prompt)
        except RuntimeError as exc:
            logger.error("Mistral generation echouee: %s", exc)
            return []

        questions = self._parse_questions(result["content"])
        for q in questions:
            q["_source"] = "mistral"
        logger.info(
            "Mistral a genere %d question(s) (attendu: %d)",
            len(questions), count,
        )
        return questions


__all__ = ["MistralClient", "SYSTEM_PROMPT", "DEFAULT_MODEL"]
