"""Structure le texte OCR en questions JSON.

Approche déterministe (sans LLM, pour démonstration offline) :
  1. Découpe le texte par exercice (« Exercice N (P points) »).
  2. Dans chaque exercice, extrait les sous-questions numérotées
     (« 1. », « 2. », ...).
  3. Pour chaque question :
     - enonce = texte après le numéro, nettoyé des caractères de bruit OCR.
     - reponse = "" (à remplir par un humain ou un LLM ultérieurement).
     - explication = "" (idem).
     - matiere / examen / annee / serie = depuis le nom de fichier.
     - type = "ouvert" par défaut (sans plus de contexte, on ne peut pas
       décider entre calcul, qcm, vraiFaux, redaction).
     - points = points de l'exercice divisés par le nombre de questions.
     - irt.b = estimation heuristique (voir _estimate_irt_b).
  4. Sauvegarde en JSON par matière + un JSON agrégé dans final/.

Pour un déploiement réel, remplacer la regex par un appel LLM (GPT-4o-mini ou
Claude) avec un prompt structuré — voir Agent AG (llm_generation) et
data_pipeline/structure_questions.py pour l'implémentation de référence.

Usage :
    python structure_extracted.py
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

BASE_DIR = Path(__file__).resolve().parent
EXTRACTED_TEXT_DIR = BASE_DIR / "extracted_text"
STRUCTURED_DIR = BASE_DIR / "structured_questions"
FINAL_DIR = BASE_DIR / "final"

# Mapping matiere -> code 4 lettres utilisé dans les IDs (convention
# ExamBoost, alignée avec assets/data/questions.json).
MATIERE_CODES = {
    "Mathématiques": "MATH",
    "Français": "FRAN",
    "Sciences Physiques": "PHYS",
    "Sciences de la Vie et de la Terre": "SVT",
    "Histoire-Géographie": "HIST",
}

# Liste des 5 PDFs à traiter : (txt, matiere, annee, json_out).
PIPELINE_ITEMS: List[Tuple[str, str, int, str]] = [
    ("bepc_maths_2022.txt", "Mathématiques", 2022,
     "bepc_maths_2022_questions.json"),
    ("bepc_francais_2021.txt", "Français", 2021,
     "bepc_francais_2021_questions.json"),
    ("bepc_sciences_2023.txt", "Sciences Physiques", 2023,
     "bepc_sciences_2023_questions.json"),
    ("bepc_svt_2020.txt", "Sciences de la Vie et de la Terre", 2020,
     "bepc_svt_2020_questions.json"),
    ("bepc_histoire_2022.txt", "Histoire-Géographie", 2022,
     "bepc_histoire_2022_questions.json"),
]


# ─── Regex de parsing ──────────────────────────────────────────────────────
#
# Tesseract normalise assez bien « Exercice N (P points) » mais peut
# insérer des espaces parasites ou confondre 0 et O. On reste large :
#   - « Exercice » peut avoir une typo (« Exercice », « Exercicee »).
#   - Le numéro peut être 1 chiffre ou plus.
#   - « points » est parfois au singulier.
EXERCISE_RE = re.compile(
    r"Exercice\s+(\d+)\s*\(\s*(\d+)\s*points?\s*\)",
    re.IGNORECASE,
)

# Question numérotée en début de ligne : « 1. », « 2) », « 3 - », « 1, ».
# On accepte . ) - , comme séparateur. Le numéro doit être en début de
# paragraphe (après une nouvelle ligne ou le début du texte).
QUESTION_RE = re.compile(
    r"(?:^|\n)\s*(\d{1,2})\s*[.)\-,]\s+([^\n]+(?:\n(?!\s*\d{1,2}\s*[.)\-,])[^\n]+)*)",
    re.MULTILINE,
)


@dataclass
class StructuringStats:
    """Statistiques de structuration pour un fichier texte."""

    txt_name: str
    matiere: str
    annee: int
    num_exercises: int = 0
    num_questions: int = 0
    output_json: str = ""


# ─── Nettoyage du texte OCR ────────────────────────────────────────────────


def _clean_ocr_text(text: str) -> str:
    """Nettoie le texte OCR : whitespace, séparateurs de page, artefacts.

    Les séparateurs « === PAGE N === » insérés par run_real_ocr.py sont
    conservés dans le .txt pour débogage mais neutralisés ici (remplacés
    par une nouvelle ligne) pour éviter de casser la détection d'exercices.
    """
    # Supprime les marqueurs de page.
    text = re.sub(r"={2,}\s*PAGE\s+\d+\s*={2,}", "\n", text, flags=re.IGNORECASE)
    # Collapse les espaces multiples (mais préserve les nouvelles lignes).
    text = re.sub(r"[^\S\n]+", " ", text)
    # Strip les espaces en début/fin de ligne.
    text = re.sub(r" *\n *", "\n", text)
    # Plusieurs newlines consécutifs -> un seul.
    text = re.sub(r"\n{2,}", "\n", text)
    return text.strip()


def _clean_question_text(text: str) -> str:
    """Nettoie le texte d'une question individuelle."""
    # Collapse whitespace.
    text = re.sub(r"\s+", " ", text).strip()
    # Supprime les pipes et crochets orphelins fréquents en OCR.
    text = re.sub(r"^\s*[\|\[\]\{\}]+\s*", "", text)
    text = re.sub(r"\s*[\|\[\]\{\}]+\s*$", "", text)
    # Supprime les espaces avant ponctuation finale.
    text = re.sub(r"\s+([.,;:?!])", r"\1", text)
    return text.strip()


# ─── Estimation IRT heuristique ───────────────────────────────────────────


def _estimate_irt_b(matiere: str, points: int, annee: int) -> float:
    """Estimation heuristique du paramètre IRT b (difficulté).

    Alignée sur estimate_irt.py du pipeline principal :
      - base 0.0
      - +0.4 si Sciences Physiques ou Maths (scientifique)
      - +0.3 si SVT
      - +0.1 si Histoire-Géo
      - +0.3 si points >= 4
      - +0.1 par année récente (> 2021)
    """
    b = 0.0
    if matiere in ("Sciences Physiques", "Mathématiques"):
        b += 0.4
    elif matiere == "Sciences de la Vie et de la Terre":
        b += 0.3
    elif matiere == "Histoire-Géographie":
        b += 0.1
    if points >= 4:
        b += 0.3
    if annee > 2021:
        b += 0.1
    # Arrondi à 1 décimale.
    return round(b, 1)


# ─── Parsing ───────────────────────────────────────────────────────────────


def _split_exercises(text: str) -> List[Tuple[int, int, str]]:
    """Découpe le texte en exercices.

    Returns:
        Liste de tuples (num_exercice, points, contenu_texte). Si aucun
        exercice n'est détecté, retourne [(1, 0, text)] pour ne pas perdre
        le contenu.
    """
    matches = list(EXERCISE_RE.finditer(text))
    if not matches:
        return [(1, 0, text)]

    exercises: List[Tuple[int, int, str]] = []
    for i, m in enumerate(matches):
        ex_num = int(m.group(1))
        ex_points = int(m.group(2))
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        # Le contenu commence après la ligne « Exercice N (P points) ».
        # On saute le reste de la ligne courante (jusqu'au premier \n).
        first_newline = text.find("\n", start)
        if first_newline != -1 and first_newline < end:
            content_start = first_newline + 1
        else:
            content_start = start
        content = text[content_start:end].strip()
        exercises.append((ex_num, ex_points, content))
    return exercises


def _extract_questions_from_block(block: str) -> List[Tuple[str, str]]:
    """Extrait les questions numérotées d'un bloc d'exercice.

    Returns:
        Liste de tuples (numero_question, texte_question).
    """
    questions: List[Tuple[str, str]] = []
    seen = set()
    for m in QUESTION_RE.finditer(block):
        num = m.group(1)
        raw = m.group(2)
        cleaned = _clean_question_text(raw)
        # Filtre le bruit : trop court, doublon, ou qui ressemble à du
        # bruit OCR (commence par un chiffre isolé + ponctuation).
        if len(cleaned) < 10:
            continue
        if num in seen:
            continue
        # Évite les faux positifs comme « 20 %. » collé à un texte.
        if cleaned.startswith((".", ",", ";", ":", ")", "]")):
            continue
        seen.add(num)
        questions.append((num, cleaned))
    return questions


def structure_text_to_questions(
    txt_path: Path,
    matiere: str,
    annee: int,
    output_json: Path,
) -> Tuple[List[Dict], StructuringStats]:
    """Structure un fichier texte OCR en liste de questions JSON.

    Args:
        txt_path: fichier .txt produit par run_real_ocr.py.
        matiere: matière au format lisible (Mathématiques, Français, ...).
        annee: année de session extraite du nom de fichier.
        output_json: chemin du JSON de sortie par matière.

    Returns:
        Tuple (questions, stats).
    """
    stats = StructuringStats(
        txt_name=txt_path.name, matiere=matiere, annee=annee,
        output_json=str(output_json),
    )

    if not txt_path.exists():
        print(f"  ERREUR : fichier OCR introuvable : {txt_path}")
        return [], stats

    raw_text = txt_path.read_text(encoding="utf-8")
    cleaned_text = _clean_ocr_text(raw_text)

    code = MATIERE_CODES.get(matiere, matiere.upper()[:4])
    questions: List[Dict] = []
    q_counter = 0

    exercises = _split_exercises(cleaned_text)
    stats.num_exercises = len(exercises)
    print(f"  {len(exercises)} exercice(s) détecté(s) dans {txt_path.name}")

    for ex_num, ex_points, ex_content in exercises:
        ex_questions = _extract_questions_from_block(ex_content)
        if not ex_questions:
            print(f"    Exercice {ex_num} : aucune question détectée")
            continue

        # Estimation des points par question (répartition équitable).
        points_per_q = ex_points // len(ex_questions) if ex_questions else 0

        for q_num, q_text in ex_questions:
            q_counter += 1
            irt_b = _estimate_irt_b(matiere, points_per_q, annee)
            question = {
                "id": f"TG-BEPC-{code}-{annee}-OCR-Q{q_counter:02d}",
                "enonce": q_text,
                "reponse": "",
                "explication": "",
                "matiere": matiere,
                "chapitre": f"Exercice {ex_num}",
                "competence_id": f"TG-{code}-OCR-{q_counter:03d}",
                "examen": "BEPC",
                "serie": None,
                "annee": annee,
                "type": "ouvert",
                "choix": None,
                "points": points_per_q,
                "irt": {
                    "a": None,
                    "b": irt_b,
                    "c": None,
                    "calibre": False,
                },
                "source": "ocr_pipeline",
                "source_pdf": txt_path.stem.replace(".txt", "") + ".pdf",
                "original_exercise": ex_num,
                "original_question_number": q_num,
            }
            questions.append(question)

    stats.num_questions = len(questions)

    # Sauvegarde du JSON par matière.
    output_json.parent.mkdir(parents=True, exist_ok=True)
    output_json.write_text(
        json.dumps(questions, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(f"  {len(questions)} questions structurées -> "
          f"{output_json.relative_to(BASE_DIR)}")
    return questions, stats


# ─── Driver ────────────────────────────────────────────────────────────────


def main() -> int:
    """Structure les 5 fichiers OCR et fusionne dans final/."""
    print("=== Structuration du texte OCR en questions JSON ===")
    print()

    all_questions: List[Dict] = []
    all_stats: List[StructuringStats] = []

    for txt_name, matiere, annee, json_name in PIPELINE_ITEMS:
        txt_path = EXTRACTED_TEXT_DIR / txt_name
        json_path = STRUCTURED_DIR / json_name
        print(f"-- {matiere} ({annee}) --")
        questions, stats = structure_text_to_questions(
            txt_path, matiere, annee, json_path
        )
        all_questions.extend(questions)
        all_stats.append(stats)
        print()

    # JSON agrégé final.
    FINAL_DIR.mkdir(parents=True, exist_ok=True)
    final_path = FINAL_DIR / "ocr_extracted_questions.json"
    final_path.write_text(
        json.dumps(all_questions, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    # Rapport de stats.
    stats_path = FINAL_DIR / "structuring_stats.json"
    stats_path.write_text(
        json.dumps(
            {
                "total_files": len(all_stats),
                "total_exercises": sum(s.num_exercises for s in all_stats),
                "total_questions": len(all_questions),
                "per_file": [s.__dict__ for s in all_stats],
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    print("=== Synthèse structuration ===")
    print(f"  Fichiers traités : {len(all_stats)}")
    print(f"  Exercices détectés : {sum(s.num_exercises for s in all_stats)}")
    print(f"  Questions structurées : {len(all_questions)}")
    print(f"  JSON agrégé : {final_path.relative_to(BASE_DIR)}")
    print(f"  Stats : {stats_path.relative_to(BASE_DIR)}")
    print()
    print(f"{len(all_questions)} questions OCR-isées prêtes pour la validation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
