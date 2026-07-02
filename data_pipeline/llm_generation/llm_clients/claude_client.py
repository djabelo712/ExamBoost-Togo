"""
Wrapper Anthropic pour la generation de questions BEPC/BAC.

Utilise le SDK `anthropic` avec le modele `claude-sonnet-4-6`. Le client :
    - applique un system prompt "professeur togolais"
    - demande une reponse JSON strict
    - gere les retry avec backoff exponentiel (max 3 essais)
    - respecte un rate limit conservateur (50 req/min, delai inter-requetes)
    - estime et logge le cout de chaque appel

Usage:
    from llm_clients.claude_client import ClaudeClient
    client = ClaudeClient()
    questions = await client.generate_questions(prompt_text, count=20)
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

try:
    import anthropic  # type: ignore
    from anthropic import APIError, AsyncAnthropic, RateLimitError
    _ANTHROPIC_AVAILABLE = True
except ImportError:  # pragma: no cover - dependance optionnelle en test
    anthropic = None  # type: ignore
    APIError = Exception  # type: ignore
    RateLimitError = Exception  # type: ignore
    AsyncAnthropic = None  # type: ignore
    _ANTHROPIC_AVAILABLE = False

logger = logging.getLogger(__name__)


# ─── Constantes ───────────────────────────────────────────────────────────

# Modele cible (le plus recent Sonnet, equilibre qualite / cout).
DEFAULT_MODEL: str = os.getenv("CLAUDE_MODEL", "claude-sonnet-4-6")

# System prompt commun a tous les LLM (assume par le cahier des charges).
SYSTEM_PROMPT: str = (
    "Tu es un professeur togolais experimente qui cree des questions "
    "d'examen BEPC et BAC (series A, B, C, D, F) pour le compte du programme "
    "ExamBoost Togo. Tu respectes le programme officiel du Ministere de "
    "l'Enseignement Primaire, Secondaire et Technique (MEPST) du Togo. "
    "Tu reponds UNIQUEMENT avec un tableau JSON valide, sans texte autour, "
    "sans markdown, sans commentaire."
)

# Bornes de tokens pour une generation de ~30 questions.
MAX_INPUT_TOKENS: int = 8192
MAX_OUTPUT_TOKENS: int = 8192

# Rate limit conservateur : 50 req/min -> 1.2s entre requetes.
RATE_LIMIT_DELAY_S: float = 1.2

# Parametres retry.
MAX_RETRIES: int = 3
INITIAL_BACKOFF_S: float = 2.0
BACKOFF_MULTIPLIER: float = 2.0

# Tarification (USD / 1K tokens) - a maintenir a jour avec la doc Anthropic.
COST_PER_1K_INPUT: float = 0.003
COST_PER_1K_OUTPUT: float = 0.015


# ─── Client ───────────────────────────────────────────────────────────────


class ClaudeClient:
    """Client async Anthropic pour generer des questions JSON.

    Attributes:
        api_key: cle API (depuis ANTHROPIC_API_KEY).
        model: modele utilise (defaut: claude-sonnet-4-6).
        _client: instance AsyncAnthropic (lazy init).
        _last_call: timestamp du dernier appel (pour rate limit).
    """

    def __init__(
        self,
        api_key: Optional[str] = None,
        model: str = DEFAULT_MODEL,
    ) -> None:
        self.api_key: Optional[str] = api_key or os.getenv("ANTHROPIC_API_KEY")
        self.model: str = model
        self._client: Optional[Any] = None
        self._last_call: float = 0.0

    # ── Initialisation paresseuse du client ──────────────────────────────

    def _get_client(self) -> Any:
        """Initialise et retourne le client AsyncAnthropic.

        Raises:
            RuntimeError: si la dependance `anthropic` n'est pas installee.
            RuntimeError: si ANTHROPIC_API_KEY est manquant.
        """
        if not _ANTHROPIC_AVAILABLE:
            raise RuntimeError(
                "Le package 'anthropic' n'est pas installe. "
                "Installez-le via : pip install anthropic"
            )
        if not self.api_key:
            raise RuntimeError(
                "ANTHROPIC_API_KEY manquant. Ajoutez-le dans le fichier "
                "data_pipeline/.env ou exportez la variable d'environnement."
            )
        if self._client is None:
            self._client = AsyncAnthropic(api_key=self.api_key)
        return self._client

    # ── Rate limiting ────────────────────────────────────────────────────

    async def _respect_rate_limit(self) -> None:
        """Attend si necessaire pour respecter le rate limit Anthropic."""
        now = time.monotonic()
        elapsed = now - self._last_call
        if elapsed < RATE_LIMIT_DELAY_S:
            await asyncio.sleep(RATE_LIMIT_DELAY_S - elapsed)
        self._last_call = time.monotonic()

    # ── Retry avec backoff exponentiel ───────────────────────────────────

    async def _call_with_retry(
        self,
        prompt: str,
    ) -> Dict[str, Any]:
        """Appelle l'API Anthropic avec retry sur erreurs transitoires.

        Args:
            prompt: prompt utilisateur complet (contient deja le contexte).

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
                response = await client.messages.create(
                    model=self.model,
                    max_tokens=MAX_OUTPUT_TOKENS,
                    system=SYSTEM_PROMPT,
                    messages=[{"role": "user", "content": prompt}],
                    temperature=0.4,
                )
                # Extraction contenu + usage.
                content = ""
                if response.content:
                    content = "".join(
                        getattr(block, "text", "") for block in response.content
                    )
                usage = getattr(response, "usage", None)
                input_tokens = getattr(usage, "input_tokens", 0) or 0
                output_tokens = getattr(usage, "output_tokens", 0) or 0
                logger.info(
                    "Claude OK (model=%s, in=%d tok, out=%d tok, cout~$%.4f)",
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
            except RateLimitError as exc:
                # Rate limit : attendre plus longtemps.
                last_exc = exc
                wait = backoff * 2
                logger.warning(
                    "Claude rate limite (essai %d/%d), attente %.1fs",
                    attempt, MAX_RETRIES, wait,
                )
                await asyncio.sleep(wait)
            except APIError as exc:
                last_exc = exc
                logger.warning(
                    "Claude APIError essai %d/%d: %s",
                    attempt, MAX_RETRIES, exc,
                )
                await asyncio.sleep(backoff)
                backoff *= BACKOFF_MULTIPLIER
            except Exception as exc:  # noqa: BLE001
                last_exc = exc
                logger.warning(
                    "Claude erreur inattendue essai %d/%d: %s",
                    attempt, MAX_RETRIES, exc,
                )
                await asyncio.sleep(backoff)
                backoff *= BACKOFF_MULTIPLIER

        raise RuntimeError(
            f"Echec Claude apres {MAX_RETRIES} essais. Derniere erreur: {last_exc}"
        )

    # ── Estimation cout ──────────────────────────────────────────────────

    @staticmethod
    def _estimate_cost(input_tokens: int, output_tokens: int) -> float:
        """Estime le cout USD d'un appel a partir des tarifs en vigueur.

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

    # ── Parsing de la reponse ────────────────────────────────────────────

    @staticmethod
    def _parse_questions(content: str) -> List[Dict[str, Any]]:
        """Extrait la liste de questions depuis la reponse brute Claude.

        Strategies (par ordre):
            1. Direct JSON array.
            2. JSON object contenant une cle "questions".
            3. Regex pour trouver le premier tableau JSON.

        Args:
            content: texte retourne par Claude (souvent du JSON pur).

        Returns:
            Liste de dicts de questions (vide si parsing echoue).
        """
        if not content:
            return []
        text = content.strip()
        # 1. Tableau direct.
        if text.startswith("["):
            try:
                parsed = json.loads(text)
                if isinstance(parsed, list):
                    return [q for q in parsed if isinstance(q, dict)]
            except json.JSONDecodeError:
                pass
        # 2. Objet contenant une cle "questions" / "items" / "data".
        try:
            parsed = json.loads(text)
            if isinstance(parsed, dict):
                for key in ("questions", "items", "data"):
                    if isinstance(parsed.get(key), list):
                        return [q for q in parsed[key] if isinstance(q, dict)]
                # Objet unique = une seule question.
                if "enonce" in parsed:
                    return [parsed]
        except json.JSONDecodeError:
            pass
        # 3. Fallback regex : premier tableau JSON trouve.
        match = re.search(r"\[\s*\{.*\}\s*\]", text, flags=re.DOTALL)
        if match:
            try:
                parsed = json.loads(match.group(0))
                if isinstance(parsed, list):
                    return [q for q in parsed if isinstance(q, dict)]
            except json.JSONDecodeError:
                pass
        logger.warning(
            "Claude: echec parsing JSON (%d chars), retour vide", len(content)
        )
        return []

    # ── API publique ─────────────────────────────────────────────────────

    async def generate_questions(
        self,
        prompt: str,
        count: int = 30,
    ) -> List[Dict[str, Any]]:
        """Genere `count` questions via Claude.

        Args:
            prompt: prompt utilisateur complet (template formate).
            count: nombre de questions attendues (informatif, transmis au LLM).

        Returns:
            Liste de dicts de questions au format ExamBoost. Liste vide si
            la cle API est absente ou si toutes les tentatives echouent.
        """
        if not self.api_key:
            logger.warning(
                "Claude: ANTHROPIC_API_KEY absent, skip generation"
            )
            return []

        # On injecte le nombre demande dans le prompt si placeholder present.
        final_prompt = prompt.replace("{count}", str(count))
        try:
            result = await self._call_with_retry(final_prompt)
        except RuntimeError as exc:
            logger.error("Claude generation echouee: %s", exc)
            return []

        questions = self._parse_questions(result["content"])
        # Marque chaque question avec sa source (pour la cross-validation).
        for q in questions:
            q["_source"] = "claude"
        logger.info(
            "Claude a genere %d question(s) (attendu: %d)",
            len(questions), count,
        )
        return questions


__all__ = ["ClaudeClient", "SYSTEM_PROMPT", "DEFAULT_MODEL"]
