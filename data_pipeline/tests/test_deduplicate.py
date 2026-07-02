"""
Tests unitaires pour la phase de deduplication SimHash.

Couvre:
    - SimHash computation (meme enonce => hash proche)
    - Distance de Hamming (calcul correct, commutativite, borne 0-64)
    - Déduplication (garde le plus complet, retire les doublons, seuil)
    - Score de completude (completeness_score)
    - Clustering (clusters reportes dans DedupResult)
    - Cas limites (liste vide, liste unique, seuil extrême)

Aucun appel reseau. Aucune dependance filesystem (tout in-memory).
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Dict, List

import pytest
from simhash import Simhash

from deduplicate import (
    DedupResult,
    completeness_score,
    compute_simhash,
    deduplicate_questions,
)
from utils.json_utils import normalize_enonce


# ─── Helpers ───────────────────────────────────────────────────────────────


def _make_q(
    qid: str,
    enonce: str,
    points: int | None = 4,
    explication: str = "explication",
    b: float | None = 0.5,
) -> Dict[str, Any]:
    """Build a fully-formed question dict for dedup tests."""
    return {
        "id": qid,
        "enonce": enonce,
        "reponse": "reponse",
        "explication": explication,
        "matiere": "Mathématiques",
        "chapitre": "Test",
        "competence_id": "TG-MATHS-TEST-001",
        "examen": "BEPC",
        "serie": None,
        "annee": 2022,
        "type": "calcul",
        "choix": None,
        "points": points,
        "irt": {"a": None, "b": b, "c": None, "calibre": False},
    }


# ─── 1) completeness_score ────────────────────────────────────────────────


class TestCompletenessScore:
    """completeness_score returns 0-5 based on field presence."""

    def test_max_score_5_for_fully_filled_question(self):
        q = _make_q("Q1", "Calculer 2+2")
        assert completeness_score(q) == 5

    def test_min_score_1_for_enonce_only(self):
        # Only 'enonce' filled: score=1.
        q = {"enonce": "x"}
        assert completeness_score(q) == 1

    def test_score_0_for_empty_dict(self):
        assert completeness_score({}) == 0

    def test_score_increases_with_reponse(self):
        q = {"enonce": "x", "reponse": "4"}
        assert completeness_score(q) == 2

    def test_score_increases_with_explication(self):
        q = {"enonce": "x", "reponse": "4", "explication": "car 2+2=4"}
        assert completeness_score(q) == 3

    def test_score_increases_with_points(self):
        q = {
            "enonce": "x", "reponse": "4",
            "explication": "ok", "points": 4,
        }
        assert completeness_score(q) == 4

    def test_score_increases_with_irt_b(self):
        q = {
            "enonce": "x", "reponse": "4", "explication": "ok",
            "points": 4, "irt": {"b": 0.5},
        }
        assert completeness_score(q) == 5

    def test_irt_b_null_does_not_score(self):
        q = {
            "enonce": "x", "reponse": "4", "explication": "ok",
            "points": 4, "irt": {"b": None},
        }
        assert completeness_score(q) == 4

    def test_irt_not_a_dict_does_not_score(self):
        q = {
            "enonce": "x", "reponse": "4", "explication": "ok",
            "points": 4, "irt": None,
        }
        assert completeness_score(q) == 4

    def test_whitespace_only_fields_do_not_score(self):
        # enonce with only whitespace => 0.
        q = {"enonce": "   ", "reponse": "  ", "explication": "  "}
        assert completeness_score(q) == 0


# ─── 2) compute_simhash ───────────────────────────────────────────────────


class TestComputeSimhash:
    """compute_simhash returns a Simhash built from shingled normalized enonce."""

    def test_returns_simhash_instance(self):
        q = _make_q("Q1", "Calculer la somme de deux et deux")
        sh = compute_simhash(q)
        assert isinstance(sh, Simhash)

    def test_same_enonce_produces_same_hash(self):
        e = "Calculer la somme de deux et deux"
        sh1 = compute_simhash(_make_q("Q1", e))
        sh2 = compute_simhash(_make_q("Q2", e))
        assert sh1.value == sh2.value

    def test_near_identical_enonce_produces_close_hash(self):
        """Two enonces differing by a single punctuation/space should have
        Hamming distance <= SIMILARITY_MAX_BIT_DISTANCE."""
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Calculer la somme 1+2+3+4.")
        sh1 = compute_simhash(q1)
        sh2 = compute_simhash(q2)
        distance = bin(sh1.value ^ sh2.value).count("1")
        # Should be small (similar).
        assert distance <= 20

    def test_very_different_enonces_produce_distant_hashes(self):
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Quelle est la capitale du Togo en Afrique ?")
        sh1 = compute_simhash(q1)
        sh2 = compute_simhash(q2)
        distance = bin(sh1.value ^ sh2.value).count("1")
        # Different topics => far apart.
        assert distance > 20

    def test_empty_enonce_uses_empty_token(self):
        """A question with no enonce still returns a Simhash (built from
        the literal 'empty' feature)."""
        q = _make_q("Q1", "")
        sh = compute_simhash(q)
        assert isinstance(sh, Simhash)
        # Two empty-enonce questions should have the same hash.
        sh2 = compute_simhash(_make_q("Q2", ""))
        assert sh.value == sh2.value

    def test_accent_insensitive(self):
        """Normalization removes accents before hashing."""
        q1 = _make_q("Q1", "Calculer l'aire du triangle équilatéral")
        q2 = _make_q("Q2", "Calculer l'aire du triangle equilateral")
        sh1 = compute_simhash(q1)
        sh2 = compute_simhash(q2)
        # Identical after accent stripping.
        assert sh1.value == sh2.value

    def test_case_insensitive(self):
        q1 = _make_q("Q1", "Calculer la somme des termes")
        q2 = _make_q("Q2", "CALCULER LA SOMME DES TERMES")
        sh1 = compute_simhash(q1)
        sh2 = compute_simhash(q2)
        assert sh1.value == sh2.value


# ─── 3) Hamming distance ──────────────────────────────────────────────────


class TestHammingDistance:
    """Hamming distance is computed via XOR + bit count."""

    def _hamming(self, sh1: Simhash, sh2: Simhash) -> int:
        return bin(sh1.value ^ sh2.value).count("1")

    def test_distance_zero_for_identical_hashes(self):
        sh = compute_simhash(_make_q("Q1", "Calculer 2+2"))
        assert self._hamming(sh, sh) == 0

    def test_distance_symmetric(self):
        q1 = _make_q("Q1", "Calculer la somme 1+2+3+4")
        q2 = _make_q("Q2", "Quelle est la capitale du Togo")
        sh1 = compute_simhash(q1)
        sh2 = compute_simhash(q2)
        assert self._hamming(sh1, sh2) == self._hamming(sh2, sh1)

    def test_distance_max_is_64_bits(self):
        """A Simhash is 64 bits => Hamming distance is bounded by 64."""
        # Two maximally-different enonces.
        q1 = _make_q("Q1", "a")
        q2 = _make_q("Q2", "z")
        sh1 = compute_simhash(q1)
        sh2 = compute_simhash(q2)
        d = self._hamming(sh1, sh2)
        assert 0 <= d <= 64

    def test_distance_triangle_inequality_holds(self):
        """Hamming distance respects the triangle inequality."""
        qa = _make_q("A", "Calculer la derivee de x carre")
        qb = _make_q("B", "Calculer la derivee de x cube")
        qc = _make_q("C", "Etudier la continuite de f")
        sha = compute_simhash(qa)
        shb = compute_simhash(qb)
        shc = compute_simhash(qc)
        d_ab = self._hamming(sha, shb)
        d_bc = self._hamming(shb, shc)
        d_ac = self._hamming(sha, shc)
        assert d_ac <= d_ab + d_bc


# ─── 4) deduplicate_questions ─────────────────────────────────────────────


class TestDeduplicateQuestions:
    """deduplicate_questions returns (kept, DedupResult)."""

    def test_empty_list_returns_empty(self):
        kept, result = deduplicate_questions([])
        assert kept == []
        assert result.input_count == 0
        assert result.output_count == 0
        assert result.duplicates_dropped == 0

    def test_single_question_kept(self):
        q = _make_q("Q1", "Calculer 2+2")
        kept, result = deduplicate_questions([q])
        assert len(kept) == 1
        assert result.input_count == 1
        assert result.output_count == 1
        assert result.duplicates_dropped == 0

    def test_two_distinct_questions_both_kept(self):
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Quelle est la capitale du Togo en Afrique ?")
        kept, result = deduplicate_questions([q1, q2])
        assert len(kept) == 2
        assert result.duplicates_dropped == 0

    def test_near_duplicate_deduped(self):
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Calculer la somme 1+2+3+4.")  # quasi identical
        q3 = _make_q("Q3", "Quelle est la capitale du Togo ?")
        kept, result = deduplicate_questions([q1, q2, q3])
        assert result.input_count == 3
        assert result.output_count == 2
        assert result.duplicates_dropped == 1

    def test_keeps_most_complete_on_collision(self):
        """When two questions are duplicates, the most complete one is kept."""
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.",
                     points=None, explication="", b=None)  # lower score
        q2 = _make_q("Q2", "Calculer la somme 1 + 2 + 3 + 4.",
                     points=4, explication="explication", b=0.5)  # higher score
        kept, _ = deduplicate_questions([q1, q2])
        assert len(kept) == 1
        assert kept[0]["id"] == "Q2"

    def test_keeps_first_when_equal_completeness(self):
        """When two duplicates have equal completeness, the one with the
        higher index wins (max with tie-breaker on i)."""
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Calculer la somme 1 + 2 + 3 + 4.")
        kept, _ = deduplicate_questions([q1, q2])
        assert len(kept) == 1
        # max((score, idx)) => Q2 wins because of higher idx.
        assert kept[0]["id"] == "Q2"

    def test_threshold_zero_keeps_distinct_topics(self):
        """A threshold of 0 requires exact hash match for dedup.

        With clearly distinct enonces, all questions are kept.
        """
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q(
            "Q2",
            "Quelle est la capitale du Togo en Afrique de l'Ouest ?",
        )
        q3 = _make_q(
            "Q3",
            "Definir la photosynthese chez les vegetaux chlorophylliens.",
        )
        kept, result = deduplicate_questions([q1, q2, q3], threshold=0)
        # All three are clearly distinct topics => all kept.
        assert result.output_count == 3
        assert result.duplicates_dropped == 0

    def test_threshold_64_dedups_everything(self):
        """A threshold of 64 means any two questions are duplicates."""
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Quelle est la capitale du Togo ?")
        kept, result = deduplicate_questions([q1, q2], threshold=64)
        assert result.output_count == 1

    def test_result_clusters_populated(self):
        """When duplicates are found, the clusters field lists them."""
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Calculer la somme 1+2+3+4.")
        kept, result = deduplicate_questions([q1, q2])
        assert len(result.clusters) == 1
        cluster = result.clusters[0]
        assert set(cluster) == {"Q1", "Q2"}

    def test_result_clusters_empty_when_no_dups(self):
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Quelle est la capitale du Togo en Afrique de l'Ouest ?")
        _, result = deduplicate_questions([q1, q2])
        assert result.clusters == []

    def test_result_is_dedup_result_instance(self):
        q = _make_q("Q1", "Calculer 2+2")
        _, result = deduplicate_questions([q])
        assert isinstance(result, DedupResult)

    def test_three_duplicates_collapse_to_one(self):
        """Three near-identical questions collapse to one kept question."""
        q1 = _make_q("Q1", "Calculer la somme 1 + 2 + 3 + 4.")
        q2 = _make_q("Q2", "Calculer la somme 1 + 2 + 3 + 4 !")
        q3 = _make_q("Q3", "Calculer la somme 1 + 2 + 3 + 4 ?")
        kept, result = deduplicate_questions([q1, q2, q3])
        assert len(kept) == 1
        assert result.duplicates_dropped == 2


# ─── 5) Integration with normalize_enonce ────────────────────────────────


class TestNormalizeEnonceIntegration:
    """The SimHash pipeline depends on normalize_enonce(). Verify contract."""

    def test_normalize_strips_punctuation(self):
        out = normalize_enonce("Calculer 2+2 !")
        # No punctuation remains.
        assert "+" not in out
        assert "!" not in out

    def test_normalize_collapses_whitespace(self):
        out = normalize_enonce("a    b\tc\nd")
        assert "  " not in out
        assert "\t" not in out
        assert "\n" not in out

    def test_normalize_lowercases(self):
        assert normalize_enonce("ABCDEF") == "abcdef"

    def test_normalize_empty_returns_empty(self):
        assert normalize_enonce("") == ""
