"""Validateurs pour le pipeline de generation LLM.

Trois validateurs complementaires:
    - schema_validator      : conformite au schema JSON ExamBoost.
    - pedagogical_validator : pertinence pedagogique (longueurs, pieges, niveau).
    - duplicate_checker     : deduplication vs questions existantes (SimHash).
"""

from __future__ import annotations

__all__ = [
    "validate_schema",
    "validate_pedagogy",
    "check_duplicates",
    "DuplicateChecker",
]
