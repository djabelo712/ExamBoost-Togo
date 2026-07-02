"""services/classroom_manager.py — Gestionnaire de sessions classe temps reel.

Le ClassroomManager est un singleton en memoire (par defaut). Pour une
mise en prod multi-instance, il faudrait le remplacer par un backend
Redis pub/sub ; l'API publique reste identique.

Responsabilites :
  - Creation de sessions (code 6 chiffres unique)
  - Connexion/deconnexion des joueurs (eleves + enseignant)
  - Diffusion des questions, enregistrement des reponses
  - Calcul du score (points = base * temps_restant / temps_total)
  - Classement temps reel + statistiques par question
  - Mode live (timer 30s) et mode devoir (sans timer, 7 jours)

Le manager n'a AUCUNE dependance a FastAPI (websocket acceptee en dehors)
pour rester testable unitairement.
"""

from __future__ import annotations

import asyncio
import random
import string
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Set, Tuple

# On importe les modeles Pydantic
from models.classroom_models import (
    AnswerResultOut,
    ClassroomPlayerOut,
    ClassroomSessionOut,
    PlayerRole,
    PlayerStatus,
    QuestionStatOut,
    SessionCreateRequest,
    SessionMode,
    SessionResultsOut,
    SessionStatus,
    SessionStatusOut,
    utc_now,
    event,
)


# ─── Constantes ──────────────────────────────────────────────────────
CODE_LENGTH = 6
CODE_ALPHABET = string.digits  # code a 6 chiffres
BASE_POINTS = 1000             # points max par question (reponse instantanee)
MIN_POINTS = 100               # points minimum si reponse correcte
HOMEWORK_DEFAULT_DAYS = 7


# ─── Dataclasses internes (etat mutable) ─────────────────────────────
@dataclass
class _Player:
    """Joueur connecte (etat interne, non serialise directement)."""
    id: str
    name: str
    role: PlayerRole
    score: int = 0
    status: PlayerStatus = PlayerStatus.connected
    websocket: Any = None  # starlette.websockets.WebSocket (evite import circulaire)
    joined_at: datetime = field(default_factory=utc_now)
    answered_count: int = 0
    last_answer_correct: Optional[bool] = None
    # Reponses historique : {question_id: (answer, correct, time_taken, points)}
    answers: Dict[str, Tuple[str, bool, float, int]] = field(default_factory=dict)

    def to_out(self) -> ClassroomPlayerOut:
        return ClassroomPlayerOut(
            id=self.id,
            name=self.name,
            score=self.score,
            role=self.role,
            status=self.status,
            last_answer_correct=self.last_answer_correct,
            answered_count=self.answered_count,
            joined_at=self.joined_at,
        )


@dataclass
class _QuestionRuntime:
    """Etat d'une question pendant qu'elle est diffusee."""
    question_id: str
    started_at: datetime
    time_limit_seconds: int
    answered_player_ids: Set[str] = field(default_factory=set)
    correct_player_ids: Set[str] = field(default_factory=set)
    answer_times: List[float] = field(default_factory=list)  # secondes


@dataclass
class _Session:
    """Session classe (etat interne)."""
    code: str
    teacher_id: str
    teacher_name: str
    exam: str
    matiere: Optional[str]
    question_ids: List[str]
    mode: SessionMode
    time_limit_seconds: int
    homework_expires_at: Optional[datetime]
    created_at: datetime = field(default_factory=utc_now)
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    status: SessionStatus = SessionStatus.waiting
    players: List[_Player] = field(default_factory=list)
    current_index: int = -1
    current_runtime: Optional[_QuestionRuntime] = None
    # Snapshot des questions (id, enonce, reponse, explication, type, choix)
    # Recuperees au moment de la creation via question_repository
    questions_snapshot: List[Dict[str, Any]] = field(default_factory=list)

    # ─── Helpers ───────────────────────────────────────────────────
    @property
    def students(self) -> List[_Player]:
        return [p for p in self.players if p.role == PlayerRole.student]

    @property
    def teacher(self) -> Optional[_Player]:
        """Enseignant connecte (sinon le 1er enseignant connu, meme
        deconnecte). On preferera l'enseignant actif pour eviter de
        bloquer une reconnexion apres deconnexion reseau."""
        # Priorite : enseignant connecte
        for p in self.players:
            if p.role == PlayerRole.teacher and p.status != PlayerStatus.disconnected:
                return p
        # Sinon : le 1er enseignant connu (pour info)
        for p in self.players:
            if p.role == PlayerRole.teacher:
                return p
        return None

    def get_player(self, player_id: str) -> Optional[_Player]:
        for p in self.players:
            if p.id == player_id:
                return p
        return None

    def to_out(self) -> ClassroomSessionOut:
        return ClassroomSessionOut(
            code=self.code,
            teacher_id=self.teacher_id,
            teacher_name=self.teacher_name,
            exam=self.exam,
            matiere=self.matiere,
            mode=self.mode,
            status=self.status,
            time_limit_seconds=self.time_limit_seconds,
            question_ids=self.question_ids,
            current_question_index=self.current_index,
            current_question_id=(
                self.question_ids[self.current_index]
                if 0 <= self.current_index < len(self.question_ids)
                else None
            ),
            players_count=len(self.students),
            created_at=self.created_at,
            started_at=self.started_at,
            ended_at=self.ended_at,
            homework_expires_at=self.homework_expires_at,
        )

    def to_status_out(self) -> SessionStatusOut:
        return SessionStatusOut(
            code=self.code,
            exists=True,
            status=self.status,
            mode=self.mode,
            players_count=len(self.students),
            current_question_index=self.current_index,
            total_questions=len(self.question_ids),
            teacher_name=self.teacher_name,
            created_at=self.created_at,
            homework_expires_at=self.homework_expires_at,
        )


# ─── Repository de questions (lazy, faillible) ──────────────────────
def _load_questions_snapshot(question_ids: List[str]) -> List[Dict[str, Any]]:
    """Recupere les questions depuis la base SQL.

    Si la base n'est pas disponible (ex: tests unitaires), retourne des
    placeholders pour ne pas bloquer la creation de session. Les
    placeholders n'ont pas de reponse -> toutes les reponses seront
    considerees comme fausses.
    """
    try:
        from sqlalchemy import select
        from database import SessionLocal
        from models.db_models import Question as DbQuestion

        snapshot: List[Dict[str, Any]] = []
        with SessionLocal() as db:
            rows = db.execute(
                select(DbQuestion).where(DbQuestion.id.in_(question_ids))
            ).scalars().all()
            # Conserver l'ordre demande
            rows_by_id = {r.id: r for r in rows}
            for qid in question_ids:
                r = rows_by_id.get(qid)
                if r is None:
                    snapshot.append({
                        "id": qid, "enonce": "Question introuvable",
                        "reponse": "", "explication": None,
                        "type": "ouvert", "choix": None,
                    })
                else:
                    snapshot.append({
                        "id": r.id,
                        "enonce": r.enonce,
                        "reponse": r.reponse,
                        "explication": r.explication,
                        "type": r.type.name if r.type else "ouvert",
                        "choix": r.choix if r.choix else None,
                    })
        return snapshot
    except Exception:
        # Fallback : placeholders
        return [
            {
                "id": qid,
                "enonce": f"Question {qid}",
                "reponse": "",
                "explication": None,
                "type": "ouvert",
                "choix": None,
            }
            for qid in question_ids
        ]


# ─── Manager (singleton) ────────────────────────────────────────────
class ClassroomManager:
    """Gestionnaire centralise des sessions classe temps reel."""

    def __init__(self) -> None:
        self.sessions: Dict[str, _Session] = {}
        # Lock par session pour eviter les courses sur reponses simultanees
        self._locks: Dict[str, asyncio.Lock] = {}

    # ─── Codes & creation ──────────────────────────────────────────
    def _generate_unique_code(self) -> str:
        """Genere un code a 6 chiffres unique."""
        for _ in range(1000):
            code = "".join(random.choices(CODE_ALPHABET, k=CODE_LENGTH))
            if code not in self.sessions:
                return code
        # Fallback improbable : ajout d'un suffixe aleatoire
        return "".join(random.choices(CODE_ALPHABET, k=CODE_LENGTH))

    def create_session(self, payload: SessionCreateRequest) -> str:
        """Cree une session et retourne le code 6 chiffres."""
        code = self._generate_unique_code()
        homework_expires = None
        if payload.mode == SessionMode.homework:
            homework_expires = utc_now() + timedelta(days=payload.homework_days)

        snapshot = _load_questions_snapshot(payload.question_ids)
        session = _Session(
            code=code,
            teacher_id=payload.teacher_id,
            teacher_name=payload.teacher_name,
            exam=payload.exam,
            matiere=payload.matiere,
            question_ids=list(payload.question_ids),
            mode=payload.mode,
            time_limit_seconds=payload.time_limit_seconds,
            homework_expires_at=homework_expires,
            questions_snapshot=snapshot,
        )
        self.sessions[code] = session
        self._locks[code] = asyncio.Lock()
        return code

    def get_session(self, code: str) -> Optional[_Session]:
        session = self.sessions.get(code)
        if not session:
            return None
        # Auto-expiration des devoirs
        if (
            session.mode == SessionMode.homework
            and session.status != SessionStatus.ended
            and session.homework_expires_at
            and utc_now() > session.homework_expires_at
        ):
            self._finalize_session(session)
        return session

    # ─── Connexion / deconnexion ───────────────────────────────────
    def add_player(
        self,
        code: str,
        join_data: Dict[str, Any],
        websocket: Any,
    ) -> Optional[_Player]:
        """Ajoute un joueur a la session. Retourne None si introuvable."""
        session = self.get_session(code)
        if not session or session.status == SessionStatus.ended:
            return None

        player_id = join_data.get("player_id") or join_data.get("id")
        if not player_id:
            return None

        # Cas : joueur deja connecte (reconnexion) -> on remplace le websocket
        existing = session.get_player(player_id)
        if existing:
            existing.websocket = websocket
            existing.status = PlayerStatus.connected
            return existing

        role = PlayerRole(join_data.get("role", "student"))
        # Verifie qu'un autre enseignant ACTIF n'est pas deja connecte.
        # Un enseignant deconnecte (perte reseau) peut etre remplace.
        if role == PlayerRole.teacher:
            active_teacher = next(
                (p for p in session.players
                 if p.role == PlayerRole.teacher
                 and p.status != PlayerStatus.disconnected
                 and p.id != player_id),
                None,
            )
            if active_teacher is not None:
                # Un autre enseignant est deja actif -> on force student
                role = PlayerRole.student
            else:
                # Nettoie les anciens enseignants deconnectes (evite
                # l'accumulation apres plusieurs reconnexions)
                session.players = [
                    p for p in session.players
                    if not (p.role == PlayerRole.teacher
                            and p.status == PlayerStatus.disconnected)
                ]

        player = _Player(
            id=player_id,
            name=join_data.get("player_name") or join_data.get("name") or "Joueur",
            role=role,
            websocket=websocket,
        )
        session.players.append(player)
        return player

    def remove_player(self, code: str, player_id: str) -> None:
        """Marque le joueur comme deconnecte (garde son score)."""
        session = self.sessions.get(code)
        if not session:
            return
        player = session.get_player(player_id)
        if player:
            player.status = PlayerStatus.disconnected
            player.websocket = None

    # ─── Broadcast ─────────────────────────────────────────────────
    async def broadcast(self, code: str, message: Dict[str, Any]) -> None:
        """Envoie un message a tous les joueurs connectes."""
        session = self.sessions.get(code)
        if not session:
            return
        # Copie pour eviter mutation pendant iteration
        for player in list(session.players):
            if player.websocket is None:
                continue
            try:
                await player.websocket.send_json(message)
            except Exception:
                # WebSocket fermee : on marque deconnecte
                player.status = PlayerStatus.disconnected
                player.websocket = None

    async def send_to(
        self,
        code: str,
        player_id: str,
        message: Dict[str, Any],
    ) -> None:
        """Envoie un message a un joueur precis."""
        session = self.sessions.get(code)
        if not session:
            return
        player = session.get_player(player_id)
        if player and player.websocket:
            try:
                await player.websocket.send_json(message)
            except Exception:
                player.status = PlayerStatus.disconnected
                player.websocket = None

    async def broadcast_leaderboard(self, code: str) -> None:
        """Diffuse le classement mis a jour a tous les joueurs."""
        session = self.sessions.get(code)
        if not session:
            return
        leaderboard = self.get_leaderboard(code)
        await self.broadcast(code, event(
            "leaderboard_update",
            leaderboard=[p.model_dump(mode="json") for p in leaderboard],
        ))

    # ─── Demarrage / questions ─────────────────────────────────────
    def start_quiz(self, code: str) -> Optional[Dict[str, Any]]:
        """Passe la session en mode live et prepare la 1re question.

        Retourne le message ``quiz_started`` a diffuser, ou None si session
        introuvable / deja lancee.
        """
        session = self.get_session(code)
        if not session or session.status != SessionStatus.waiting:
            return None
        session.status = SessionStatus.live
        session.started_at = utc_now()
        return event(
            "quiz_started",
            session=session.to_out().model_dump(mode="json"),
        )

    def next_question(self, code: str) -> Optional[Dict[str, Any]]:
        """Passe a la question suivante.

        Retourne le message ``new_question`` a diffuser, ou le message
        ``session_ended`` si toutes les questions ont ete diffusees.
        """
        session = self.get_session(code)
        if not session or session.status == SessionStatus.ended:
            return None

        next_index = session.current_index + 1
        if next_index >= len(session.question_ids):
            # Fin naturelle
            results = self._finalize_session(session)
            return event(
                "session_ended",
                results=results.model_dump(mode="json"),
            )

        session.current_index = next_index
        qid = session.question_ids[next_index]
        # Recupere la question snapshot (sans la reponse!)
        snapshot = next(
            (q for q in session.questions_snapshot if q["id"] == qid),
            None,
        )
        if snapshot is None:
            snapshot = {"id": qid, "enonce": "Question introuvable",
                        "type": "ouvert", "choix": None, "explication": None}

        # Reset statut des eleves
        for p in session.students:
            if p.status != PlayerStatus.disconnected:
                p.status = PlayerStatus.connected

        session.current_runtime = _QuestionRuntime(
            question_id=qid,
            started_at=utc_now(),
            time_limit_seconds=session.time_limit_seconds,
        )

        # Question publique (sans reponse ni explication)
        public_question = {
            "id": snapshot["id"],
            "enonce": snapshot["enonce"],
            "type": snapshot["type"],
            "choix": snapshot["choix"],
        }
        return event(
            "new_question",
            question=public_question,
            question_number=next_index + 1,
            total_questions=len(session.question_ids),
            time_limit=session.time_limit_seconds,
            mode=session.mode.value,
        )

    # ─── Reponses ──────────────────────────────────────────────────
    def record_answer(
        self,
        code: str,
        player_id: str,
        question_id: str,
        answer: str,
        time_taken_seconds: float = 0.0,
    ) -> Optional[AnswerResultOut]:
        """Enregistre la reponse d'un eleve, calcule le score.

        Retourne None si session / joueur introuvable ou question non active.
        """
        session = self.get_session(code)
        if not session or session.status != SessionStatus.live:
            return None
        player = session.get_player(player_id)
        if not player or player.role != PlayerRole.student:
            return None
        rt = session.current_runtime
        if not rt or rt.question_id != question_id:
            return None

        # Empêche de repondre deux fois a la meme question
        if player.id in rt.answered_player_ids:
            return None

        # Recupere la reponse attendue
        snapshot = next(
            (q for q in session.questions_snapshot if q["id"] == question_id),
            None,
        )
        expected = snapshot["reponse"] if snapshot else ""
        explanation = snapshot.get("explication") if snapshot else None

        # Comparaison tolérante (minuscules, trim)
        correct = bool(expected) and _normalize(answer) == _normalize(expected)

        # Calcul des points (degre de vitesse)
        points = 0
        if correct:
            if session.mode == SessionMode.homework:
                # Mode devoir : points fixes par question correcte
                points = BASE_POINTS
            else:
                # Mode live : bonus de vitesse
                t = max(0.0, min(time_taken_seconds, float(rt.time_limit_seconds)))
                ratio = 1.0 - (t / max(1.0, float(rt.time_limit_seconds)))
                points = MIN_POINTS + int((BASE_POINTS - MIN_POINTS) * ratio)

        player.score += points
        player.answered_count += 1
        player.last_answer_correct = correct
        player.status = PlayerStatus.answered
        player.answers[question_id] = (answer, correct, time_taken_seconds, points)

        rt.answered_player_ids.add(player.id)
        if correct:
            rt.correct_player_ids.add(player.id)
        rt.answer_times.append(time_taken_seconds)

        return AnswerResultOut(
            correct=correct,
            points_earned=points,
            total_score=player.score,
            question_id=question_id,
            expected_answer=expected if not correct else None,
            explanation=explanation,
        )

    def all_answered(self, code: str) -> bool:
        """True si tous les eleves connectes ont repondu a la question courante."""
        session = self.sessions.get(code)
        if not session or not session.current_runtime:
            return False
        rt = session.current_runtime
        active_students = [
            p for p in session.students
            if p.status != PlayerStatus.disconnected
        ]
        if not active_students:
            return False
        return all(p.id in rt.answered_player_ids for p in active_students)

    def get_question_stats(self, code: str) -> Optional[QuestionStatOut]:
        """Stats de la question courante (ou derniere)."""
        session = self.sessions.get(code)
        if not session or not session.current_runtime:
            return None
        rt = session.current_runtime
        answered = len(rt.answered_player_ids)
        correct = len(rt.correct_player_ids)
        avg_time = (
            sum(rt.answer_times) / len(rt.answer_times)
            if rt.answer_times else 0.0
        )
        success_rate = (correct / answered) if answered else 0.0
        return QuestionStatOut(
            question_id=rt.question_id,
            answered_count=answered,
            correct_count=correct,
            success_rate=success_rate,
            average_time_seconds=avg_time,
        )

    # ─── Classement & resultats ────────────────────────────────────
    def get_leaderboard(self, code: str) -> List[ClassroomPlayerOut]:
        """Classement complet par score decroissant."""
        session = self.sessions.get(code)
        if not session:
            return []
        sorted_players = sorted(
            session.students,
            key=lambda p: (-p.score, p.name.lower()),
        )
        return [p.to_out() for p in sorted_players]

    def _finalize_session(self, session: _Session) -> SessionResultsOut:
        """Termine la session et calcule les resultats finaux."""
        session.status = SessionStatus.ended
        session.ended_at = utc_now()

        leaderboard = self.get_leaderboard(session.code)
        podium = leaderboard[:3]

        # Stats par question
        question_stats: List[QuestionStatOut] = []
        # Pour l'instant on n'a que les stats de la question courante
        # (les autres pourraient etre conservees si besoin en etendant
        # _QuestionRuntime avec un historique)
        rt = session.current_runtime
        if rt:
            question_stats.append(self.get_question_stats(session.code))  # type: ignore[arg-type]

        return SessionResultsOut(
            session_code=session.code,
            status=session.status,
            podium=podium,
            leaderboard=leaderboard,
            question_stats=[qs for qs in question_stats if qs],
            total_players=len(session.students),
            total_questions=len(session.question_ids),
            ended_at=session.ended_at,
        )

    def end_session(self, code: str) -> Optional[SessionResultsOut]:
        """Termine une session avant la fin naturelle (bouton enseignant)."""
        session = self.get_session(code)
        if not session or session.status == SessionStatus.ended:
            return None
        return self._finalize_session(session)

    def get_results(self, code: str) -> Optional[SessionResultsOut]:
        """Resultats finaux d'une session terminee."""
        session = self.get_session(code)
        if not session:
            return None
        if session.status != SessionStatus.ended:
            # On peut quand meme construire un classement partiel
            return SessionResultsOut(
                session_code=code,
                status=session.status,
                podium=self.get_leaderboard(code)[:3],
                leaderboard=self.get_leaderboard(code),
                question_stats=[],
                total_players=len(session.students),
                total_questions=len(session.question_ids),
                ended_at=session.ended_at,
            )
        # Reconstruction depuis l'etat
        return SessionResultsOut(
            session_code=code,
            status=session.status,
            podium=self.get_leaderboard(code)[:3],
            leaderboard=self.get_leaderboard(code),
            question_stats=[self.get_question_stats(code)]
                if session.current_runtime else [],
            total_players=len(session.students),
            total_questions=len(session.question_ids),
            ended_at=session.ended_at,
        )

    def get_status(self, code: str) -> SessionStatusOut:
        """Statut public d'une session."""
        session = self.get_session(code)
        if not session:
            return SessionStatusOut(
                code=code,
                exists=False,
                status=SessionStatus.ended,
                mode=SessionMode.live,
            )
        return session.to_status_out()

    # ─── Nettoyage ─────────────────────────────────────────────────
    def cleanup(self) -> None:
        """Supprime les sessions terminees de plus de 24h (memoire)."""
        cutoff = utc_now() - timedelta(hours=24)
        to_remove = [
            code for code, s in self.sessions.items()
            if s.status == SessionStatus.ended
            and s.ended_at and s.ended_at < cutoff
        ]
        for code in to_remove:
            self.sessions.pop(code, None)
            self._locks.pop(code, None)


# ─── Helpers ─────────────────────────────────────────────────────────
def _normalize(s: str) -> str:
    """Normalise une reponse pour comparaison tolérante."""
    if s is None:
        return ""
    return str(s).strip().lower().replace(" ", "").replace(".", ",")


# ─── Singleton ───────────────────────────────────────────────────────
# Une seule instance partagee par le process FastAPI
classroom_manager = ClassroomManager()
