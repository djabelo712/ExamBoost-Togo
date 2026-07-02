"""scripts/export_questions.py — Export des questions vers JSON ou CSV.

Usage :
    python scripts/export_questions.py --output questions.json \\
        --api-url http://localhost:8000 \\
        --token <JWT_ADMIN> \\
        [--format json|csv] \\
        [--matiere Mathematiques] [--examen BEPC] [--serie C] [--annee 2024]

Recupere les questions filtrees via POST /admin/questions/batch-export
et ecrit le contenu dans le fichier specifie.

Dependances :
    pip install requests
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    sys.stderr.write(
        "[export_questions] Le module 'requests' est requis.\n"
        "Installez-le avec : pip install requests\n"
    )
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Exporte les questions depuis l'API admin vers un fichier."
    )
    parser.add_argument(
        "--output",
        "-o",
        required=True,
        help="Chemin du fichier de sortie (.json ou .csv)",
    )
    parser.add_argument(
        "--api-url",
        default="http://localhost:8000",
        help="URL de base de l'API (defaut: http://localhost:8000)",
    )
    parser.add_argument(
        "--token",
        required=True,
        help="JWT d'un compte admin",
    )
    parser.add_argument(
        "--format",
        choices=["json", "csv"],
        default=None,
        help="Format de sortie (defaut: deduit de l'extension du fichier)",
    )
    parser.add_argument("--matiere", default=None, help="Filtre par matiere")
    parser.add_argument("--examen", default=None, help="Filtre par examen")
    parser.add_argument("--serie", default=None, help="Filtre par serie")
    parser.add_argument("--annee", type=int, default=None, help="Filtre par annee")
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="Timeout HTTP en secondes (defaut: 60)",
    )
    args = parser.parse_args()

    # ─── Deduction du format ─────────────────────────────────────
    output_path = Path(args.output)
    fmt = args.format
    if fmt is None:
        ext = output_path.suffix.lower().lstrip(".")
        if ext in ("json", "csv"):
            fmt = ext
        else:
            fmt = "json"

    # ─── Construction des filtres ────────────────────────────────
    filters: dict = {}
    if args.matiere:
        filters["matiere"] = args.matiere
    if args.examen:
        filters["examen"] = args.examen
    if args.serie:
        filters["serie"] = args.serie
    if args.annee is not None:
        filters["annee"] = args.annee

    # ─── Requete POST /admin/questions/batch-export ──────────────
    url = f"{args.api_url.rstrip('/')}/admin/questions/batch-export"
    headers = {
        "Authorization": f"Bearer {args.token}",
        "Content-Type": "application/json",
    }
    payload = {"format": fmt, "filters": filters or None}

    print(
        f"[export_questions] Export format={fmt} filters={filters or 'aucun'}"
    )

    try:
        response = requests.post(
            url, headers=headers, json=payload, timeout=args.timeout
        )
    except requests.RequestException as exc:
        sys.stderr.write(f"[export_questions] Erreur reseau: {exc}\n")
        return 3

    if response.status_code != 200:
        sys.stderr.write(
            f"[export_questions] Erreur HTTP {response.status_code}: "
            f"{response.text}\n"
        )
        if response.status_code in (401, 403):
            sys.stderr.write(
                "Verifiez que le token est valide et que le compte est admin.\n"
            )
        return 1

    data = response.json()
    content = data.get("content", "")
    count = data.get("count", 0)

    # ─── Ecriture du fichier ─────────────────────────────────────
    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with output_path.open("w", encoding="utf-8") as f:
            f.write(content)
    except OSError as exc:
        sys.stderr.write(
            f"[export_questions] Impossible d'ecrire {output_path}: {exc}\n"
        )
        return 4

    print(f"[export_questions] {count} question(s) exportee(s) vers {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
