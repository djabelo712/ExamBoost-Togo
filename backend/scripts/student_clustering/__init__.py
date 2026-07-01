"""student_clustering — Clustering K-Means des eleves ExamBoost Togo.

Package contenant le pipeline de segmentation des eleves en profils types
(personas pedagogiques) base sur leurs probabilites de maitrise P(L) par
matiere (BKT).

Modules
-------
- ``generate_synthetic_profiles`` : genere 2000 profils eleves synthetiques
  repartis en 5 archetypes (Scientifique, Litteraire, Polyvalent, En difficulte,
  Mixte atypique).
- ``cluster_students`` : applique K-Means (test K=3,4,5,6 via silhouette) et
  serialise le modele en ``.joblib``.
- ``analyze_clusters`` : genere 2 visualisations (PCA 2D + radar charts).
- ``generate_personas`` : produit le document ``personas.md`` avec descriptions
  pedagogiques par cluster.

Usage
-----
    python generate_synthetic_profiles.py
    python cluster_students.py
    python analyze_clusters.py
    python generate_personas.py
"""

from __future__ import annotations

__all__: list[str] = []
__version__: str = "1.0.0"
