"""
Script principal orchestrateur de la generation LLM de questions BEPC/BAC.

Génère 100+ nouvelles questions via 3 LLM (Claude, GPT-4o, Mistral) avec
validation croisee : seules les questions validees par au moins 2 LLM sur 3
sont conservees.

Pipeline:
    1. Charge le prompt template adapte a (matiere, examen, serie).
    2. Genere les questions en parallele via les 3 LLM (asyncio.gather).
    3. Sauvegarde les raw outputs (pour debug / revalidation).
    4. Cross-validation : fusionne les 3 sources et garde celles validees
       par >= 2 LLM (SimHash distance Hamming < 9).
    5. Validation schema JSON (champs, types, coherence).
    6. Validation pedagogique (longueurs, pieges, niveau).
    7. Deduplication vs questions existantes (SimHash distance < 5).
    8. (Optionnel) Generation de corriges detailles supplementaires.
    9. Sauvegarde finale dans data/llm_generated/final_questions_to_add.json.

Usage:
    # Generation pour une matiere specifique
    python generate_questions_3llm.py \\
        --matiere Mathematiques --examen BEPC --count 30

    # Generation sur toutes les combinaisons (100+ questions)
    python generate_questions_3llm.py --all

    # Skip generation, juste re-valider les raw outputs existants
    python generate_questions_3llm.py --validate-only
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

# Imports locaux (relatifs au dossier llm_generation/).
from llm_clients.claude_client import ClaudeClient
from llm_clients.openai_client import OpenAIClient
from llm_clients.mistral_client import MistralClient
from validators.schema_validator import validate_schema, validate_schema_with_errors
from validators.pedagogical_validator import (
    validate_pedagogy,
    validate_pedagogy_with_errors,
)
from validators.duplicate_checker import (
    DuplicateChecker,
    load_existing_questions,
    check_duplicates,
)
from merge_questions import (
    merge_and_cross_validate,
    clean_metadata,
    stats as merge_stats,
)

logger = logging.getLogger("generate_questions_3llm")


# ─── Constantes ───────────────────────────────────────────────────────────

# Racine du module llm_generation/.
_MODULE_ROOT: Path = Path(__file__).resolve().parent

# Dossier des prompts.
PROMPTS_DIR: Path = _MODULE_ROOT / "prompts"

# Dossier des sorties (raw + final).
OUTPUT_ROOT: Path = _MODULE_ROOT.parent / "data" / "llm_generated"
CLAUDE_RAW_DIR: Path = OUTPUT_ROOT / "claude_raw"
OPENAI_RAW_DIR: Path = OUTPUT_ROOT / "openai_raw"
MISTRAL_RAW_DIR: Path = OUTPUT_ROOT / "mistral_raw"
MERGED_DIR: Path = OUTPUT_ROOT / "merged_validated"
FINAL_PATH: Path = OUTPUT_ROOT / "final_questions_to_add.json"

# Mapping (matiere, examen, serie) -> fichier prompt.
# Tuple keys: (examen, matiere, serie_or_none) -> prompt filename.
PROMPT_MAPPING: Dict[Tuple[str, str, Optional[str]], str] = {
    ("BEPC", "Mathematiques", None): "bepc_maths_prompt.txt",
    ("BEPC", "Francais", None): "bepc_francais_prompt.txt",
    ("BEPC", "Sciences de la Vie et de la Terre", None): "bepc_sciences_prompt.txt",
    ("BEPC", "Sciences Physiques", None): "bepc_sciences_prompt.txt",
    ("BAC", "Mathematiques", "C"): "bac_c_maths_prompt.txt",
    ("BAC", "Sciences Physiques", "C"): "bac_c_physique_prompt.txt",
    ("BAC", "Sciences de la Vie et de la Terre", "D"): "bac_d_svt_prompt.txt",
}

# Combinaisons cibles pour le mode --all (pour viser 100+ questions finales).
# Chaque entree cible 20 questions par LLM, soit ~60 raw / combinaison,
# et ~15-20 validees apres cross-validation. Total ~120 questions.
ALL_TARGETS: List[Tuple[str, str, Optional[str], int]] = [
    ("BEPC", "Mathematiques", None, 25),
    ("BEPC", "Francais", None, 20),
    ("BEPC", "Sciences de la Vie et de la Terre", None, 20),
    ("BEPC", "Sciences Physiques", None, 20),
    ("BAC", "Mathematiques", "C", 20),
    ("BAC", "Sciences Physiques", "C", 20),
    ("BAC", "Sciences de la Vie et de la Terre", "D", 20),
]


# ─── Dataclasses ──────────────────────────────────────────────────────────


@dataclass
class GenerationResult:
    """Resultat d'une generation pour une combinaison (matiere, examen, serie).

    Attributes:
        examen: "BEPC" ou "BAC".
        matiere: libelle complet.
        serie: lettre de serie (BAC) ou None (BEPC).
        raw_questions: dict {source: liste_questions}.
        merged: liste validee apres cross-validation.
        schema_valid: liste validee par le schema.
        pedago_valid: liste validee par la pedagogie.
        not_duplicate: liste finale (non doublon).
        errors: liste d'erreurs detaillees par question rejetee.
    """

    examen: str
    matiere: str
    serie: Optional[str]
    raw_questions: Dict[str, List[Dict[str, Any]]] = field(default_factory=dict)
    merged: List[Dict[str, Any]] = field(default_factory=list)
    schema_valid: List[Dict[str, Any]] = field(default_factory=list)
    pedago_valid: List[Dict[str, Any]] = field(default_factory=list)
    not_duplicate: List[Dict[str, Any]] = field(default_factory=list)
    errors: List[Tuple[Dict[str, Any], List[str]]] = field(default_factory=list)


# ─── Helpers ──────────────────────────────────────────────────────────────


def find_prompt(
    examen: str,
    matiere: str,
    serie: Optional[str],
) -> Optional[Path]:
    """Trouve le fichier prompt pour une combinaison.

    Args:
        examen: "BEPC" ou "BAC".
        matiere: libelle complet ("Mathematiques", ...).
        serie: "A"/"B"/"C"/"D"/"F" ou None.

    Returns:
        Path vers le fichier prompt, ou None si introuvable.
    """
    # Normalisation : BAC1/BAC2/Probatoire -> BAC.
    examen_norm = "BAC" if examen.startswith("BAC") or examen == "Probatoire" else "BEPC"
    filename = PROMPT_MAPPING.get((examen_norm, matiere, serie))
    if not filename:
        logger.warning(
            "Aucun prompt trouve pour (examen=%s, matiere=%s, serie=%s)",
            examen, matiere, serie,
        )
        return None
    path = PROMPTS_DIR / filename
    if not path.exists():
        logger.warning("Fichier prompt introuvable: %s", path)
        return None
    return path


def load_prompt(
    examen: str,
    matiere: str,
    serie: Optional[str],
    annee: int = 2024,
    count: int = 30,
) -> Optional[str]:
    """Charge et formate un prompt template.

    Args:
        examen: "BEPC" ou "BAC".
        matiere: libelle complet.
        serie: lettre ou None.
        annee: annee de l'examen.
        count: nombre de questions demande.

    Returns:
        Prompt formate, ou None si prompt introuvable.
    """
    path = find_prompt(examen, matiere, serie)
    if path is None:
        return None
    template = path.read_text(encoding="utf-8")
    # Placeholders standards.
    niveau = "Terminale" if examen.startswith("BAC") else "3e"
    serie_str = serie if serie else "null"
    examen_for_prompt = examen
    # Pour BAC, le prompt attend {examen}=BAC (sans le 1/2).
    if examen.startswith("BAC"):
        examen_for_prompt = "BAC"
    return template.format(
        examen=examen_for_prompt,
        matiere=matiere,
        serie=serie_str,
        annee=annee,
        niveau=niveau,
        count=count,
        liste_chapitres="voir fichier prompt",
    )


def ensure_output_dirs() -> None:
    """Cree les dossiers de sortie s'ils n'existent pas."""
    for d in (CLAUDE_RAW_DIR, OPENAI_RAW_DIR, MISTRAL_RAW_DIR, MERGED_DIR, OUTPUT_ROOT):
        d.mkdir(parents=True, exist_ok=True)


def save_raw(
    source: str,
    examen: str,
    matiere: str,
    serie: Optional[str],
    questions: List[Dict[str, Any]],
) -> Path:
    """Sauvegarde les raw questions d'une source LLM.

    Args:
        source: "claude" / "openai" / "mistral".
        examen/matiere/serie: metadonnees.
        questions: liste brute retournee par le LLM.

    Returns:
        Chemin du fichier sauvegarde.
    """
    dir_map = {
        "claude": CLAUDE_RAW_DIR,
        "openai": OPENAI_RAW_DIR,
        "mistral": MISTRAL_RAW_DIR,
    }
    out_dir = dir_map.get(source, OUTPUT_ROOT)
    out_dir.mkdir(parents=True, exist_ok=True)
    serie_str = serie or "TOUTES"
    matiere_slug = matiere.replace(" ", "_").replace("-", "_")
    filename = f"{examen}_{matiere_slug}_{serie_str}.json"
    path = out_dir / filename
    with path.open("w", encoding="utf-8") as fh:
        json.dump(questions, fh, ensure_ascii=False, indent=2)
    logger.info("Sauvegarde raw %s: %s (%d questions)", source, path.name, len(questions))
    return path


def save_merged(
    examen: str,
    matiere: str,
    serie: Optional[str],
    questions: List[Dict[str, Any]],
) -> Path:
    """Sauvegarde le resultat merge+valide pour une combinaison.

    Args:
        examen/matiere/serie: metadonnees.
        questions: liste validee apres cross-validation + validators.

    Returns:
        Chemin du fichier sauvegarde.
    """
    MERGED_DIR.mkdir(parents=True, exist_ok=True)
    serie_str = serie or "TOUTES"
    matiere_slug = matiere.replace(" ", "_").replace("-", "_")
    filename = f"merged_{examen}_{matiere_slug}_{serie_str}.json"
    path = MERGED_DIR / filename
    with path.open("w", encoding="utf-8") as fh:
        json.dump(questions, fh, ensure_ascii=False, indent=2)
    logger.info("Sauvegarde merged: %s (%d questions)", path.name, len(questions))
    return path


def save_final(questions: List[Dict[str, Any]]) -> Path:
    """Sauvegarde la liste finale agreggee.

    Args:
        questions: liste de toutes les questions validees (toutes combinaisons).

    Returns:
        Chemin du fichier final.
    """
    FINAL_PATH.parent.mkdir(parents=True, exist_ok=True)
    with FINAL_PATH.open("w", encoding="utf-8") as fh:
        json.dump(questions, fh, ensure_ascii=False, indent=2)
    logger.info("Sauvegarde FINAL: %s (%d questions)", FINAL_PATH, len(questions))
    return FINAL_PATH


# ─── Generation via 3 LLM ─────────────────────────────────────────────────


async def generate_with_all_llms(
    matiere: str,
    examen: str,
    serie: Optional[str],
    count: int,
    annee: int = 2024,
) -> Dict[str, List[Dict[str, Any]]]:
    """Genere `count` questions via les 3 LLM en parallele.

    Args:
        matiere: libelle complet.
        examen: "BEPC" ou "BAC".
        serie: lettre ou None.
        count: nombre de questions demande a chaque LLM.
        annee: annee de l'examen.

    Returns:
        Dict {claude: [...], openai: [...], mistral: [...]}. Chaque liste est
        vide si la cle API est absente ou si toutes les tentatives echouent.
    """
    prompt = load_prompt(examen, matiere, serie, annee=annee, count=count)
    if prompt is None:
        logger.error(
            "Impossible de charger un prompt pour (examen=%s, matiere=%s, serie=%s)",
            examen, matiere, serie,
        )
        return {"claude": [], "openai": [], "mistral": []}

    logger.info(
        "Generation en parallele via 3 LLM (matiere=%s, examen=%s, serie=%s, count=%d)",
        matiere, examen, serie, count,
    )

    # Instantiation des 3 clients.
    tasks = [
        ClaudeClient().generate_questions(prompt, count),
        OpenAIClient().generate_questions(prompt, count),
        MistralClient().generate_questions(prompt, count),
    ]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    output: Dict[str, List[Dict[str, Any]]] = {}
    sources = ("claude", "openai", "mistral")
    for source, result in zip(sources, results):
        if isinstance(result, Exception):
            logger.error("Erreur %s: %s", source, result)
            output[source] = []
        elif not isinstance(result, list):
            logger.error(
                "%s: type inattendu %s (attendu list)", source, type(result).__name__
            )
            output[source] = []
        else:
            output[source] = result
    return output


# ─── Validation pipeline ──────────────────────────────────────────────────


def validate_pipeline(
    merged: List[Dict[str, Any]],
    checker: Optional[DuplicateChecker],
) -> Tuple[List[Dict[str, Any]], List[Tuple[Dict[str, Any], List[str]]]]:
    """Applique les 3 validators sur la liste mergee.

    Args:
        merged: liste validee par cross-validation 2/3.
        checker: DuplicateChecker initialise (ou None pour skip).

    Returns:
        Tuple (final_questions, all_rejected_with_errors).
    """
    final: List[Dict[str, Any]] = []
    rejected: List[Tuple[Dict[str, Any], List[str]]] = []

    for q in merged:
        errors: List[str] = []

        # 1. Schema.
        ok_schema, schema_errors = validate_schema_with_errors(q)
        if not ok_schema:
            errors.extend(schema_errors)

        # 2. Pedagogie (seulement si schema OK pour eviter cascades inutiles).
        ok_pedago = False
        if ok_schema:
            ok_pedago, pedago_errors = validate_pedagogy_with_errors(q)
            if not ok_pedago:
                errors.extend(pedago_errors)

        # 3. Doublons (seulement si schema + pedago OK).
        if ok_schema and ok_pedago and checker is not None:
            is_dup = check_duplicates(q, checker)
            if is_dup:
                errors.append("doublon vs questions existantes")

        if errors:
            rejected.append((q, errors))
        else:
            final.append(q)

    return final, rejected


# ─── Orchestration d'une combinaison ──────────────────────────────────────


async def process_one(
    examen: str,
    matiere: str,
    serie: Optional[str],
    count: int,
    checker: Optional[DuplicateChecker],
    annee: int = 2024,
    validate_only: bool = False,
) -> GenerationResult:
    """Genere + valide pour une combinaison (matiere, examen, serie).

    Args:
        examen/matiere/serie: metadonnees de la combinaison.
        count: nombre de questions a demander a chaque LLM.
        checker: DuplicateChecker initialise.
        annee: annee de l'examen.
        validate_only: si True, skip la generation et charge les raw existants.

    Returns:
        GenerationResult avec toutes les etapes.
    """
    result = GenerationResult(examen=examen, matiere=matiere, serie=serie)

    if validate_only:
        # Charge les raw existants.
        for source, raw_dir in (
            ("claude", CLAUDE_RAW_DIR),
            ("openai", OPENAI_RAW_DIR),
            ("mistral", MISTRAL_RAW_DIR),
        ):
            serie_str = serie or "TOUTES"
            matiere_slug = matiere.replace(" ", "_").replace("-", "_")
            path = raw_dir / f"{examen}_{matiere_slug}_{serie_str}.json"
            if path.exists():
                with path.open("r", encoding="utf-8") as fh:
                    result.raw_questions[source] = json.load(fh)
            else:
                logger.warning("Raw manquant pour %s: %s", source, path)
                result.raw_questions[source] = []
    else:
        # Generation via 3 LLM.
        result.raw_questions = await generate_with_all_llms(
            matiere=matiere, examen=examen, serie=serie, count=count, annee=annee,
        )
        # Sauvegarde raw.
        for source, questions in result.raw_questions.items():
            if questions:
                save_raw(source, examen, matiere, serie, questions)

    # Cross-validation 2/3.
    result.merged = merge_and_cross_validate(result.raw_questions)
    s = merge_stats(result.raw_questions, result.merged)
    logger.info(
        "Cross-val [%s/%s/%s]: raw=%d, merged=%d (%.1f%%)",
        examen, matiere, serie, s["total_raw"], s["total_merged"], s["validation_rate"],
    )

    # Validation pipeline (schema + pedago + doublons).
    final, rejected = validate_pipeline(result.merged, checker)
    result.not_duplicate = final
    result.errors = rejected

    # Sauvegarde merged (nettoye des metadonnees internes non-JSON-serializable).
    cleaned_merged = clean_metadata(result.merged)
    save_merged(examen, matiere, serie, cleaned_merged)

    logger.info(
        "Pipeline [%s/%s/%s]: merged=%d, final=%d, rejetees=%d",
        examen, matiere, serie,
        len(result.merged), len(final), len(rejected),
    )
    return result


# ─── Main async ───────────────────────────────────────────────────────────


async def async_main(args: argparse.Namespace) -> int:
    """Point d'entree async du script.

    Args:
        args: arguments parses par argparse.

    Returns:
        Code de sortie (0 = OK, 1 = erreur).
    """
    ensure_output_dirs()

    # Chargement des questions existantes pour la deduplication.
    existing = load_existing_questions()
    checker: Optional[DuplicateChecker] = DuplicateChecker(existing) if existing else None
    logger.info(
        "Charge %d questions existantes pour deduplication", len(existing)
    )

    # Construction de la liste des combinaisons a traiter.
    if args.all:
        targets = ALL_TARGETS
    elif args.validate_only and not args.matiere:
        # --validate-only sans --matiere : on revalide toutes les combinaisons.
        targets = ALL_TARGETS
    elif args.matiere:
        targets = [(args.examen, args.matiere, args.serie, args.count)]
    else:
        logger.error(
            "Specifier --matiere <M> ou --all. "
            "Voir --help pour les options."
        )
        return 1

    # Traitement sequentiel des combinaisons (pour eviter de saturer les API).
    all_final: List[Dict[str, Any]] = []
    summary: List[Dict[str, Any]] = []
    for examen, matiere, serie, count in targets:
        try:
            result = await process_one(
                examen=examen,
                matiere=matiere,
                serie=serie,
                count=count,
                checker=checker,
                annee=args.annee,
                validate_only=args.validate_only,
            )
            # Nettoyage metadonnees internes avant integration finale.
            cleaned = clean_metadata(result.not_duplicate)
            all_final.extend(cleaned)
            summary.append({
                "examen": examen,
                "matiere": matiere,
                "serie": serie,
                "raw_total": sum(len(v) for v in result.raw_questions.values()),
                "merged": len(result.merged),
                "final": len(cleaned),
                "rejected": len(result.errors),
            })
        except Exception as exc:  # noqa: BLE001
            logger.error(
                "Echec combinaison (%s/%s/%s): %s",
                examen, matiere, serie, exc,
            )

    # Sauvegarde finale agregee.
    save_final(all_final)

    # Rapport synthese.
    logger.info("=" * 60)
    logger.info("SYNTHESE FINALE")
    logger.info("=" * 60)
    for entry in summary:
        logger.info(
            "  %s/%s/%s : raw=%d, merged=%d, final=%d, rejetees=%d",
            entry["examen"], entry["matiere"], entry["serie"],
            entry["raw_total"], entry["merged"], entry["final"], entry["rejected"],
        )
    logger.info("-" * 60)
    logger.info(
        "TOTAL : %d questions finales pretes a integrer dans questions.json",
        len(all_final),
    )
    logger.info("Fichier final : %s", FINAL_PATH)
    return 0 if all_final else 2


# ─── CLI ──────────────────────────────────────────────────────────────────


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    """Parse les arguments CLI.

    Args:
        argv: liste d'arguments (defaut: sys.argv[1:]).

    Returns:
        Namespace avec les arguments parses.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Genere 100+ nouvelles questions BEPC/BAC via 3 LLM "
            "(Claude, GPT-4o, Mistral) avec validation croisee 2/3."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Exemples:\n"
            "  # Generation pour une matiere\n"
            "  python generate_questions_3llm.py \\\n"
            "      --matiere Mathematiques --examen BEPC --count 30\n\n"
            "  # Generation sur toutes les combinaisons\n"
            "  python generate_questions_3llm.py --all\n\n"
            "  # Skip generation, juste re-valider les raw existants\n"
            "  python generate_questions_3llm.py --validate-only\n"
        ),
    )
    parser.add_argument(
        "--matiere",
        type=str,
        help="Matiere cible (ex: Mathematiques, Francais, SVT, ...).",
    )
    parser.add_argument(
        "--examen",
        type=str,
        default="BEPC",
        choices=["BEPC", "BAC", "BAC1", "BAC2", "Probatoire"],
        help="Examen cible (defaut: BEPC).",
    )
    parser.add_argument(
        "--serie",
        type=str,
        default=None,
        choices=["A", "B", "C", "D", "F"],
        help="Serie BAC (A/B/C/D/F). Pour BEPC, laisser vide.",
    )
    parser.add_argument(
        "--count",
        type=int,
        default=30,
        help="Nombre de questions a demander a chaque LLM (defaut: 30).",
    )
    parser.add_argument(
        "--annee",
        type=int,
        default=2024,
        help="Annee de l'examen (defaut: 2024).",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Generer sur toutes les combinaisons predefinies (100+ questions).",
    )
    parser.add_argument(
        "--validate-only",
        action="store_true",
        help="Skip la generation LLM, revalider uniquement les raw existants.",
    )
    return parser.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    """Point d'entree sync (wrapper autour de async_main).

    Args:
        argv: liste d'arguments (defaut: sys.argv[1:]).

    Returns:
        Code de sortie.
    """
    args = parse_args(argv)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    )
    return asyncio.run(async_main(args))


if __name__ == "__main__":
    sys.exit(main())
