"""generate_personas — Genere le document ``personas.md`` par cluster.

Pour chaque cluster identifie par ``cluster_students.py``, produit une
description pedagogique au format markdown :

- **Nom du persona** (auto-attribue selon le profil moyen du cluster :
  Scientifique / Litteraire / Polyvalent / En difficulte / Atypique)
- **Profil moyen** : P(L) moyen par matiere, en pourcentage
- **Caracteristiques** : forces, faiblesses, type d'eleve correspondant
- **Recommandations pedagogiques** : mix de revision cible, objectifs
- **Messages de motivation** : phrases pre-remplies pour l'app

Le document final inclut egalement une section **Utilisation en production**
qui montre comment brancher le modele sur le backend FastAPI et l'app Flutter.

Usage
-----
    python generate_personas.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Final

import joblib
import numpy as np

# ─── Constantes ────────────────────────────────────────────────────────
OUTPUT_DIR: Final[Path] = Path(__file__).resolve().parent / "output"
MODEL_PATH: Final[Path] = OUTPUT_DIR / "cluster_model.joblib"
STATS_PATH: Final[Path] = OUTPUT_DIR / "cluster_stats.json"
PERSONAS_PATH: Final[Path] = OUTPUT_DIR / "personas.md"

# Ordre canonique des matieres (miroir des autres modules)
FEATURES: Final[list[str]] = [
    "pL_maths", "pL_francais", "pL_sciences",
    "pL_svt", "pL_histoire", "pL_anglais",
]
MATIERE_LABELS: Final[dict[str, str]] = {
    "pL_maths": "Mathematiques",
    "pL_francais": "Francais",
    "pL_sciences": "Sciences Physiques",
    "pL_svt": "SVT",
    "pL_histoire": "Histoire-Geographie",
    "pL_anglais": "Anglais",
}
# Indices des sous-groupes (pour la classification)
SCIENCES_IDX: Final[list[int]] = [0, 2, 3]   # maths, sciences, svt
LETTRES_IDX: Final[list[int]] = [1, 4, 5]    # francais, histoire, anglais

# Seuils de classification
THRESHOLDS: Final[dict[str, float]] = {
    "difficulte": 0.40,   # mean_all < ce seuil => en difficulte
    "polyvalent": 0.55,   # mean_all > ce seuil ET faible ecart => polyvalent
    "polyvalent_std": 0.10,
    "specialiste": 0.65,  # un groupe > ce seuil => specialist
    "specialiste_gap": 0.15,  # ecart mini entre les 2 groupes
    "fort": 0.60,   # matiere "forte"
    "faible": 0.40,  # matiere "faible"
}


# ─── Classification automatique d'un cluster ────────────────────────────
def classify_cluster(mean_pL: dict[str, float]) -> tuple[str, str]:
    """Determine le type de persona d'un cluster a partir de son profil moyen.

    Regles (par ordre de priorite) :
        1. mean_all < 0.40                          -> En_difficulte
        2. mean_all > 0.55 ET std < 0.10            -> Polyvalent
        3. mean_sciences > 0.65 ET gap > 0.15       -> Scientifique
        4. mean_lettres > 0.65 ET gap > 0.15        -> Litteraire
        5. sinon                                     -> Atypique

    Parameters
    ----------
    mean_pL : dict[str, float]
        Dictionnaire ``{feature: mean_P(L)}`` (cles = FEATURES).

    Returns
    -------
    tuple[str, str]
        ``(persona_code, persona_label_fr)`` ou ``persona_code`` est l'un de
        ``{"En_difficulte", "Polyvalent", "Scientifique", "Litteraire",
        "Atypique"}``.
    """
    values = np.array([mean_pL[f] for f in FEATURES])
    mean_all = float(values.mean())
    std_all = float(values.std())

    if mean_all < THRESHOLDS["difficulte"]:
        return "En_difficulte", "L'Eleve en Difficulte"

    if mean_all > THRESHOLDS["polyvalent"] and std_all < THRESHOLDS["polyvalent_std"]:
        return "Polyvalent", "Le Polyvalent"

    mean_sci = float(values[SCIENCES_IDX].mean())
    mean_let = float(values[LETTRES_IDX].mean())

    if mean_sci > THRESHOLDS["specialiste"] and (mean_sci - mean_let) > THRESHOLDS["specialiste_gap"]:
        return "Scientifique", "Le Scientifique"

    if mean_let > THRESHOLDS["specialiste"] and (mean_let - mean_sci) > THRESHOLDS["specialiste_gap"]:
        return "Litteraire", "Le Litteraire"

    return "Atypique", "L'Atypique"


# ─── Generation du contenu pedagogique par persona ──────────────────────
def _strong_weak_subjects(mean_pL: dict[str, float]) -> tuple[list[str], list[str], list[str]]:
    """Retourne (matieres_fortes, matieres_moyennes, matieres_faibles).

    Seuils : fort > 0.60, faible < 0.40, moyen entre les deux.
    """
    strong: list[str] = []
    medium: list[str] = []
    weak: list[str] = []
    for f in FEATURES:
        v = mean_pL[f]
        if v >= THRESHOLDS["fort"]:
            strong.append(MATIERE_LABELS[f])
        elif v < THRESHOLDS["faible"]:
            weak.append(MATIERE_LABELS[f])
        else:
            medium.append(MATIERE_LABELS[f])
    return strong, medium, weak


def _characteristics(
    persona_code: str,
    mean_pL: dict[str, float],
) -> list[str]:
    """Genere les caracteristiques pedagogiques du persona.

    Parameters
    ----------
    persona_code : str
        Code du persona (Scientifique, Litteraire, etc.).
    mean_pL : dict[str, float]
        Profil moyen du cluster.

    Returns
    -------
    list[str]
        Liste de puces markdown.
    """
    strong, medium, weak = _strong_weak_subjects(mean_pL)
    values = np.array([mean_pL[f] for f in FEATURES])
    mean_all = float(values.mean())

    common: list[str] = []
    if strong:
        common.append(f"Points forts : {', '.join(strong)}")
    if medium:
        common.append(f"Niveau moyen : {', '.join(medium)}")
    if weak:
        common.append(f"Points faibles : {', '.join(weak)}")

    specifics: dict[str, list[str]] = {
        "Scientifique": [
            "Excellente maitrise des matieres scientifiques",
            "Legere faiblesse en lettres et langues",
            "Profil type : eleve de serie C ou D, en confiance en maths mais qui neglige parfois le francais (pourtant coef 2 au BEPC)",
        ],
        "Litteraire": [
            "Excellente maitrise des lettres et langues",
            "Difficulte relative en sciences exactes",
            "Profil type : eleve de serie A ou en voie litteraire, a l'aise en dissertation mais peu spontane en calcul",
        ],
        "Polyvalent": [
            "Profil equilibre sur les 6 matieres",
            "Bonne regularite, peu de lacunes marquees",
            "Profil type : eleve serieux et methodique, vise une mention au BEPC ou au BAC",
        ],
        "En_difficulte": [
            "Maitrise insuffisante sur la plupart des matieres (< 40%)",
            "Risque d'echec a l'examen sans soutien renforce",
            "Profil type : eleve demotive ou en rupture scolaire, a besoin d'un accompagnement individuel et de petits objectifs",
        ],
        "Atypique": [
            "Profil heterogene : 1-2 points forts atypiques et des lacunes ailleurs",
            "Ne correspond pas aux series classiques (C, D, A)",
            "Profil type : eleve passionne par un domaine precis mais en decrochage sur le reste du programme",
        ],
    }
    return common + specifics.get(persona_code, [])


def _recommendations(
    persona_code: str,
    mean_pL: dict[str, float],
) -> list[str]:
    """Genere 4 recommandations pedagogiques cibles par persona.

    Parameters
    ----------
    persona_code : str
        Code du persona.
    mean_pL : dict[str, float]
        Profil moyen du cluster.

    Returns
    -------
    list[str]
        Liste de 4 recommandations (puces markdown numerotees).
    """
    strong, _, weak = _strong_weak_subjects(mean_pL)
    strong_str = ", ".join(strong) if strong else "tes points forts"
    weak_str = ", ".join(weak) if weak else "tes matieres les plus faibles"

    if persona_code == "Scientifique":
        return [
            f"**Maintien scientifique** : continuer 2-3 questions/jour en sciences ({strong_str}) pour ne pas perdre le niveau",
            f"**Renforcement lettres** : prioriser {weak_str} — chapitres les plus faibles, 1 chapitre toutes les 2 semaines",
            "**Objectif** : viser 14/20 global (au lieu de 12 actuellement) en comblant le retard en lettres",
            "**Mix ideal sessions** : 60% lettres, 30% sciences, 10% anglais",
        ]
    if persona_code == "Litteraire":
        return [
            f"**Maintien lettres** : continuer 2-3 questions/jour en lettres et langues ({strong_str}) pour consolider l'avance",
            f"**Renforcement sciences** : prioriser {weak_str} — reprendre les fondamentaux (calculs, formules) avant les sujets d'examen",
            "**Objectif** : viser 13/20 global (au lieu de 11) en gagnant 2 points en sciences",
            "**Mix ideal sessions** : 60% sciences, 30% lettres, 10% anglais",
        ]
    if persona_code == "Polyvalent":
        return [
            "**Consolidation generale** : 1 question/jour par matiere pour entretenir le niveau equilibre sur les 6 matieres",
            f"**Affinement** : cibler les 1-2 matieres les plus basses ({weak_str or 'toutes equivalentes'}) pour viser une mention",
            "**Objectif** : viser 15/20+ (mention Assez Bien ou Bien) au BEPC / BAC",
            "**Mix ideal sessions** : 40% sciences, 40% lettres, 20% anglais — equilibre",
        ]
    if persona_code == "En_difficulte":
        return [
            "**Reprise des fondamentaux** : revoir les bases de chaque matiere (1 chapitre fondamental/semaine, pas de saut)",
            f"**Petits objectifs** : 5 questions/jour max, focalisees sur {weak_str or 'les matieres les plus faibles'}, pour restaurer la confiance avant la quantite",
            "**Objectif court terme** : atteindre 50% de maitrise sur 3 matieres cles (maths, francais, sciences) avant la simulation suivante",
            "**Mix ideal sessions** : 50% matieres prioritaires (maths + francais), 50% decouverte des autres matieres",
        ]
    # Atypique
    return [
        f"**Capitaliser les points forts** : entretenir {strong_str or 'tes 1-2 points forts'} avec 2-3 questions/jour pour conserver un avantage differentiel",
        f"**Combler les lacunes** : attaquer {weak_str or 'les matieres les plus faibles'} en priorite — 1 chapitre/semaine, petit rythme regulier",
        "**Objectif** : viser 12/20 global en elevant le plancher (pas en poussant le plafond)",
        "**Mix ideal sessions** : 70% matieres faibles, 30% points forts",
    ]


def _motivation_messages(persona_code: str) -> list[str]:
    """Genere 2 messages de motivation par persona."""
    messages: dict[str, list[str]] = {
        "Scientifique": [
            "Tu es fort en sciences, maintenant attaque le francais pour viser plus haut !",
            "Avec ton niveau en maths, le BAC C est a portee. Ne neglige pas le francais (coef 2).",
        ],
        "Litteraire": [
            "Ta plume est ton arme ! Maintenant un effort sur les sciences et tout degage.",
            "Avec ton niveau en francais, la dissertation est ton point fort. Pousse aussi les maths.",
        ],
        "Polyvalent": [
            "Profil equilibre — tu peux viser une mention. Maintiens le cap !",
            "Tu n'as pas de vraie faiblesse, c'est rare. Transforme-la en mention.",
        ],
        "En_difficulte": [
            "Chaque petite victoire compte. 5 questions aujourd'hui, demain on en fait 6.",
            "Tu progresses plus vite que tu ne le penses. Reste regulier, le declic viendra.",
        ],
        "Atypique": [
            "Ton profil original est une force ! Capitalise sur tes points forts.",
            "Personne n'a ton parcours. Convertis tes atypies en atouts a l'examen.",
        ],
    }
    return messages.get(persona_code, ["Continue tes efforts !", "Tu vas y arriver."])


# ─── Rendu markdown d'un cluster ────────────────────────────────────────
def _render_cluster_section(
    cluster_id: int,
    stats: dict[str, Any],
    persona_code: str,
    persona_label: str,
) -> str:
    """Genere la section markdown d'un cluster.

    Parameters
    ----------
    cluster_id : int
        Identifiant du cluster (0 a K-1).
    stats : dict
        Stats du cluster (size, pct, mean_pL, ...).
    persona_code : str
        Code du persona (Scientifique, etc.).
    persona_label : str
        Label francais affiche.

    Returns
    -------
    str
        Section markdown complete pour ce cluster.
    """
    size = stats["size"]
    pct = stats["pct"]
    mean_pL = stats["mean_pL"]

    # Tableau profil moyen
    lines_profil = [
        f"- {MATIERE_LABELS[f]} : {mean_pL[f] * 100:.0f}%" for f in FEATURES
    ]
    profil_md = "\n".join(lines_profil)

    # Caracteristiques
    characteristics = _characteristics(persona_code, mean_pL)
    characteristics_md = "\n".join(f"- {c}" for c in characteristics)

    # Recommandations (numerotees)
    recommendations = _recommendations(persona_code, mean_pL)
    recommendations_md = "\n".join(
        f"{i}. {r}" for i, r in enumerate(recommendations, start=1)
    )

    # Messages de motivation
    messages = _motivation_messages(persona_code)
    messages_md = "\n".join(f"- \"{m}\"" for m in messages)

    # Distribution des archetypes vrais (pour validation)
    archetypes = stats.get("archetype_distribution", {})
    if archetypes:
        # Top 3 archetypes les plus representes
        sorted_arch = sorted(archetypes.items(), key=lambda x: x[1], reverse=True)[:3]
        arch_md = ", ".join(f"{a} ({n})" for a, n in sorted_arch)
    else:
        arch_md = "N/A"

    return f"""## Cluster {cluster_id} : "{persona_label}" ({size} eleves, {pct:.1f}%)

### Profil moyen
{profil_md}

### Caracteristiques
{characteristics_md}

### Recommandations pedagogiques
{recommendations_md}

### Messages de motivation
{messages_md}

### Composition (archetypes vrais les plus representes)
{arch_md}

---"""


def _render_header(best_k: int, n_total: int, metrics: dict, model_data: dict) -> str:
    """Genere l'en-tete du document personas.md."""
    # Resume des metriques K-Means
    metrics_lines = []
    for k, m in metrics.items():
        marker = " (choisi)" if k == best_k else ""
        metrics_lines.append(
            f"- K={k} : silhouette={m['silhouette']:.3f}, "
            f"Davies-Bouldin={m['davies_bouldin']:.3f}{marker}"
        )
    metrics_md = "\n".join(metrics_lines)

    # Note sur le tiebreaker (si applicable)
    tiebreak_applied = model_data.get("tiebreak_applied", False)
    best_k_strict = model_data.get("best_k_strict", best_k)
    if tiebreak_applied:
        tiebreak_note = (
            f"\n> **Note** : K={best_k_strict} a la meilleure silhouette stricte, "
            f"mais K={best_k} (spec \"4-5 profils types\") a ete prefere car sa "
            f"silhouette est >= 85% du meilleur. Granularite pedagogique privilegiee."
        )
    else:
        tiebreak_note = ""

    return f"""# Personas Pedagogiques — ExamBoost Togo

Ce document decrit les {best_k} profils types d'eleves identifiees par
clustering K-Means sur {n_total} profils eleves (P(L) par matiere, modele BKT).
Utilisez ces personas pour personnaliser les recommandations de revision
dans l'app Flutter et le backend FastAPI.

## Synthese technique

- **Algorithme** : K-Means (sklearn) avec standardisation prealable
- **Features** : 6 P(L) par matiere (Maths, Francais, Sciences, SVT, Histoire, Anglais)
- **K optimal** : {best_k}
- **Selection de K testee** :
{metrics_md}{tiebreak_note}

## Methodologie

1. **Generation** de {n_total} profils synthetiques repartis en 5 archetypes
   (Scientifique, Litteraire, Polyvalent, En difficulte, Mixte atypique) —
   cf. `generate_synthetic_profiles.py`.
2. **Standardisation** des features (StandardScaler) pour neutraliser les
   differences d'echelle entre matieres.
3. **K-Means** avec K=3,4,5,6 — selection du K maximisant le **silhouette
   score** (compromis cohesion intra-cluster / separation inter-cluster),
   avec tiebreaker pedagogique preferant K=5 si la silhouette est dans les
   85% du meilleur.
4. **Classification automatique** de chaque cluster en persona pedagogique
   (Scientifique / Litteraire / Polyvalent / En difficulte / Atypique) basee
   sur le profil moyen P(L) par matiere.

> **Note** : les clusters issus de K-Means ne correspondent pas toujours
> 1:1 aux archetypes simules. Le persona attribue est calcule a partir du
> profil moyen reel du cluster, ce qui rend le document robuste au choix
> de K et a la qualite des donnees reelles.

---"""


def _render_footer(features: list[str]) -> str:
    """Genere le pied de document : section 'Utilisation en production'."""
    features_str = ", ".join(features)
    return f"""
## Utilisation en production

### Backend FastAPI — endpoint `/student/cluster`

Le modele serialise `cluster_model.joblib` contient tout le necessaire
(modele KMeans + StandardScaler + liste features) pour inferer le cluster
d'un eleve en production.

```python
# backend/services/student_clustering_service.py
import joblib
from pathlib import Path

MODEL_PATH = Path(__file__).parent / "models" / "cluster_model.joblib"
_model_data = joblib.load(MODEL_PATH)
_kmeans = _model_data["model"]
_scaler = _model_data["scaler"]
_features = _model_data["features"]  # [{features_str}]


def get_student_cluster(pL_by_matiere: dict[str, float]) -> int:
    \"\"\"Retourne l'ID de cluster (0 a K-1) pour un eleve donne.

    Parameters
    ----------
    pL_by_matiere : dict[str, float]
        Dictionnaire {{matiere: P(L)}} pour les 6 matieres (cles : pL_maths,
        pL_francais, pL_sciences, pL_svt, pL_histoire, pL_anglais).

    Returns
    -------
    int
        ID du cluster assigne.
    \"\"\"
    X = [[pL_by_matiere[f] for f in _features]]
    X_scaled = _scaler.transform(X)
    return int(_kmeans.predict(X_scaled)[0])
```

### Endpoint FastAPI

```python
# backend/routers/student.py
from fastapi import APIRouter, HTTPException
from backend.services.student_clustering_service import get_student_cluster

router = APIRouter(prefix="/student", tags=["student"])


@router.get("/cluster/{{user_id}}")
async def get_cluster(user_id: str):
    \"\"\"Retourne le cluster (persona) de l'eleve connecte.\"\"\"
    # 1. Recuperer le bktMaitrise de l'eleve (depuis la DB)
    user = await fetch_user(user_id)
    if not user:
        raise HTTPException(404, "User not found")

    # 2. Agreger P(L) par matiere (moyenne des competences de chaque matiere)
    pL_by_matiere = aggregate_pL_by_matiere(user.bktMaitrise)
    #    ex : {{'pL_maths': 0.78, 'pL_francais': 0.52, ...}}

    # 3. Inferer le cluster
    cluster_id = get_student_cluster(pL_by_matiere)

    return {{
        "user_id": user_id,
        "cluster": cluster_id,
        "persona": PERSONA_NAMES.get(cluster_id, "Inconnu"),
        "recommendations": PERSONA_RECOMMENDATIONS.get(cluster_id, []),
    }}
```

### Personnalisation in-app (Flutter)

Quand un eleve a un cluster identifie (via l'endpoint ci-dessus),
adapter dans le dashboard :

- **Messages de motivation** : piocher dans `personas.md` > Cluster X >
  Messages de motivation
- **Sessions ciblees** : prioriser les matieres faibles du persona
- **Recommandations de questions** : adapter la difficulte IRT au profil
  (ex : Scientifique en difficulte -> questions de difficulte moyenne en
  sciences pour restaurer la confiance)
- **Affichage du persona** dans le dashboard :
  `"Tu es profil Scientifique"` (gamification)

### Re-entrainement avec donnees reelles

Le modele actuel est entraine sur 2000 profils synthetiques. Pour passer
en production avec donnees reelles :

1. Recuperer les `bktMaitrise` des eleves actifs (>= 50 questions repondues)
2. Agreger P(L) par matiere (moyenne des competences de chaque matiere —
   cf. `competenceId` dans `lib/models/question.dart` qui encode la matiere)
3. Remplacer `output/profiles.csv` par le CSV reel (meme schema)
4. Relancer `python cluster_students.py && python analyze_clusters.py && python generate_personas.py`
5. Re-deployer `cluster_model.joblib` sur le backend

### Limites connues

1. **K-Means suppose des clusters spheriques** : les clusters de forme
   allongee ou concentrique ne seront pas bien captures. Pour les profils
   atypiques (mixte), considerer DBSCAN ou Gaussian Mixture Models.
2. **P(L) BKT par matiere** est une moyenne sur les competences — un eleve
   peut etre fort sur un chapitre et faible sur un autre dans la meme
   matiere. Le clustering opere a l'echelle matiere, pas competence.
3. **Pas de signal comportemental** : le clustering actuel n'utilise que
   P(L). Pour affiner, ajouter en features : nombre de sessions 7j, streak,
   temps moyen par question (cf. `ml_training/generate_synthetic_students.py`).
4. **Personas statiques** : les personas sont calcules une fois pour
   toutes. En production, re-entrainer mensuellement avec les nouvelles
   donnees pour detecter d'eventuels nouveaux profils.
"""


def generate_personas() -> str:
    """Genere le document personas.md complet.

    Returns
    -------
    str
        Contenu markdown complet du document personas.
    """
    # Chargement des artefacts
    if not STATS_PATH.exists() or not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"{STATS_PATH} ou {MODEL_PATH} manquant. Lancer cluster_students.py avant."
        )
    with STATS_PATH.open("r", encoding="utf-8") as f:
        cluster_stats: dict[str, Any] = json.load(f)
    model_data = joblib.load(MODEL_PATH)
    best_k = model_data["best_k"]
    metrics = model_data["metrics"]
    features = model_data["features"]

    # Total eleves
    n_total = sum(cluster_stats[str(c)]["size"] for c in range(best_k))

    # En-tete
    header = _render_header(
        best_k=best_k, n_total=n_total, metrics=metrics, model_data=model_data
    )

    # Sections par cluster (dans l'ordre 0 a K-1)
    sections: list[str] = []
    for c in range(best_k):
        stats = cluster_stats[str(c)]
        persona_code, persona_label = classify_cluster(stats["mean_pL"])
        sections.append(
            _render_cluster_section(
                cluster_id=c,
                stats=stats,
                persona_code=persona_code,
                persona_label=persona_label,
            )
        )

    # Pied de document
    footer = _render_footer(features)

    return "\n".join([header, *sections, footer])


def main() -> None:
    """Point d'entree CLI : genere personas.md."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    content = generate_personas()
    with PERSONAS_PATH.open("w", encoding="utf-8") as f:
        f.write(content)
    print(f"[personas] Document sauve : {PERSONAS_PATH}")
    print(f"[personas] Taille : {len(content)} caracteres")


if __name__ == "__main__":
    main()
