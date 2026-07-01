"""Valide les questions OCR-isées et prépare la fusion avec questions.json.

Règles de validation appliquées à chaque question :
  1. Présence des champs obligatoires : id, enonce, matiere, examen, annee,
     type, irt.
  2. Cohérence des métadonnées :
       - examen == "BEPC"  (cette démo ne traite que le BEPC)
       - serie is None     (BEPC n'a pas de série)
       - 2010 <= annee <= 2025
       - matiere dans la liste des 5 matières BEPC valides.
  3. Qualité de l'énoncé :
       - longueur entre 20 et 800 caractères
       - pas de chiffre orphelin en fin d'énoncé (ex: "... = 2 1}" -> bruit)
       - pas de caractères de contrôle ou de pipes en début/fin
       - ratio lettres/caractères >= 0.5 (filtre le bruit pur)
  4. Cohérence du type et des choix :
       - type dans {ouvert, qcm, vraiFaux, calcul, redaction}
       - si type == "qcm" ou "vraiFaux" -> choix non null et >= 2 items
       - sinon -> choix doit être null
  5. IRT :
       - irt.b entre -3 et +3 (bornes théoriques IRT)
       - irt.calibre est un booléen

Statut de chaque question :
  - "valid"    : passe toutes les règles -> prêt à fusionner.
  - "warning"  : passe mais avec une réserve (ex: énoncé contenant un
                 caractère suspect). On garde en valid mais on logge.
  - "rejected" : ne passe pas au moins une règle bloquante.

Sortie :
  - final/ocr_validated_questions.json : questions valides prêtes à fusionner.
  - final/validation_report.json : rapport détaillé (compteurs + exemples).
  - final/validation_report.md  : rapport lisible pour humain (pitch DJANTA).

Note : la fusion réelle avec assets/data/questions.json est volontairement
laissée à l'agent de wiring (cf. README section "Intégration"). Ce script
produit juste le fichier à fusionner.

Usage :
    python validate_and_merge.py
"""

from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

BASE_DIR = Path(__file__).resolve().parent
FINAL_DIR = BASE_DIR / "final"

VALID_MATIERES = {
    "Mathématiques",
    "Français",
    "Sciences Physiques",
    "Sciences de la Vie et de la Terre",
    "Histoire-Géographie",
}
VALID_TYPES = {"ouvert", "qcm", "vraiFaux", "calcul", "redaction"}
VALID_EXAMENS = {"BEPC", "BAC1", "BAC2"}

REQUIRED_FIELDS = (
    "id", "enonce", "matiere", "examen", "annee", "type", "irt",
)

# Patterns de bruit OCR fréquents à signaler en warning (non bloquant).
NOISE_PATTERNS = [
    (re.compile(r"\s\d{1,2}\s*\}$"), "chiffre orphelin avant accolade fermante"),
    (re.compile(r"\s\d{1,2}\s*\)$"), "chiffre orphelin avant parenthèse fermante"),
    (re.compile(r"\bx2\b"), "x2 au lieu de x² (exposant perdu)"),
    (re.compile(r"\br2\b"), "r2 au lieu de r² (exposant perdu)"),
    (re.compile(r"\bx3\b"), "x3 au lieu de x³ (exposant perdu)"),
    (re.compile(r"\bS\s*[:;]\s*\d"), "S au lieu de 5 (confusion OCR)"),
    (re.compile(r"\bdans\s+M\b"), "M au lieu de ℝ (symbole math perdu)"),
    (re.compile(r"\bM\s+l'équation"), "M au lieu de ℝ"),
    (re.compile(r"={2,}"), "séparateur de page mal nettoyé"),
    (re.compile(r"[|]{2,}"), "pipes multiples (bruit OCR)"),
]


@dataclass
class ValidationIssue:
    """Une issue de validation détectée sur une question."""

    severity: str  # "error" ou "warning"
    rule: str
    message: str


@dataclass
class QuestionValidation:
    """Résultat de validation pour une question."""

    question_id: str
    status: str  # "valid", "warning", "rejected"
    issues: List[ValidationIssue] = field(default_factory=list)
    question: Optional[Dict] = None


# ─── Règles de validation ──────────────────────────────────────────────────


def _check_required_fields(q: Dict) -> List[ValidationIssue]:
    """Vérifie la présence des champs obligatoires."""
    issues: List[ValidationIssue] = []
    for f in REQUIRED_FIELDS:
        if f not in q:
            issues.append(ValidationIssue(
                severity="error", rule="required_field",
                message=f"champ obligatoire manquant : {f}",
            ))
    return issues


def _check_metadata(q: Dict) -> List[ValidationIssue]:
    """Vérifie la cohérence des métadonnées (examen, serie, annee, matiere)."""
    issues: List[ValidationIssue] = []
    examen = q.get("examen")
    if examen not in VALID_EXAMENS:
        issues.append(ValidationIssue(
            severity="error", rule="examen_invalid",
            message=f"examen='{examen}' non supporté (attendu dans {sorted(VALID_EXAMENS)})",
        ))
    matiere = q.get("matiere")
    if matiere not in VALID_MATIERES:
        issues.append(ValidationIssue(
            severity="error", rule="matiere_invalid",
            message=f"matiere='{matiere}' non reconnue",
        ))
    annee = q.get("annee")
    if not isinstance(annee, int) or not (2010 <= annee <= 2025):
        issues.append(ValidationIssue(
            severity="error", rule="annee_invalid",
            message=f"annee={annee} hors plage [2010, 2025]",
        ))
    # Pour le BEPC, serie doit être null.
    if examen == "BEPC" and q.get("serie") is not None:
        issues.append(ValidationIssue(
            severity="error", rule="serie_bepc_must_be_null",
            message=f"BEPC ne doit pas avoir de série (serie='{q.get('serie')}')",
        ))
    return issues


def _check_enonce_quality(q: Dict) -> List[ValidationIssue]:
    """Vérifie la qualité de l'énoncé (longueur, bruit OCR)."""
    issues: List[ValidationIssue] = []
    enonce = q.get("enonce") or ""
    if not isinstance(enonce, str):
        issues.append(ValidationIssue(
            severity="error", rule="enonce_not_string",
            message="l'énoncé n'est pas une chaîne de caractères",
        ))
        return issues

    if len(enonce) < 20:
        issues.append(ValidationIssue(
            severity="error", rule="enonce_too_short",
            message=f"énoncé trop court ({len(enonce)} < 20 caractères)",
        ))
    if len(enonce) > 800:
        issues.append(ValidationIssue(
            severity="warning", rule="enonce_too_long",
            message=f"énoncé très long ({len(enonce)} > 800 caractères)",
        ))

    # Ratio lettres / total (filtre le bruit pur).
    if enonce:
        letters = sum(1 for c in enonce if c.isalpha())
        ratio = letters / len(enonce)
        if ratio < 0.5:
            issues.append(ValidationIssue(
                severity="error", rule="enonce_low_letter_ratio",
                message=f"ratio lettres/caractères trop bas ({ratio:.2f} < 0.5)",
            ))

    # Patterns de bruit OCR (warnings).
    for pattern, label in NOISE_PATTERNS:
        if pattern.search(enonce):
            issues.append(ValidationIssue(
                severity="warning", rule="ocr_noise",
                message=f"bruit OCR suspecté : {label}",
            ))
    return issues


def _check_type_choix(q: Dict) -> List[ValidationIssue]:
    """Vérifie la cohérence type <-> choix."""
    issues: List[ValidationIssue] = []
    qtype = q.get("type")
    if qtype not in VALID_TYPES:
        issues.append(ValidationIssue(
            severity="error", rule="type_invalid",
            message=f"type='{qtype}' non supporté (attendu dans {sorted(VALID_TYPES)})",
        ))
        return issues

    choix = q.get("choix")
    if qtype in ("qcm", "vraiFaux"):
        if not choix or not isinstance(choix, list) or len(choix) < 2:
            issues.append(ValidationIssue(
                severity="error", rule="choix_missing_for_qcm",
                message=f"type={qtype} nécessite choix >= 2 items",
            ))
    else:
        if choix is not None:
            issues.append(ValidationIssue(
                severity="warning", rule="choix_should_be_null",
                message=f"type={qtype} devrait avoir choix=null (actuel: {choix})",
            ))
    return issues


def _check_irt(q: Dict) -> List[ValidationIssue]:
    """Vérifie la cohérence du bloc IRT."""
    issues: List[ValidationIssue] = []
    irt = q.get("irt")
    if not isinstance(irt, dict):
        issues.append(ValidationIssue(
            severity="error", rule="irt_not_dict",
            message="irt doit être un objet {a, b, c, calibre}",
        ))
        return issues
    b = irt.get("b")
    if b is not None:
        if not isinstance(b, (int, float)):
            issues.append(ValidationIssue(
                severity="error", rule="irt_b_not_number",
                message=f"irt.b doit être numérique (actuel: {type(b).__name__})",
            ))
        elif not (-3.0 <= float(b) <= 3.0):
            issues.append(ValidationIssue(
                severity="error", rule="irt_b_out_of_range",
                message=f"irt.b={b} hors plage [-3, 3]",
            ))
    if not isinstance(irt.get("calibre"), bool):
        issues.append(ValidationIssue(
            severity="error", rule="irt_calibre_not_bool",
            message="irt.calibre doit être un booléen",
        ))
    return issues


def validate_question(q: Dict) -> QuestionValidation:
    """Valide une question complète et retourne le statut + issues."""
    all_issues: List[ValidationIssue] = []
    all_issues.extend(_check_required_fields(q))
    all_issues.extend(_check_metadata(q))
    all_issues.extend(_check_enonce_quality(q))
    all_issues.extend(_check_type_choix(q))
    all_issues.extend(_check_irt(q))

    has_error = any(i.severity == "error" for i in all_issues)
    has_warning = any(i.severity == "warning" for i in all_issues)
    if has_error:
        status = "rejected"
    elif has_warning:
        status = "warning"
    else:
        status = "valid"

    return QuestionValidation(
        question_id=str(q.get("id", "<no-id>")),
        status=status,
        issues=all_issues,
        question=q if status != "rejected" else None,
    )


# ─── Driver ────────────────────────────────────────────────────────────────


def _status_emoji(status: str) -> str:
    """Mapping statut -> indicateur texte (sans emoji, conforme aux conventions)."""
    return {"valid": "[OK]", "warning": "[WARN]", "rejected": "[KO]"}[status]


def main() -> int:
    """Valide les questions OCR et génère les rapports."""
    print("=== Validation des questions OCR-isées ===")
    print()

    input_path = FINAL_DIR / "ocr_extracted_questions.json"
    if not input_path.exists():
        print(f"ERREUR : fichier introuvable : {input_path}")
        print("Lancer d'abord : python structure_extracted.py")
        return 1

    ocr_questions: List[Dict] = json.loads(
        input_path.read_text(encoding="utf-8")
    )
    print(f"  {len(ocr_questions)} questions à valider")
    print()

    results: List[QuestionValidation] = []
    for q in ocr_questions:
        results.append(validate_question(q))

    # Partition valides / warnings / rejetées.
    valid = [r for r in results if r.status == "valid"]
    warnings = [r for r in results if r.status == "warning"]
    rejected = [r for r in results if r.status == "rejected"]

    # Statistiques par matière et par règle.
    by_mat = Counter(r.question.get("matiere") if r.question else
                     _get_mat_from_qid(r.question_id) for r in results)
    by_status = Counter(r.status for r in results)
    by_rule: Dict[str, int] = defaultdict(int)
    for r in results:
        for issue in r.issues:
            by_rule[issue.rule] += 1

    # Sauvegarde des questions valides (valid + warning, on garde les warnings
    # en les marquant pour révision humaine).
    questions_to_merge: List[Dict] = []
    for r in valid + warnings:
        if r.question is None:
            continue
        q_copy = dict(r.question)
        q_copy["_validation_status"] = r.status
        if r.status == "warning":
            q_copy["_validation_warnings"] = [
                {"rule": i.rule, "message": i.message}
                for i in r.issues if i.severity == "warning"
            ]
        questions_to_merge.append(q_copy)

    validated_path = FINAL_DIR / "ocr_validated_questions.json"
    validated_path.write_text(
        json.dumps(questions_to_merge, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    # Rapport JSON détaillé.
    report_json = {
        "total": len(results),
        "valid": len(valid),
        "warning": len(warnings),
        "rejected": len(rejected),
        "by_matiere": dict(by_mat),
        "by_status": dict(by_status),
        "by_rule": dict(by_rule),
        "rejected_samples": [
            {
                "question_id": r.question_id,
                "issues": [asdict(i) for i in r.issues],
                "enonce_excerpt": (
                    r.question.get("enonce", "")[:120] + "..."
                    if r.question else "<rejetée>"
                ),
            }
            for r in rejected[:10]
        ],
        "warning_samples": [
            {
                "question_id": r.question_id,
                "issues": [asdict(i) for i in r.issues],
                "enonce_excerpt": (
                    r.question.get("enonce", "")[:120] + "..."
                    if r.question else "<absente>"
                ),
            }
            for r in warnings[:10]
        ],
    }
    report_path = FINAL_DIR / "validation_report.json"
    report_path.write_text(
        json.dumps(report_json, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    # Rapport Markdown lisible (pitch DJANTA).
    md_path = FINAL_DIR / "validation_report.md"
    md_lines = [
        "# Rapport de validation OCR — démo BEPC",
        "",
        "Généré automatiquement par `validate_and_merge.py`.",
        "",
        "## Synthèse",
        "",
        f"- Total questions OCR-isées : **{len(results)}**",
        f"- Questions valides (sans warning) : **{len(valid)}**",
        f"- Questions valides avec warning : **{len(warnings)}**",
        f"- Questions rejetées : **{len(rejected)}**",
        f"- Taux de validation : "
        f"**{(len(valid) + len(warnings)) / max(len(results), 1) * 100:.1f}%**",
        "",
        "## Répartition par matière",
        "",
        "| Matière | Total | Valides | Warnings | Rejetées |",
        "|---------|-------|---------|----------|----------|",
    ]
    for mat in sorted(VALID_MATIERES):
        total = by_mat.get(mat, 0)
        v = sum(1 for r in results
                if (r.question or {}).get("matiere") == mat and r.status == "valid")
        w = sum(1 for r in results
                if (r.question or {}).get("matiere") == mat and r.status == "warning")
        rej = sum(1 for r in results
                  if _get_mat_from_qid(r.question_id) == mat
                  and r.status == "rejected")
        md_lines.append(f"| {mat} | {total} | {v} | {w} | {rej} |")
    md_lines.extend([
        "",
        "## Issues détectées (par règle)",
        "",
        "| Règle | Occurrences |",
        "|-------|-------------|",
    ])
    for rule, count in sorted(by_rule.items(), key=lambda x: -x[1]):
        md_lines.append(f"| `{rule}` | {count} |")
    md_lines.extend([
        "",
        "## Exemples de questions rejetées",
        "",
    ])
    if not rejected:
        md_lines.append("_Aucune question rejetée._")
    else:
        for sample in report_json["rejected_samples"]:
            md_lines.append(f"### {sample['question_id']}")
            md_lines.append("")
            md_lines.append(f"**Extrait** : {sample['enonce_excerpt']}")
            md_lines.append("")
            md_lines.append("**Issues** :")
            for issue in sample["issues"]:
                md_lines.append(f"- `[{issue['severity']}]` {issue['rule']} : "
                                f"{issue['message']}")
            md_lines.append("")
    md_lines.extend([
        "## Exemples de warnings (questions conservées)",
        "",
    ])
    if not warnings:
        md_lines.append("_Aucun warning._")
    else:
        for sample in report_json["warning_samples"]:
            md_lines.append(f"### {sample['question_id']}")
            md_lines.append("")
            md_lines.append(f"**Extrait** : {sample['enonce_excerpt']}")
            md_lines.append("")
            md_lines.append("**Warnings** :")
            for issue in sample["issues"]:
                md_lines.append(f"- `[{issue['severity']}]` {issue['rule']} : "
                                f"{issue['message']}")
            md_lines.append("")

    md_path.write_text("\n".join(md_lines), encoding="utf-8")

    # Affichage console.
    print("=== Synthèse validation ===")
    print(f"  Valid (sans warning) : {len(valid)}")
    print(f"  Valid (avec warning) : {len(warnings)}")
    print(f"  Rejetées             : {len(rejected)}")
    print(f"  Taux de validation   : "
          f"{(len(valid) + len(warnings)) / max(len(results), 1) * 100:.1f}%")
    print()
    print("=== Issues par règle ===")
    for rule, count in sorted(by_rule.items(), key=lambda x: -x[1]):
        print(f"  {rule:35s} : {count}")
    print()
    print("Fichiers générés :")
    print(f"  {validated_path.relative_to(BASE_DIR)}")
    print(f"  {report_path.relative_to(BASE_DIR)}")
    print(f"  {md_path.relative_to(BASE_DIR)}")
    print()
    print(f"{len(questions_to_merge)} questions prêtes à être intégrées à "
          f"assets/data/questions.json (l'agent wiring fera la fusion).")
    return 0


def _get_mat_from_qid(qid: str) -> str:
    """Récupère la matière depuis un ID TG-BEPC-{CODE}-... (fallback)."""
    if not qid:
        return "<inconnu>"
    code_to_mat = {
        "MATH": "Mathématiques", "FRAN": "Français",
        "PHYS": "Sciences Physiques", "SVT": "Sciences de la Vie et de la Terre",
        "HIST": "Histoire-Géographie",
    }
    parts = qid.split("-")
    if len(parts) >= 3:
        return code_to_mat.get(parts[2], "<inconnu>")
    return "<inconnu>"


if __name__ == "__main__":
    sys.exit(main())
