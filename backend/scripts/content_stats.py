"""scripts/content_stats.py — Affiche les statistiques contenu.

Usage :
    python scripts/content_stats.py --api-url http://localhost:8000 \\
        --token <JWT_ADMIN>

Interroge GET /admin/stats et affiche un resume lisible dans le
terminal : total, repartition par matiere / examen / serie / annee /
type, taux de calibration IRT, questions sans explication, et liste
des doublons potentiels.

Dependances :
    pip install requests
"""

from __future__ import annotations

import argparse
import sys

try:
    import requests
except ImportError:
    sys.stderr.write(
        "[content_stats] Le module 'requests' est requis.\n"
        "Installez-le avec : pip install requests\n"
    )
    sys.exit(2)


# ─── Helpers d'affichage ─────────────────────────────────────────────
def _print_dict(title: str, data: dict, indent: str = "  ") -> None:
    """Affiche un dictionnaire {cle: compte} trie par cle."""
    print(f"\n{title} :")
    if not data:
        print(f"{indent}(vide)")
        return
    width = max(len(str(k)) for k in data.keys()) + 2
    for key in sorted(data.keys(), key=lambda k: str(k)):
        print(f"{indent}{str(key):<{width}}: {data[key]}")


def _print_section(title: str) -> None:
    """Affiche un separateur de section."""
    print("\n" + "=" * 60)
    print(title)
    print("=" * 60)


# ─── Main ────────────────────────────────────────────────────────────
def main() -> int:
    parser = argparse.ArgumentParser(
        description="Affiche les statistiques contenu ExamBoost."
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
        "--timeout",
        type=int,
        default=30,
        help="Timeout HTTP en secondes (defaut: 30)",
    )
    args = parser.parse_args()

    # ─── Requete GET /admin/stats ────────────────────────────────
    url = f"{args.api_url.rstrip('/')}/admin/stats"
    headers = {"Authorization": f"Bearer {args.token}"}

    try:
        response = requests.get(url, headers=headers, timeout=args.timeout)
    except requests.RequestException as exc:
        sys.stderr.write(f"[content_stats] Erreur reseau: {exc}\n")
        return 3

    if response.status_code != 200:
        sys.stderr.write(
            f"[content_stats] Erreur HTTP {response.status_code}: "
            f"{response.text}\n"
        )
        if response.status_code in (401, 403):
            sys.stderr.write(
                "Verifiez que le token est valide et que le compte est admin.\n"
            )
        return 1

    stats = response.json()

    # ─── Affichage ───────────────────────────────────────────────
    _print_section("STATS CONTENU EXAMBOOST TOGO")

    print(f"\nTotal questions              : {stats.get('total_questions', 0)}")
    print(
        f"Questions calibrees IRT      : "
        f"{stats.get('irt_calibrated_count', 0)} "
        f"({stats.get('irt_calibrated_percent', 0.0):.1f}%)"
    )
    print(
        f"Questions sans explication   : "
        f"{stats.get('questions_without_explanation', 0)}"
    )
    print(f"Derniere mise a jour         : {stats.get('last_updated', 'N/A')}")

    _print_dict("Repartition par matiere", stats.get("by_matiere", {}))
    _print_dict("Repartition par examen", stats.get("by_examen", {}))
    _print_dict("Repartition par serie", stats.get("by_serie", {}))
    _print_dict("Repartition par annee", stats.get("by_annee", {}))
    _print_dict("Repartition par type", stats.get("by_type", {}))

    # ─── Doublons potentiels ─────────────────────────────────────
    duplicates = stats.get("duplicate_warnings", [])
    print("\n" + "-" * 60)
    if duplicates:
        print(f"ATTENTION : {len(duplicates)} groupe(s) de doublons potentiels")
        for i, dup in enumerate(duplicates[:10], 1):
            ids = dup.get("ids", [])
            ids_str = ", ".join(str(_id) for _id in ids[:5])
            if len(ids) > 5:
                ids_str += f", ... (+{len(ids) - 5})"
            print(f"  {i}. [{dup.get('count', '?')} questions] prefixe=\"{dup.get('prefix', '')[:60]}\"")
            print(f"     IDs: {ids_str}")
        if len(duplicates) > 10:
            print(f"  ... et {len(duplicates) - 10} autre(s) groupe(s) non affiche(s)")
    else:
        print("Aucun doublon potentiel detecte.")

    print("\n" + "=" * 60)
    return 0


if __name__ == "__main__":
    sys.exit(main())
