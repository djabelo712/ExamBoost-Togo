"""
Pipeline de generation LLM de nouvelles questions BEPC/BAC pour ExamBoost Togo.

Module racine qui orchestre la generation via 3 LLM (Claude, GPT-4o, Mistral)
avec une validation croisee : seules les questions validees par au moins 2 LLM
sur 3 sont conservees.

Sous-modules:
    - llm_clients/ : wrappers homogenes autour des 3 SDK LLM.
    - validators/  : validation schema JSON, validation pedagogique, dedup.
    - prompts/     : templates specialises par matiere/examen.
    - merge_questions : fusion + cross-validation 2/3 LLM.
    - generate_questions_3llm : script principal CLI.
"""

from __future__ import annotations

__all__ = ["__version__"]

__version__ = "0.1.0"
