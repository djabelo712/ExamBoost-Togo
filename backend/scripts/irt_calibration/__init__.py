"""backend/scripts/irt_calibration — Pipeline de calibration IRT 3PL reel.

Ce package fournit un pipeline complet pour calibrer les parametres IRT
(a, b, c) de chaque question a partir des reponses reelles collectees.
Il reproduit la formule 3PL utilisee cote Flutter (``srs_service.dart``)
et cote backend (``services/irt_service.py``) :

    P(theta) = c + (1 - c) * 1 / (1 + exp(-1.7 * a * (theta - b)))

Modules
-------
- ``generate_synthetic_data``  : genere un dataset synthetique (demo)
- ``calibrate_irt``            : calibre a, b, c via py-irt ou numpy MLE
- ``analyze_calibration``      : genere ICC curves + rapport markdown
- ``export_calibrated_questions`` : exporte questions.json avec irt.calibre=True
"""

__version__ = "1.0.0"
