# Student Clustering — Personas pedagogiques K-Means

Pipeline Python de segmentation des eleves en 4-5 profils types (personas
pedagogiques) base sur leurs probabilites de maitrise P(L) par matiere
(sortie du modele BKT, cf. `lib/models/user.dart` champ `bktMaitrise`).

## Objectif

Disposer d'un modele de clustering K-Means permettant de :

- **Identifier le profil type** d'un eleve (Scientifique, Litteraire,
  Polyvalent, En difficulte, Atypique) a partir de ses P(L) par matiere.
- **Personnaliser les recommandations** : mix de sessions, messages de
  motivation, difficulte ciblee.
- **Segmenter la base utilisateur** : analyser les cohortes, alerter sur
  les eleves en difficulte, adapter le contenu editorial.
- **Brancher en production** via un endpoint FastAPI
  `/student/cluster/{user_id}` qui retourne le cluster + le persona.

## Installation

### 1. Creer un environnement virtuel (Python 3.11+)

```bash
cd backend/scripts/student_clustering
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2. Verifier les versions

```bash
python -c "import sklearn, pandas, numpy, matplotlib, joblib; print('OK')"
```

## Workflow

Le pipeline se lance en 4 etapes (depuis le dossier `student_clustering/`) :

```bash
# 1. Generer 2000 profils synthetiques (5 archetypes) — ~2 sec
python generate_synthetic_profiles.py

# 2. Clusteriser en K groupes (K=3,4,5,6 testes) — ~3 sec
python cluster_students.py

# 3. Analyser : PCA 2D + radar charts — ~5 sec
python analyze_clusters.py

# 4. Generer personas.md (descriptions pedagogiques) — ~1 sec
python generate_personas.py
```

A la fin, le dossier `output/` contient :

```
output/
├── profiles.csv                    # 2000 profils + colonne cluster ajoutee
├── cluster_model.joblib            # Modele KMeans + StandardScaler serialise
├── cluster_stats.json              # Stats par cluster (taille, P(L) moyen, ...)
├── cluster_visualization.png       # PCA 2D avec centroides
├── cluster_profiles.png            # Radar charts 2x3 par cluster
└── personas.md                     # Personas pedagogiques (markdown)
```

## Architecture des 5 archetypes simules

Le simulateur `generate_synthetic_profiles.py` produit des profils realistes
avec correlations intra-groupe (un eleve fort en maths a aussi un niveau
correct en sciences, pas 0.05) :

| Archetype        | %    | Profil type                                              |
|------------------|------|----------------------------------------------------------|
| Scientifique     | 25 % | Fort en Maths/Sciences/SVT (>= 0.72), moyen en lettres   |
| Litteraire       | 20 % | Fort en FR/Histoire/Anglais (>= 0.75), moyen en sciences |
| Polyvalent       | 20 % | Equilibre ~0.67 partout, faible ecart                   |
| En difficulte    | 20 % | P(L) < 0.40 sur les 6 matieres                          |
| Mixte atypique   | 15 % | 1-2 matieres fortes (0.78), les autres faibles (0.35)   |

Bruit gaussien ajoute (sigma 0.06 a 0.10 selon archetype) + facteur commun
correle (30 % du bruit) pour eviter les profils physiquement improbables.

## Methodologie de clustering

### Choix de K

Le pipeline teste K = 3, 4, 5, 6 et garde le K qui maximise le **silhouette
score** (critere principal). Le silhouette score mesure a la fois la
**cohesion** intra-cluster et la **separation** inter-cluster, ce qui en
fait un meilleur critere que l'inertie (qui baisse monotone avec K) ou
le Davies-Bouldin index (qui minimize).

Sur les 2000 profils synthetiques avec 5 archetypes, on s'attend a ce que
K=5 gagne (silhouette ~ 0.30-0.40), mais le pipeline laisse l'algorithme
decider.

### Standardisation

Le `StandardScaler` (moyenne 0, variance 1) est applique avant K-Means car
les P(L) sont deja sur [0, 1] mais la variance peut differrer entre
matieres. Sans standardisation, une matiere a forte variance dominerait
le clustering.

### Classification des clusters en personas

Une fois les clusters identifies, `generate_personas.py` attribue
automatiquement un persona a chaque cluster en fonction de son profil moyen :

1. `mean_all < 0.40` -> **En difficulte**
2. `mean_all > 0.55 ET std < 0.10` -> **Polyvalent**
3. `mean_sciences > 0.65 ET gap(sciences - lettres) > 0.15` -> **Scientifique**
4. `mean_lettres > 0.65 ET gap(lettres - sciences) > 0.15` -> **Litteraire**
5. sinon -> **Atypique**

Cette classification est robuste au choix de K : si K-Means trouve 4 ou 6
clusters, le persona attribue reste coherent avec le profil moyen observe.

## Branchement en production

### Etape 1 — Copier le modele serialise

```bash
cp backend/scripts/student_clustering/output/cluster_model.joblib \
   backend/services/models/cluster_model.joblib
```

### Etape 2 — Creer le service d'inference

```python
# backend/services/student_clustering_service.py
import joblib
from pathlib import Path

MODEL_PATH = Path(__file__).parent / "models" / "cluster_model.joblib"
_model_data = joblib.load(MODEL_PATH)
_kmeans = _model_data["model"]
_scaler = _model_data["scaler"]
_features = _model_data["features"]
_best_k = _model_data["best_k"]


def get_student_cluster(pL_by_matiere: dict[str, float]) -> int:
    """Retourne l'ID de cluster (0 a K-1) pour un eleve donne.

    Parameters
    ----------
    pL_by_matiere : dict[str, float]
        Dictionnaire {matiere: P(L)} pour les 6 matieres.

    Returns
    -------
    int
        ID du cluster assigne.
    """
    X = [[pL_by_matiere[f] for f in _features]]
    X_scaled = _scaler.transform(X)
    return int(_kmeans.predict(X_scaled)[0])
```

### Etape 3 — Agreger P(L) par matiere depuis bktMaitrise

Le modele Flutter (`lib/models/user.dart`) stocke `bktMaitrise` comme
`Map<String, double>` ou la cle est un `competenceId` (ex :
`TG-MATHS-EQ1D-001`). Pour obtenir P(L) par matiere, agreger par prefixe :

```python
def aggregate_pL_by_matiere(bkt_maitrise: dict[str, float]) -> dict[str, float]:
    """Moyenne P(L) par matiere a partir du dictionnaire competence -> P(L).

    Les competenceId suivent le format TG-<MATIERE>-<CHAP>-<NUM>
    (ex : TG-MATHS-EQ1D-001, TG-FR-CONJ-002).
    """
    mapping = {
        "MATHS": "pL_maths",
        "FR": "pL_francais",
        "SCIENCES": "pL_sciences",
        "SVT": "pL_svt",
        "HISTOIRE": "pL_histoire",
        "ANGLAIS": "pL_anglais",
    }
    sums = {v: 0.0 for v in mapping.values()}
    counts = {v: 0 for v in mapping.values()}

    for comp_id, pL in bkt_maitrise.items():
        parts = comp_id.split("-")
        if len(parts) < 2:
            continue
        matiere_code = parts[1].upper()
        col = mapping.get(matiere_code)
        if col is None:
            continue
        sums[col] += pL
        counts[col] += 1

    return {col: (sums[col] / counts[col] if counts[col] > 0 else 0.0)
            for col in sums}
```

### Etape 4 — Endpoint FastAPI

```python
# backend/routers/student.py
from fastapi import APIRouter, HTTPException
from backend.services.student_clustering_service import get_student_cluster
from backend.services.bkt_service import aggregate_pL_by_matiere

router = APIRouter(prefix="/student", tags=["student"])


@router.get("/cluster/{user_id}")
async def get_cluster(user_id: str):
    """Retourne le cluster (persona) de l'eleve."""
    user = await fetch_user(user_id)
    if not user:
        raise HTTPException(404, "User not found")

    pL_by_matiere = aggregate_pL_by_matiere(user.bkt_maitrise)
    cluster_id = get_student_cluster(pL_by_matiere)

    return {
        "user_id": user_id,
        "cluster": cluster_id,
        "persona": PERSONA_NAMES[cluster_id],
        "recommendations": PERSONA_RECOMMENDATIONS[cluster_id],
        "motivation_messages": PERSONA_MESSAGES[cluster_id],
    }
```

### Etape 5 — Cote Flutter

Dans le dashboard, afficher le persona et adapter les messages :

```dart
// lib/screens/dashboard/widgets/persona_card.dart
final persona = await api.getStudentCluster(userId);
Text('Tu es profil ${persona.label}');
Text(persona.motivationMessages.first);
```

## Re-entrainement avec donnees reelles

Le modele actuel est entraine sur 2000 profils synthetiques. Pour passer
en production avec donnees reelles :

### Frequence recommandee

| Phase projet     | Frequence      | Source donnees              |
|------------------|----------------|------------------------------|
| Pre-pilote (M1-M4) | Une fois     | Synthetique 2000             |
| Pilote (M5-M6)   | Bi-mensuel     | Synthetique + 100-500 vrais  |
| Production (M7+) | Mensuel (cron) | 5000+ vrais eleves           |

### Procedure

1. Recuperer les `bktMaitrise` des eleves actifs (>= 50 questions repondues).
2. Agreger P(L) par matiere (cf. `aggregate_pL_by_matiere` ci-dessus).
3. Exporter en CSV avec le meme schema que `profiles.csv` :
   ```
   student_id, pL_maths, pL_francais, pL_sciences, pL_svt, pL_histoire, pL_anglais, archetype_true
   ```
   (la colonne `archetype_true` peut etre vide pour les donnees reelles,
   elle n'est utilisee que pour validation sur donnees synthetiques.)
4. Relancer :
   ```bash
   python cluster_students.py
   python analyze_clusters.py
   python generate_personas.py
   ```
5. Re-deployer `cluster_model.joblib` + `personas.md` sur le backend.

### Seuils d'alerte

- **Silhouette < 0.20** sur nouvelles donnees : clusters mal separes,
  reconsiderer K ou changer d'algorithme (DBSCAN, GMM).
- **Taille d'un cluster > 60 %** de la population : clustering trop grossier,
  augmenter K.
- **Taille d'un cluster < 2 %** de la population : cluster parasite (outlier),
  considerer un cluster "bruit" ou augmenter la taille du dataset.

## Limites

1. **K-Means suppose des clusters spheriques** : les clusters de forme
   allongee ou concentrique ne seront pas bien captures. Pour les profils
   atypiques (mixte), considerer **DBSCAN** (densite-based, gere le bruit)
   ou **Gaussian Mixture Models** (clusters elliptiques, probabilistes).
2. **P(L) BKT par matiere** est une moyenne sur les competences — un eleve
   peut etre fort sur un chapitre et faible sur un autre dans la meme
   matiere. Le clustering opere a l'echelle matiere, pas competence.
3. **Pas de signal comportemental** : le clustering actuel n'utilise que
   P(L). Pour affiner, ajouter en features : nombre de sessions 7j, streak,
   temps moyen par question (cf. `ml_training/generate_synthetic_students.py`).
4. **Personas statiques** : les personas sont calcules une fois pour
   toutes. En production, re-entrainer mensuellement avec les nouvelles
   donnees pour detecter d'eventuels nouveaux profils.
5. **Cold start** : un nouvel eleve sans donnees BKT n'a pas de cluster.
   Prevoir un persona par defaut ("Decouverte") pendant les 10 premieres
   questions, puis un cluster provisional calcule des qu'il a >= 1 P(L)
   par matiere.

## Structure du code

```
student_clustering/
├── __init__.py                      # Package marker
├── generate_synthetic_profiles.py   # Simulateur 2000 eleves (5 archetypes)
├── cluster_students.py              # K-Means + silhouette pour choix K
├── analyze_clusters.py              # PCA 2D + radar charts
├── generate_personas.py             # Personas markdown + reco pedagogiques
├── requirements.txt                 # Deps sklearn/pandas/numpy/matplotlib/joblib
├── README.md                        # Ce fichier
└── output/                          # Artefacts (genere par les scripts)
    ├── profiles.csv
    ├── cluster_model.joblib
    ├── cluster_stats.json
    ├── cluster_visualization.png
    ├── cluster_profiles.png
    └── personas.md
```

## Conventions

- **Python 3.11+** avec type hints (`from __future__ import annotations`)
- **Docstrings EN** (style Google) — regle Session 3
- **Commentaires FR** — regle Session 3
- **Pas d'emojis** — regle Session 3
- **Palette vert Togo** : `#006837` (vert primaire) + `#D97700` (orange accent)
- **Reproductibilite** : `random_state=42` partout
- **Outputs** dans `./output/` (jamais a la racine)

## References

- MacQueen (1967) — *Some methods for classification and analysis of
  multivariate observations* (K-Means original)
- Rousseeuw (1987) — *Silhouettes: a graphical aid to the interpretation
  and validation of cluster analysis* (silhouette score)
- Davies & Bouldin (1979) — *A Cluster Separation Measure* (DB index)
- Corbett & Anderson (1995) — *Knowledge Tracing: Modeling the Acquisition
  of Human Knowledge* (BKT, source des P(L) features)
