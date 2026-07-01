"""export_calibrated_questions.py — Export questions.json avec params IRT calibres.

Charge :
1. ``assets/data/questions.json`` (banque de questions originale)
2. ``output/calibrated_params.json`` (sortie de calibrate_irt.py)

Pour chaque question presente dans les deux fichiers :
- Met a jour ``irt.a``, ``irt.b``, ``irt.c`` avec les valeurs calibrees
- Passe ``irt.calibre`` a ``true``

Sauvegarde le resultat dans ``output/updated_questions.json``.
L'agent wiring (ou un administrateur) pourra ensuite remplacer
``assets/data/questions.json`` par ce fichier pour activer les parametres
calibres dans l'app Flutter.

Usage
-----
    python export_calibrated_questions.py
    python export_calibrated_questions.py \\
        --questions ../../assets/data/questions.json \\
        --params output/calibrated_params.json \\
        --output output/updated_questions.json
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> Any:
    """Charge un fichier JSON avec gestion d'erreurs."""
    if not path.exists():
        raise FileNotFoundError(f"Fichier introuvable : {path}")
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def _save_json(data: Any, path: Path) -> None:
    """Sauvegarde un objet JSON en UTF-8 avec indentation de 2 espaces."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")  # newline final pour git propre


def export_updated_questions(
    questions_file: str | Path = "assets/data/questions.json",
    params_file: str | Path = "output/calibrated_params.json",
    output_file: str | Path = "output/updated_questions.json",
    backup: bool = True,
    dry_run: bool = False,
    verbose: bool = True,
) -> dict[str, int]:
    """Genere un nouveau questions.json avec les parametres IRT calibres.

    Parameters
    ----------
    questions_file:
        Chemin vers questions.json original.
    params_file:
        Chemin vers calibrated_params.json (sortie de calibrate_irt.py).
    output_file:
        Chemin de sortie (updated_questions.json).
    backup:
        Si True et qu'un fichier de sortie existe deja, en fait une copie
        horodatee avant d'ecrire.
    dry_run:
        Si True, n'ecrit rien sur disque (juste rapporte les stats).
    verbose:
        Affiche l'avancement.

    Returns
    -------
    dict
        Stats : {n_total, n_calibrated, n_unchanged, n_missing_in_params}
    """
    questions_file = Path(questions_file)
    params_file = Path(params_file)
    output_file = Path(output_file)

    questions = _load_json(questions_file)
    params = _load_json(params_file)

    # Mapping question_id -> parametres calibres
    item_params_list = params.get("item_params", [])
    params_by_id: dict[str, dict[str, Any]] = {
        p["question_id"]: p for p in item_params_list
    }

    if verbose:
        print(
            f"[export] {len(questions)} questions originales | "
            f"{len(params_by_id)} questions calibrees disponibles"
        )

    # Backup optionnel
    if backup and output_file.exists() and not dry_run:
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        backup_path = output_file.with_suffix(f".{timestamp}.bak.json")
        shutil.copy2(output_file, backup_path)
        if verbose:
            print(f"[export] Backup cree : {backup_path}")

    n_total = len(questions)
    n_calibrated = 0
    n_unchanged = 0
    n_missing = 0

    for q in questions:
        qid = q.get("id")
        if qid is None:
            n_missing += 1
            continue

        if qid in params_by_id:
            p = params_by_id[qid]
            # Initialise le dict irt si absent
            if "irt" not in q or not isinstance(q["irt"], dict):
                q["irt"] = {}
            q["irt"]["a"] = round(float(p["a"]), 3)
            q["irt"]["b"] = round(float(p["b"]), 3)
            q["irt"]["c"] = round(float(p["c"]), 3)
            q["irt"]["calibre"] = True
            # Champ complementaire pour audit
            q["irt"]["methode_calibration"] = params.get("metadata", {}).get(
                "method", "unknown"
            )
            q["irt"]["n_reponses_calibration"] = int(p.get("n_responses", 0))
            n_calibrated += 1
        else:
            # Question non calibree : on garde les valeurs existantes
            # et on s'assure que calibre = False
            if "irt" not in q or not isinstance(q["irt"], dict):
                q["irt"] = {}
            q["irt"]["calibre"] = False
            n_unchanged += 1

    if not dry_run:
        _save_json(questions, output_file)

    stats = {
        "n_total": n_total,
        "n_calibrated": n_calibrated,
        "n_unchanged": n_unchanged,
        "n_missing_in_params": n_missing,
    }

    if verbose:
        print()
        print(f"[OK] Export termine.")
        print(f"     Total questions      : {n_total}")
        print(f"     Calibrees (MAJ)      : {n_calibrated}")
        print(f"     Non calibrees ( unchanged ) : {n_unchanged}")
        print(f"     Sans ID (ignores)    : {n_missing}")
        if not dry_run:
            print(f"     Sauvegarde           : {output_file}")
        else:
            print(f"     [DRY RUN] Rien ecrit sur disque.")

    return stats


# ─── CLI ───────────────────────────────────────────────────────────────────
def main() -> int:
    """Point d'entree CLI."""
    parser = argparse.ArgumentParser(
        description=(
            "Exporte questions.json avec les parametres IRT calibres "
            "(irt.calibre = true)."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--questions",
        type=str,
        default="../../assets/data/questions.json",
        help="Chemin vers questions.json original.",
    )
    parser.add_argument(
        "--params",
        type=str,
        default="output/calibrated_params.json",
        help="Chemin vers calibrated_params.json (sortie de calibrate_irt.py).",
    )
    parser.add_argument(
        "--output",
        type=str,
        default="output/updated_questions.json",
        help="Fichier JSON de sortie.",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Ne pas creer de backup horodate du fichier de sortie existant.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Mode simulation : n'ecrit rien sur disque.",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="Mode silencieux.",
    )
    args = parser.parse_args()

    # Resolution du chemin questions.json
    questions_path = Path(args.questions)
    if not questions_path.is_absolute():
        script_dir = Path(__file__).resolve().parent
        candidates = [
            questions_path,
            script_dir / args.questions,
            script_dir.parent.parent.parent / args.questions.lstrip("../"),
        ]
        for c in candidates:
            if c.exists():
                questions_path = c
                break

    try:
        export_updated_questions(
            questions_file=questions_path,
            params_file=args.params,
            output_file=args.output,
            backup=not args.no_backup,
            dry_run=args.dry_run,
            verbose=not args.quiet,
        )
    except (FileNotFoundError, ValueError) as e:
        print(f"[ERREUR] {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
