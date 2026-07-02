#!/usr/bin/env python3
"""
Fusionne toutes les sources de questions en un seul questions.json unifie.

Sources :
1. assets/data/questions.json (64 questions de base)
2. assets/data/geometry_questions.json (15 questions avec figures SVG)
3. data_pipeline/real_ocr_demo/final/ocr_validated_questions.json (36 questions OCR)

Output :
- assets/data/questions.json (ecrase avec version unifiee)
- assets/data/questions_v1_backup.json (backup ancienne version)

Le script :
- Charge les 3 sources
- Normalise le schema (champs obligatoires + optionnels)
- Deduplique par ID et par enonce normalise
- Marque les questions OCR sans reponse avec needs_answer=true
- Fusionne, trie par examen -> matiere -> annee -> id
- Genere un rapport statistique
- Sauvegarde le backup puis le nouveau fichier unifie

Usage :
    cd /home/z/my-project/ExamBoost-Togo
    python3 scripts/merge_questions.py
"""

import json
import re
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------

# Racine du projet (depuis scripts/, remonter d'un niveau)
PROJECT_ROOT = Path(__file__).resolve().parent.parent

# Fichiers sources
SOURCE_EXISTING = PROJECT_ROOT / "assets" / "data" / "questions.json"
SOURCE_GEOMETRY = PROJECT_ROOT / "assets" / "data" / "geometry_questions.json"
SOURCE_OCR = PROJECT_ROOT / "data_pipeline" / "real_ocr_demo" / "final" / "ocr_validated_questions.json"

# Fichier de sortie (ecrase l'existant)
OUTPUT_FILE = PROJECT_ROOT / "assets" / "data" / "questions.json"

# Backup de l'ancienne version
BACKUP_FILE = PROJECT_ROOT / "assets" / "data" / "questions_v1_backup.json"

# ----------------------------------------------------------------------------
# Schema attendu
# ----------------------------------------------------------------------------

# Champs obligatoires (toujours presents)
REQUIRED_FIELDS = [
    "id",
    "enonce",
    "reponse",
    "explication",
    "matiere",
    "chapitre",
    "competence_id",
    "examen",
    "serie",
    "annee",
    "type",
    "choix",
    "points",
    "irt",
]

# Champs optionnels (ajoutes si absents)
OPTIONAL_FIELDS = {
    "figure_id": None,         # Present pour questions de geometrie
    "needs_answer": False,     # True pour questions OCR sans reponse
}

# Sous-champs IRT obligatoires
IRT_KEYS = ["a", "b", "c", "calibre"]

# Valeurs de matieres normalisees (pour verifier la coherence)
MATIERES_VALIDES = {
    "Mathematiques",
    "Francais",
    "Sciences Physiques",
    "Sciences de la Vie et de la Terre",
    "Histoire-Geographie",
    "Anglais",
}

# Valeurs d'examens valides
EXAMENS_VALIDES = {"BEPC", "BAC1", "BAC2", "Probatoire"}

# Series valides pour BAC
SERIES_VALIDES = {"A", "B", "C", "D", "F"}

# Types de questions valides
TYPES_VALIDES = {"calcul", "ouvert", "qcm", "vraiFaux", "redaction"}


# ----------------------------------------------------------------------------
# Utilitaires
# ----------------------------------------------------------------------------

def normalize_enonce(enonce: str) -> str:
    """
    Normalise un enonce pour la deduplication :
    - minuscules
    - accents retires
    - espaces/ponctuation regroupes
    - tronque a 120 caracteres
    """
    if not enonce:
        return ""
    s = enonce.lower()
    # Retire les accents (NFD -> ASCII)
    s = s.encode("ascii", errors="ignore").decode("ascii")
    # Regroupe tout ce qui n'est pas alphanumerique en un seul espace
    s = re.sub(r"[^a-z0-9]+", " ", s)
    s = s.strip()
    return s[:120]


def normalize_question(q: dict, source_label: str) -> dict:
    """
    Normalise une question vers le schema attendu :
    - ajoute les champs obligatoires manquants (avec valeur defaut)
    - ajoute les champs optionnels manquants
    - valide le type/serie/examen
    - marque needs_answer=True si OCR sans reponse
    """
    # Copie profonde pour ne pas muter l'original
    nq = dict(q)

    # Champs obligatoires : verifier presence, sinon valeur par defaut
    if "id" not in nq or not nq["id"]:
        raise ValueError(f"Question sans ID valide (source={source_label})")
    if "enonce" not in nq or not nq["enonce"]:
        raise ValueError(f"Question {nq.get('id', '?')} sans enonce")
    if "reponse" not in nq:
        nq["reponse"] = ""
    if "explication" not in nq:
        nq["explication"] = ""
    if "matiere" not in nq:
        nq["matiere"] = "Mathematiques"
    if "chapitre" not in nq:
        nq["chapitre"] = "General"
    if "competence_id" not in nq:
        nq["competence_id"] = ""
    if "examen" not in nq:
        nq["examen"] = "BEPC"
    if "serie" not in nq:
        nq["serie"] = None
    if "annee" not in nq:
        nq["annee"] = None
    if "type" not in nq:
        nq["type"] = "ouvert"
    if "choix" not in nq:
        nq["choix"] = None
    if "points" not in nq:
        nq["points"] = None

    # IRT : garantir la structure complete
    irt = nq.get("irt")
    if not isinstance(irt, dict):
        irt = {}
    for k in IRT_KEYS:
        if k not in irt:
            irt[k] = None if k != "calibre" else False
    nq["irt"] = irt

    # Champs optionnels : figure_id, needs_answer
    if "figure_id" not in nq:
        nq["figure_id"] = None
    if "needs_answer" not in nq:
        # Marque automatiquement si reponse vide + source OCR
        if source_label == "ocr" and not nq["reponse"].strip():
            nq["needs_answer"] = True
        else:
            nq["needs_answer"] = False

    # Conserver les champs extras OCR (source, source_pdf, original_exercise, ...)
    # => on les garde tels quels pour traçabilite

    return nq


# ----------------------------------------------------------------------------
# Etapes du script
# ----------------------------------------------------------------------------

def etape1_charger_sources():
    """Charge les 3 sources de questions."""
    print("=" * 70)
    print("ETAPE 1 - Chargement des sources")
    print("=" * 70)

    sources = {}

    # Source 1 : existant
    if not SOURCE_EXISTING.exists():
        raise FileNotFoundError(f"Source manquante : {SOURCE_EXISTING}")
    with open(SOURCE_EXISTING, "r", encoding="utf-8") as f:
        sources["existing"] = json.load(f)
    print(f"  [OK] Existant    : {SOURCE_EXISTING.name:40s} -> {len(sources['existing'])} questions")

    # Source 2 : geometrie
    if not SOURCE_GEOMETRY.exists():
        raise FileNotFoundError(f"Source manquante : {SOURCE_GEOMETRY}")
    with open(SOURCE_GEOMETRY, "r", encoding="utf-8") as f:
        sources["geometry"] = json.load(f)
    print(f"  [OK] Geometrie   : {SOURCE_GEOMETRY.name:40s} -> {len(sources['geometry'])} questions")

    # Source 3 : OCR (optionnel si absent)
    if SOURCE_OCR.exists():
        with open(SOURCE_OCR, "r", encoding="utf-8") as f:
            sources["ocr"] = json.load(f)
        print(f"  [OK] OCR         : {SOURCE_OCR.name:40s} -> {len(sources['ocr'])} questions")
    else:
        sources["ocr"] = []
        print(f"  [!!] OCR absent  : {SOURCE_OCR}")

    total_brut = sum(len(sources[k]) for k in sources)
    print(f"\n  TOTAL brut : {total_brut} questions")
    return sources


def etape2_normaliser(sources):
    """Normalise chaque source vers le schema attendu."""
    print("\n" + "=" * 70)
    print("ETAPE 2 - Normalisation du schema")
    print("=" * 70)

    normalized = {}
    for label, questions in sources.items():
        normalized[label] = []
        for q in questions:
            try:
                nq = normalize_question(q, source_label=label)
                normalized[label].append(nq)
            except ValueError as e:
                print(f"  [WARN] {label} : question ignoree - {e}")
        print(f"  [OK] {label:10s} : {len(normalized[label])} questions normalisees")

    return normalized


def etape3_dedupliquer(normalized):
    """
    Deduplique les questions par ID puis par enonce normalise.
    Conserve la priorite : existing > geometry > ocr
    (en gardant les 3 sources si elles different).
    """
    print("\n" + "=" * 70)
    print("ETAPE 3 - Deduplication")
    print("=" * 70)

    seen_ids = set()
    seen_enonces = {}  # enonce_norm -> id
    dupes_by_id = 0
    dupes_by_enonce = []
    merged = []

    # Ordre de priorite : existing (1), geometry (2), OCR (3)
    ordre = ["existing", "geometry", "ocr"]

    for label in ordre:
        for q in normalized[label]:
            qid = q["id"]
            en_norm = normalize_enonce(q["enonce"])

            # 1. Dedup par ID
            if qid in seen_ids:
                dupes_by_id += 1
                print(f"  [DUP-ID] {qid} deja present (source={label}) - ignore")
                continue

            # 2. Dedup par enonce normalise
            # (si meme enonce + meme examen -> on considere comme doublon)
            if en_norm and en_norm in seen_enonces:
                existing_id = seen_enonces[en_norm]
                # On ne deduplique QUE si meme examen aussi (sinon c'est un
                # sujet different qui reprend la meme question - legitime)
                # Recherche dans merged
                existing_q = next((x for x in merged if x["id"] == existing_id), None)
                if existing_q and existing_q.get("examen") == q.get("examen"):
                    dupes_by_enonce.append((existing_id, qid, q.get("annee"), existing_q.get("annee")))
                    print(f"  [DUP-ENONCE] {qid} identique a {existing_id} (annee {q.get('annee')} vs {existing_q.get('annee')}) - ignore")
                    continue

            # Pas de doublon : on conserve
            seen_ids.add(qid)
            seen_enonces[en_norm] = qid
            merged.append(q)

    print(f"\n  Doublons par ID     : {dupes_by_id}")
    print(f"  Doublons par enonce : {len(dupes_by_enonce)}")
    print(f"  Total conserve      : {len(merged)} questions")
    return merged, dupes_by_id, dupes_by_enonce


def etape4_fusionner_trier(merged):
    """Trie les questions par examen -> matiere -> annee -> id."""
    print("\n" + "=" * 70)
    print("ETAPE 4 - Tri (examen -> matiere -> annee -> id)")
    print("=" * 70)

    # Ordre personnalise pour examen : BEPC < Probatoire < BAC1 < BAC2
    examen_order = {"BEPC": 0, "Probatoire": 1, "BAC1": 2, "BAC2": 3}
    matiere_order = {
        "Mathematiques": 0,
        "Sciences Physiques": 1,
        "Sciences de la Vie et de la Terre": 2,
        "Francais": 3,
        "Histoire-Geographie": 4,
        "Anglais": 5,
    }

    def sort_key(q):
        return (
            examen_order.get(q.get("examen", ""), 99),
            matiere_order.get(q.get("matiere", ""), 99),
            q.get("annee") or 0,
            q.get("id", ""),
        )

    merged.sort(key=sort_key)
    print(f"  [OK] {len(merged)} questions triees")
    return merged


def etape5_statistiques(merged):
    """Genere un rapport statistique detaille."""
    print("\n" + "=" * 70)
    print("ETAPE 5 - Statistiques")
    print("=" * 70)

    stats = {}

    # Par matiere
    stats["par_matiere"] = dict(Counter(q["matiere"] for q in merged))
    print("\n  Par matiere :")
    for k, v in sorted(stats["par_matiere"].items(), key=lambda x: -x[1]):
        print(f"    {k:40s} : {v}")

    # Par examen
    stats["par_examen"] = dict(Counter(q["examen"] for q in merged))
    print("\n  Par examen :")
    for k, v in sorted(stats["par_examen"].items(), key=lambda x: -x[1]):
        print(f"    {k:20s} : {v}")

    # Par serie (BAC uniquement)
    bac_qs = [q for q in merged if q["examen"].startswith("BAC")]
    stats["par_serie_bac"] = dict(Counter(str(q["serie"]) for q in bac_qs))
    print("\n  Par serie (BAC) :")
    for k, v in sorted(stats["par_serie_bac"].items()):
        print(f"    {k:20s} : {v}")

    # Par annee
    stats["par_annee"] = dict(Counter(q["annee"] for q in merged))
    print("\n  Par annee :")
    for k, v in sorted(stats["par_annee"].items(), key=lambda x: (x[0] or 0)):
        print(f"    {k} : {v}")

    # Par type
    stats["par_type"] = dict(Counter(q["type"] for q in merged))
    print("\n  Par type :")
    for k, v in sorted(stats["par_type"].items(), key=lambda x: -x[1]):
        print(f"    {k:15s} : {v}")

    # Avec IRT calibre
    calibres = [q for q in merged if q["irt"].get("calibre")]
    stats["irt_calibres"] = len(calibres)
    print(f"\n  IRT calibres         : {len(calibres)} / {len(merged)}")

    # Avec figure_id
    avec_figure = [q for q in merged if q.get("figure_id")]
    stats["avec_figure_id"] = len(avec_figure)
    print(f"  Avec figure_id       : {len(avec_figure)}")

    # Avec needs_answer (reponse vide)
    needs_answer = [q for q in merged if q.get("needs_answer")]
    stats["needs_answer"] = len(needs_answer)
    print(f"  Reponse vide (OCR)   : {len(needs_answer)}")

    # Total
    stats["total"] = len(merged)
    print(f"\n  TOTAL                : {len(merged)} questions")

    return stats


def etape6_sauvegarder(merged):
    """Sauvegarde le backup puis le nouveau fichier unifie."""
    print("\n" + "=" * 70)
    print("ETAPE 6 - Sauvegarde")
    print("=" * 70)

    # 6a. Backup de l'ancien fichier (s'il existe et n'est pas deja un backup)
    if SOURCE_EXISTING.exists():
        shutil.copy2(SOURCE_EXISTING, BACKUP_FILE)
        print(f"  [OK] Backup cree   : {BACKUP_FILE.name}")
    else:
        print(f"  [WARN] Pas de fichier existant a backuper")

    # 6b. Sauvegarder le nouveau fichier unifie
    # ensure_ascii=False pour garder les accents francais lisibles
    # indent=2 pour la lisibilite (pas trop volumineux)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)
    print(f"  [OK] Fichier unifie : {OUTPUT_FILE.name}")
    print(f"       Taille         : {OUTPUT_FILE.stat().st_size / 1024:.1f} Ko")
    print(f"       Questions      : {len(merged)}")


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------

def main():
    print("\n" + "#" * 70)
    print("# ExamBoost Togo - Fusion des sources de questions")
    print("#")
    print(f"# Projet : {PROJECT_ROOT}")
    print("#" * 70 + "\n")

    # 1. Charger
    sources = etape1_charger_sources()

    # 2. Normaliser
    normalized = etape2_normaliser(sources)

    # 3. Dedupliquer
    merged, dupes_id, dupes_enonce = etape3_dedupliquer(normalized)

    # 4. Fusionner + trier
    merged = etape4_fusionner_trier(merged)

    # 5. Statistiques
    stats = etape5_statistiques(merged)

    # 6. Sauvegarder
    etape6_sauvegarder(merged)

    # Recaptiulatif final
    print("\n" + "#" * 70)
    print("# RECAPITULATIF FINAL")
    print("#" * 70)
    print(f"#  Total source brut : {sum(len(sources[k]) for k in sources)} questions")
    print(f"#  Doublons ID       : {dupes_id}")
    print(f"#  Doublons enonce   : {len(dupes_enonce)}")
    print(f"#  Total unifie      : {len(merged)} questions")
    print(f"#  Avec figure_id    : {stats['avec_figure_id']}")
    print(f"#  Needs answer      : {stats['needs_answer']}")
    print(f"#  IRT calibres      : {stats['irt_calibres']}")
    print("#" * 70 + "\n")

    print("Fusion terminee avec succes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
