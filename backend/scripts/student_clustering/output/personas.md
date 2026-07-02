# Personas Pedagogiques — ExamBoost Togo

Ce document decrit les 5 profils types d'eleves identifiees par
clustering K-Means sur 2000 profils eleves (P(L) par matiere, modele BKT).
Utilisez ces personas pour personnaliser les recommandations de revision
dans l'app Flutter et le backend FastAPI.

## Synthese technique

- **Algorithme** : K-Means (sklearn) avec standardisation prealable
- **Features** : 6 P(L) par matiere (Maths, Francais, Sciences, SVT, Histoire, Anglais)
- **K optimal** : 5
- **Selection de K testee** :
- K=3 : silhouette=0.400, Davies-Bouldin=0.954
- K=4 : silhouette=0.356, Davies-Bouldin=1.039
- K=5 : silhouette=0.372, Davies-Bouldin=1.408 (choisi)
- K=6 : silhouette=0.383, Davies-Bouldin=1.392
> **Note** : K=3 a la meilleure silhouette stricte, mais K=5 (spec "4-5 profils types") a ete prefere car sa silhouette est >= 85% du meilleur. Granularite pedagogique privilegiee.

## Methodologie

1. **Generation** de 2000 profils synthetiques repartis en 5 archetypes
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

---
## Cluster 0 : "L'Eleve en Difficulte" (433 eleves, 21.6%)

### Profil moyen
- Mathematiques : 31%
- Francais : 34%
- Sciences Physiques : 28%
- SVT : 27%
- Histoire-Geographie : 30%
- Anglais : 31%

### Caracteristiques
- Points faibles : Mathematiques, Francais, Sciences Physiques, SVT, Histoire-Geographie, Anglais
- Maitrise insuffisante sur la plupart des matieres (< 40%)
- Risque d'echec a l'examen sans soutien renforce
- Profil type : eleve demotive ou en rupture scolaire, a besoin d'un accompagnement individuel et de petits objectifs

### Recommandations pedagogiques
1. **Reprise des fondamentaux** : revoir les bases de chaque matiere (1 chapitre fondamental/semaine, pas de saut)
2. **Petits objectifs** : 5 questions/jour max, focalisees sur Mathematiques, Francais, Sciences Physiques, SVT, Histoire-Geographie, Anglais, pour restaurer la confiance avant la quantite
3. **Objectif court terme** : atteindre 50% de maitrise sur 3 matieres cles (maths, francais, sciences) avant la simulation suivante
4. **Mix ideal sessions** : 50% matieres prioritaires (maths + francais), 50% decouverte des autres matieres

### Messages de motivation
- "Chaque petite victoire compte. 5 questions aujourd'hui, demain on en fait 6."
- "Tu progresses plus vite que tu ne le penses. Reste regulier, le declic viendra."

### Composition (archetypes vrais les plus representes)
En_difficulte (400), Mixte_atypique (33)

---
## Cluster 1 : "Le Polyvalent" (424 eleves, 21.2%)

### Profil moyen
- Mathematiques : 69%
- Francais : 70%
- Sciences Physiques : 66%
- SVT : 65%
- Histoire-Geographie : 67%
- Anglais : 67%

### Caracteristiques
- Points forts : Mathematiques, Francais, Sciences Physiques, SVT, Histoire-Geographie, Anglais
- Profil equilibre sur les 6 matieres
- Bonne regularite, peu de lacunes marquees
- Profil type : eleve serieux et methodique, vise une mention au BEPC ou au BAC

### Recommandations pedagogiques
1. **Consolidation generale** : 1 question/jour par matiere pour entretenir le niveau equilibre sur les 6 matieres
2. **Affinement** : cibler les 1-2 matieres les plus basses (tes matieres les plus faibles) pour viser une mention
3. **Objectif** : viser 15/20+ (mention Assez Bien ou Bien) au BEPC / BAC
4. **Mix ideal sessions** : 40% sciences, 40% lettres, 20% anglais — equilibre

### Messages de motivation
- "Profil equilibre — tu peux viser une mention. Maintiens le cap !"
- "Tu n'as pas de vraie faiblesse, c'est rare. Transforme-la en mention."

### Composition (archetypes vrais les plus representes)
Polyvalent (398), Scientifique (18), Mixte_atypique (5)

---
## Cluster 2 : "Le Litteraire" (425 eleves, 21.2%)

### Profil moyen
- Mathematiques : 50%
- Francais : 79%
- Sciences Physiques : 44%
- SVT : 47%
- Histoire-Geographie : 77%
- Anglais : 74%

### Caracteristiques
- Points forts : Francais, Histoire-Geographie, Anglais
- Niveau moyen : Mathematiques, Sciences Physiques, SVT
- Excellente maitrise des lettres et langues
- Difficulte relative en sciences exactes
- Profil type : eleve de serie A ou en voie litteraire, a l'aise en dissertation mais peu spontane en calcul

### Recommandations pedagogiques
1. **Maintien lettres** : continuer 2-3 questions/jour en lettres et langues (Francais, Histoire-Geographie, Anglais) pour consolider l'avance
2. **Renforcement sciences** : prioriser tes matieres les plus faibles — reprendre les fondamentaux (calculs, formules) avant les sujets d'examen
3. **Objectif** : viser 13/20 global (au lieu de 11) en gagnant 2 points en sciences
4. **Mix ideal sessions** : 60% sciences, 30% lettres, 10% anglais

### Messages de motivation
- "Ta plume est ton arme ! Maintenant un effort sur les sciences et tout degage."
- "Avec ton niveau en francais, la dissertation est ton point fort. Pousse aussi les maths."

### Composition (archetypes vrais les plus representes)
Litteraire (397), Mixte_atypique (27), Polyvalent (1)

---
## Cluster 3 : "L'Atypique" (218 eleves, 10.9%)

### Profil moyen
- Mathematiques : 46%
- Francais : 43%
- Sciences Physiques : 46%
- SVT : 54%
- Histoire-Geographie : 46%
- Anglais : 46%

### Caracteristiques
- Niveau moyen : Mathematiques, Francais, Sciences Physiques, SVT, Histoire-Geographie, Anglais
- Profil heterogene : 1-2 points forts atypiques et des lacunes ailleurs
- Ne correspond pas aux series classiques (C, D, A)
- Profil type : eleve passionne par un domaine precis mais en decrochage sur le reste du programme

### Recommandations pedagogiques
1. **Capitaliser les points forts** : entretenir tes points forts avec 2-3 questions/jour pour conserver un avantage differentiel
2. **Combler les lacunes** : attaquer tes matieres les plus faibles en priorite — 1 chapitre/semaine, petit rythme regulier
3. **Objectif** : viser 12/20 global en elevant le plancher (pas en poussant le plafond)
4. **Mix ideal sessions** : 70% matieres faibles, 30% points forts

### Messages de motivation
- "Ton profil original est une force ! Capitalise sur tes points forts."
- "Personne n'a ton parcours. Convertis tes atypies en atouts a l'examen."

### Composition (archetypes vrais les plus representes)
Mixte_atypique (216), Scientifique (2)

---
## Cluster 4 : "Le Scientifique" (500 eleves, 25.0%)

### Profil moyen
- Mathematiques : 78%
- Francais : 51%
- Sciences Physiques : 75%
- SVT : 71%
- Histoire-Geographie : 47%
- Anglais : 54%

### Caracteristiques
- Points forts : Mathematiques, Sciences Physiques, SVT
- Niveau moyen : Francais, Histoire-Geographie, Anglais
- Excellente maitrise des matieres scientifiques
- Legere faiblesse en lettres et langues
- Profil type : eleve de serie C ou D, en confiance en maths mais qui neglige parfois le francais (pourtant coef 2 au BEPC)

### Recommandations pedagogiques
1. **Maintien scientifique** : continuer 2-3 questions/jour en sciences (Mathematiques, Sciences Physiques, SVT) pour ne pas perdre le niveau
2. **Renforcement lettres** : prioriser tes matieres les plus faibles — chapitres les plus faibles, 1 chapitre toutes les 2 semaines
3. **Objectif** : viser 14/20 global (au lieu de 12 actuellement) en comblant le retard en lettres
4. **Mix ideal sessions** : 60% lettres, 30% sciences, 10% anglais

### Messages de motivation
- "Tu es fort en sciences, maintenant attaque le francais pour viser plus haut !"
- "Avec ton niveau en maths, le BAC C est a portee. Ne neglige pas le francais (coef 2)."

### Composition (archetypes vrais les plus representes)
Scientifique (480), Mixte_atypique (19), Polyvalent (1)

---

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
_features = _model_data["features"]  # [pL_maths, pL_francais, pL_sciences, pL_svt, pL_histoire, pL_anglais]


def get_student_cluster(pL_by_matiere: dict[str, float]) -> int:
    """Retourne l'ID de cluster (0 a K-1) pour un eleve donne.

    Parameters
    ----------
    pL_by_matiere : dict[str, float]
        Dictionnaire {matiere: P(L)} pour les 6 matieres (cles : pL_maths,
        pL_francais, pL_sciences, pL_svt, pL_histoire, pL_anglais).

    Returns
    -------
    int
        ID du cluster assigne.
    """
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


@router.get("/cluster/{user_id}")
async def get_cluster(user_id: str):
    """Retourne le cluster (persona) de l'eleve connecte."""
    # 1. Recuperer le bktMaitrise de l'eleve (depuis la DB)
    user = await fetch_user(user_id)
    if not user:
        raise HTTPException(404, "User not found")

    # 2. Agreger P(L) par matiere (moyenne des competences de chaque matiere)
    pL_by_matiere = aggregate_pL_by_matiere(user.bktMaitrise)
    #    ex : {'pL_maths': 0.78, 'pL_francais': 0.52, ...}

    # 3. Inferer le cluster
    cluster_id = get_student_cluster(pL_by_matiere)

    return {
        "user_id": user_id,
        "cluster": cluster_id,
        "persona": PERSONA_NAMES.get(cluster_id, "Inconnu"),
        "recommendations": PERSONA_RECOMMENDATIONS.get(cluster_id, []),
    }
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
