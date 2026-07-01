"""scripts/import_questions.py — Import batch de questions depuis un JSON.

Usage :
    python scripts/import_questions.py <fichier.json> \\
        --api-url http://localhost:8000 \\
        --token <JWT_ADMIN> \\
        [--overwrite]

Le fichier JSON doit contenir un tableau d'objets respectant le schema
QuestionCreate (voir backend/models/admin_schemas.py).

Dependances :
    pip install requests

Exemple de fichier d'entree :
    [
      {
        "id": "TG-BEPC-MATHS-2024-Q01",
        "enonce": "Resolver 2x + 5 = 11",
        "reponse": "x = 3",
        "explication": "2x = 6, donc x = 3.",
        "matiere": "Mathematiques",
        "chapitre": "Equations du premier degre",
        "competence_id": "TG-MATHS-EQ1D-001",
        "examen": "BEPC",
        "serie": null,
        "annee": 2024,
        "type": "calcul",
        "choix": null,
        "points": 3
      }
    ]
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    sys.stderr.write(
        "[import_questions] Le module 'requests' est requis.\n"
        "Installez-le avec : pip install requests\n"
    )
    sys.exit(2)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Importe un fichier JSON de questions vers l'API admin."
    )
    parser.add_argument(
        "file",
        help="Chemin vers le fichier JSON contenant la liste des questions",
    )
    parser.add_argument(
        "--api-url",
        default="http://localhost:8000",
        help="URL de base de l'API (defaut: http://localhost:8000)",
    )
    parser.add_argument(
        "--token",
        required=True,
        help="JWT d'un compte admin (obtenu via POST /auth/login)",
    )
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Ecraser les questions existantes de meme ID",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=60,
        help="Timeout HTTP en secondes (defaut: 60)",
    )
    args = parser.parse_args()

    # ─── Lecture du fichier ──────────────────────────────────────
    path = Path(args.file)
    if not path.exists():
        sys.stderr.write(f"[import_questions] Fichier introuvable: {path}\n")
        return 2

    try:
        with path.open("r", encoding="utf-8") as f:
            questions = json.load(f)
    except json.JSONDecodeError as exc:
        sys.stderr.write(f"[import_questions] JSON invalide: {exc}\n")
        return 2

    if not isinstance(questions, list):
        sys.stderr.write(
            "[import_questions] Le fichier doit contenir un tableau JSON.\n"
        )
        return 2

    print(
        f"[import_questions] {len(questions)} question(s) a importer "
        f"depuis {path}"
    )

    # ─── Requete POST /admin/questions/batch-import ──────────────
    url = f"{args.api_url.rstrip('/')}/admin/questions/batch-import"
    headers = {
        "Authorization": f"Bearer {args.token}",
        "Content-Type": "application/json",
    }
    payload = {
        "questions": questions,
        "overwrite_existing": args.overwrite,
    }

    try:
        response = requests.post(
            url, headers=headers, json=payload, timeout=args.timeout
        )
    except requests.RequestException as exc:
        sys.stderr.write(f"[import_questions] Erreur reseau: {exc}\n")
        return 3

    if response.status_code == 200:
        data = response.json()
        print("[import_questions] Import reussi :")
        print(f"  Creees   : {data.get('created', 0)}")
        print(f"  Modifiees: {data.get('updated', 0)}")
        print(f"  Ignorees : {data.get('skipped', 0)}")
        errors = data.get("errors", [])
        if errors:
            print(f"  Erreurs  : {len(errors)}")
            for err in errors[:10]:  # on affiche les 10 premieres
                print(f"    - {err.get('question_id') or err.get('id')}: "
                      f"{err.get('error')}")
            if len(errors) > 10:
                print(f"    ... et {len(errors) - 10} autre(s) erreur(s)")
        return 0
    elif response.status_code == 401:
        sys.stderr.write(
            "[import_questions] 401 Unauthorized — token invalide ou expire.\n"
        )
        return 1
    elif response.status_code == 403:
        sys.stderr.write(
            "[import_questions] 403 Forbidden — le compte n'est pas admin.\n"
        )
        return 1
    else:
        sys.stderr.write(
            f"[import_questions] Erreur HTTP {response.status_code}: "
            f"{response.text}\n"
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
