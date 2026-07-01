"""services/tutor_service.py — Logique LLM du tuteur ExamBoost.

Utilise l'API Anthropic (claude-sonnet-4-6 par defaut) avec un system prompt
pedagogique contextualise au Togo (FCFA, villes togolaises, vie quotidienne,
BEPC/BAC). Si la cle API n'est pas configuree, un fallback mock renvoie une
reponse templatee pour la demo.

Dependance optionnelle : ``anthropic`` (a ajouter a requirements.txt) :
    anthropic>=0.40.0

En son absence, le mode fallback est active automatiquement (aucun crash).

Configuration env :
    ANTHROPIC_API_KEY  — cle secrete (obligatoire pour activer Claude)
    ANTHROPIC_MODEL    — modele (defaut : claude-sonnet-4-6)
"""

from __future__ import annotations

import os
from typing import Any, Dict, List, Optional

# ─── SDK Anthropic (optionnel) ────────────────────────────────────────
try:
    from anthropic import AsyncAnthropic  # type: ignore[import-untyped]

    _ANTHROPIC_AVAILABLE = True
except ImportError:  # pragma: no cover - fallback si SDK absent
    _ANTHROPIC_AVAILABLE = False


# ─── Configuration ────────────────────────────────────────────────────
ANTHROPIC_API_KEY: Optional[str] = os.environ.get("ANTHROPIC_API_KEY")
ANTHROPIC_MODEL: str = os.environ.get("ANTHROPIC_MODEL", "claude-sonnet-4-6")
MAX_TOKENS: int = 2000


# ─── System prompt (pedagogique, contextualise Togo) ──────────────────
_BASE_SYSTEM_PROMPT = (
    "Tu es ExamBoost Tutor, un assistant pedagogique specialise dans l'aide "
    "aux eleves togolais preparant le BEPC et le BAC. Tu expliques clairement, "
    "avec des exemples contextualises au Togo (FCFA, villes togolaises, vie "
    "quotidienne). Tu es bienveillant, patient, et tu verifies la "
    "comprehension en posant des questions. Tu adaptes ton niveau de langue "
    "au niveau scolaire declare (3e, Terminale C, etc.). Tu ne donnes pas la "
    "reponse directement pour les exercices, tu guides l'eleve avec la "
    "methode socratique.\n\n"
    "Reponses courtes et structurees (paragraphes courts, listes a puces si "
    "utile, blocs de code pour les formules mathematiques). Pas d'emojis. "
    "Langue : francais. Si l'eleve fait une erreur, corrige avec douceur. "
    "Si la question n'est pas pedagogique, rappelle que tu aides pour les "
    "examens togolais (BEPC, BAC) et propose un sujet connexe."
)


def _build_system_prompt(context: Optional[Any]) -> str:
    """Build the full system prompt, with optional pedagogical context."""
    prompt = _BASE_SYSTEM_PROMPT
    if context is None:
        return prompt

    # Context peut etre un BaseModel (TutorContext) ou un dict
    def _get(name: str) -> Optional[str]:
        v = getattr(context, name, None)
        if v is None and isinstance(context, dict):
            v = context.get(name)
        return v

    matiere = _get("matiere")
    chapitre = _get("chapitre")
    niveau = _get("niveau_scolaire")
    serie = _get("serie")

    extras: List[str] = []
    if matiere:
        chap = f", chapitre {chapitre}" if chapitre else ""
        extras.append(f"L'eleve travaille actuellement sur {matiere}{chap}.")
    if niveau:
        serie_str = f" (serie {serie})" if serie else ""
        extras.append(f"Niveau scolaire : {niveau}{serie_str}.")
    if extras:
        prompt += "\n\nContexte :\n- " + "\n- ".join(extras)
    return prompt


def is_anthropic_configured() -> bool:
    """Indique si le SDK Anthropic ET la cle API sont disponibles."""
    return _ANTHROPIC_AVAILABLE and bool(ANTHROPIC_API_KEY)


# ─── Fonction principale ─────────────────────────────────────────────
async def generate_answer(
    user: Any,
    question: str,
    context: Optional[Any] = None,
    conversation_history: Optional[List[Dict[str, str]]] = None,
) -> Dict[str, Any]:
    """Generate the tutor's answer.

    Args:
        user: User ORM (for niveau_scolaire / serie).
        question: the student's question.
        context: optional TutorContext (matiere / chapitre).
        conversation_history: list of {role, content} turns.

    Returns:
        Dict with keys: answer, suggested_followup, tokens_used, model, fallback.
    """
    enriched_context = _enrich_context_with_user(context, user)

    if is_anthropic_configured():
        try:
            return await _call_anthropic(
                question=question,
                context=enriched_context,
                conversation_history=conversation_history or [],
            )
        except Exception:
            # Erreur API (rate limit Anthropic, reseau, etc.) -> fallback
            # plutot que de planter l'eleve.
            return _build_fallback(question=question, context=enriched_context)

    return _build_fallback(question=question, context=enriched_context)


def _enrich_context_with_user(context: Optional[Any], user: Any) -> Any:
    """Add niveau_scolaire/serie from user to context if absent."""
    niveau = getattr(user, "niveau_scolaire", None)
    serie = getattr(user, "serie", None)

    if context is None:
        return {
            "matiere": None,
            "chapitre": None,
            "competence_id": None,
            "niveau_scolaire": niveau,
            "serie": serie,
        }

    # Si c'est un BaseModel, on ne le modifie pas (utilise tel quel)
    # mais on ajoute niveau_scolaire/serie dans le dict cas fallback.
    if hasattr(context, "model_dump"):
        d = context.model_dump()
        if not d.get("niveau_scolaire"):
            d["niveau_scolaire"] = niveau
        if not d.get("serie"):
            d["serie"] = serie
        return d
    return context


async def _call_anthropic(
    question: str,
    context: Any,
    conversation_history: List[Dict[str, str]],
) -> Dict[str, Any]:
    """Call the Anthropic Claude API and return a dict response."""
    client = AsyncAnthropic(api_key=ANTHROPIC_API_KEY)

    # Construit les messages : historique (10 derniers tours) + question
    messages: List[Dict[str, str]] = []
    for turn in conversation_history[-10:]:
        role = turn.get("role", "user")
        content = turn.get("content", "")
        if not content:
            continue
        if role not in ("user", "assistant"):
            continue
        messages.append({"role": role, "content": content})
    messages.append({"role": "user", "content": question})

    system_prompt = _build_system_prompt(context)

    response = await client.messages.create(
        model=ANTHROPIC_MODEL,
        max_tokens=MAX_TOKENS,
        system=system_prompt,
        messages=messages,
    )

    # Extraction du texte depuis les content blocks
    answer_parts: List[str] = []
    for block in response.content:
        if getattr(block, "type", None) == "text":
            answer_parts.append(block.text)
    answer = "\n".join(answer_parts).strip()

    tokens_used = int(getattr(response.usage, "input_tokens", 0)) + int(
        getattr(response.usage, "output_tokens", 0)
    )

    followups = _generate_followups(question, context)

    return {
        "answer": answer,
        "suggested_followup": followups,
        "tokens_used": tokens_used,
        "model": ANTHROPIC_MODEL,
        "fallback": False,
    }


def _build_fallback(question: str, context: Any) -> Dict[str, Any]:
    """Build a mock answer when Anthropic API is not configured."""
    matiere = None
    if context is not None:
        matiere = (
            getattr(context, "matiere", None)
            if not isinstance(context, dict)
            else context.get("matiere")
        )

    matiere_str = f" en {matiere}" if matiere else ""
    answer = (
        f"Voici une explication sur « {question} »{matiere_str}.\n\n"
        "Le tuteur IA est actuellement en mode demonstration (la cle API "
        "Anthropic n'est pas configuree sur le serveur). Pour activer les "
        "vraies reponses, ajoute ANTHROPIC_API_KEY dans le fichier .env du "
        "backend.\n\n"
        "En attendant, voici une piste de reflexion :\n"
        "- Identifie les mots-cles de la question.\n"
        "- Rappelle la definition du concept.\n"
        "- Applique la methode vue en classe.\n"
        "- Verifie le resultat avec un exemple concret.\n\n"
        "Si tu es administrateur, vois backend/services/tutor_service.py."
    )
    followups = _generate_followups(question, context)

    return {
        "answer": answer,
        "suggested_followup": followups,
        "tokens_used": 0,
        "model": "fallback-mock",
        "fallback": True,
    }


def _generate_followups(question: str, context: Any) -> List[str]:
    """Heuristique simple pour suggerer 3 questions de suivi."""
    q_lower = question.lower()

    if any(
        k in q_lower
        for k in ("pythagore", "thales", "thalès", "triangle", "geometrie", "géométrie")
    ):
        return [
            "Donne-moi un exercice d'application.",
            "Comment demontrer cette propriete ?",
            "Quels sont les pieges frequents ?",
        ]
    if any(
        k in q_lower
        for k in ("factoriser", "equation", "équation", "developper", "developper", "algebre", "algèbre")
    ):
        return [
            "Montre-moi un autre exemple.",
            "Quelle est la methode generale ?",
            "Comment verifier le resultat ?",
        ]
    if any(
        k in q_lower
        for k in ("conjuguer", "subjonctif", "verbe", "francais", "français", "metaphore", "comparaison")
    ):
        return [
            "Donne-moi la liste des exceptions.",
            "Comment reconnaitre quand l'utiliser ?",
            "Un exemple avec un autre mot ?",
        ]
    if any(
        k in q_lower
        for k in ("ohm", "physique", "electricite", "électricité", "chimie", "reaction")
    ):
        return [
            "Donne-moi un exemple concret.",
            "Comment je calcule le resultat ?",
            "Quelles sont les unites importantes ?",
        ]
    return [
        "Peux-tu me donner un exemple concret ?",
        "Comment je verifie que j'ai compris ?",
        "Quels sont les pieges a eviter ?",
    ]
