"""
Configuration pytest commune.

Ajoute la racine du pipeline au sys.path afin que les imports
`from utils...`, `from config...` fonctionnent depuis le dossier tests/.
"""

from __future__ import annotations

import sys
from pathlib import Path

# Remonte d'un niveau (tests/ -> data_pipeline/)
_PIPELINE_ROOT = Path(__file__).resolve().parent.parent
if str(_PIPELINE_ROOT) not in sys.path:
    sys.path.insert(0, str(_PIPELINE_ROOT))
