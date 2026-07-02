"""routers/classroom.py — Module Classe Temps Reel (Kahoot-like + devoir).

Expose :
  - WebSocket : ``/classroom/{session_code}`` — canal temps reel
  - POST      : ``/classroom/create``          — cree une session
  - GET       : ``/classroom/{code}/status``   — statut public
  - GET       : ``/classroom/{code}/results``  — resultats finaux
  - POST      : ``/classroom/{code}/end``      — termine la session (REST)
  - POST      : ``/classroom/cleanup``         — nettoyage memoire

Le WebSocket suit un protocole simple :
  1. Client envoie ``{"type": "join", "player_id", "player_name", "role"}``
  2. Server confirme via ``{"type": "joined", "session": ..., "me": ...}``
  3. Ensuite, messages entrants : ``answer``, ``next_question``,
     ``force_next``, ``start_quiz``, ``end_session``
  4. Messages sortants : ``player_joined``, ``player_left``,
     ``quiz_started``, ``new_question``, ``answer_confirmed``,
     ``leaderboard_update``, ``all_answered``, ``session_ended``,
     ``error``

Aucune persistence DB : tout est en memoire dans ``ClassroomManager``
(singleton). Pour multi-instance, brancher Redis pub/sub.
"""

from __future__ import annotations

from typing import Any, Dict, List

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from models.classroom_models import (
    AnswerResultOut,
    ClassroomPlayerOut,
    ClassroomSessionOut,
    JoinRequest,
    PlayerRole,
    SessionCreateRequest,
    SessionResultsOut,
    SessionStatusOut,
    event,
)
from services.classroom_manager import classroom_manager


router = APIRouter()


# ─── WebSocket ───────────────────────────────────────────────────────
@router.websocket("/classroom/{session_code}")
async def classroom_websocket(websocket: WebSocket, session_code: str):
    """WebSocket pour session classe temps reel.

    Le 1er message doit etre un ``join``. Ensuite, le serveur broadcast
    les evenements (questions, leaderboard, etc.).
    """
    await websocket.accept()

    # 1. Reception du join
    try:
        join_data = await websocket.receive_json()
    except Exception:
        await websocket.close(code=1008)
        return

    if join_data.get("type") != "join":
        await websocket.send_json(event(
            "error",
            message="Premier message doit etre de type 'join'",
        ))
        await websocket.close(code=1008)
        return

    # 2. Ajout du joueur
    player = classroom_manager.add_player(session_code, join_data, websocket)
    if not player:
        await websocket.send_json(event(
            "error",
            message="Session introuvable ou terminee",
        ))
        await websocket.close()
        return

    # 3. Confirmation au joueur + broadcast aux autres
    session = classroom_manager.get_session(session_code)
    session_out = session.to_out() if session else None
    await websocket.send_json(event(
        "joined",
        session=session_out.model_dump(mode="json") if session_out else None,
        player=player.to_out().model_dump(mode="json"),
    ))

    # Diffuse la liste des joueurs mise a jour
    await classroom_manager.broadcast(session_code, event(
        "player_joined",
        player=player.to_out().model_dump(mode="json"),
        players_count=session.players_count if session else 0,
        leaderboard=[
            p.model_dump(mode="json")
            for p in classroom_manager.get_leaderboard(session_code)
        ],
    ))

    # 4. Boucle principale
    try:
        while True:
            data = await websocket.receive_json()
            msg_type = data.get("type")

            if msg_type == "answer":
                await _handle_answer(session_code, player.id, data)

            elif msg_type == "next_question":
                if player.role == PlayerRole.teacher:
                    await _handle_next_question(session_code)

            elif msg_type == "force_next":
                if player.role == PlayerRole.teacher:
                    await _handle_next_question(session_code)

            elif msg_type == "start_quiz":
                if player.role == PlayerRole.teacher:
                    await _handle_start_quiz(session_code)

            elif msg_type == "end_session":
                if player.role == PlayerRole.teacher:
                    await _handle_end_session(session_code)

            else:
                await websocket.send_json(event(
                    "error",
                    message=f"Type de message inconnu: {msg_type}",
                ))

    except WebSocketDisconnect:
        classroom_manager.remove_player(session_code, player.id)
        await classroom_manager.broadcast(session_code, event(
            "player_left",
            player_id=player.id,
            players_count=(
                session.players_count
                if (session := classroom_manager.get_session(session_code))
                else 0
            ),
        ))


# ─── Handlers WebSocket ──────────────────────────────────────────────
async def _handle_answer(code: str, player_id: str, data: Dict[str, Any]) -> None:
    """Traite une reponse eleve : enregistre + confirme + broadcast leaderboard."""
    question_id = data.get("question_id")
    answer = data.get("answer", "")
    time_taken = float(data.get("time_taken_seconds", 0.0))

    result = classroom_manager.record_answer(
        code, player_id, question_id, answer, time_taken,
    )
    if not result:
        await classroom_manager.send_to(code, player_id, event(
            "error",
            message="Impossible d'enregistrer la reponse (session fermee, "
                    "question non active ou deja repondu)",
        ))
        return

    # Confirme a l'eleve
    await classroom_manager.send_to(code, player_id, event(
        "answer_confirmed",
        correct=result.correct,
        points_earned=result.points_earned,
        total_score=result.total_score,
        question_id=result.question_id,
        expected_answer=result.expected_answer,
        explanation=result.explanation,
    ))

    # Diffuse le classement mis a jour
    await classroom_manager.broadcast_leaderboard(code)

    # Si tous ont repondu -> broadcast all_answered (l'enseignant peut
    # alors declencher la question suivante)
    if classroom_manager.all_answered(code):
        stats = classroom_manager.get_question_stats(code)
        await classroom_manager.broadcast(code, event(
            "all_answered",
            stats=stats.model_dump(mode="json") if stats else None,
        ))
        # En mode devoir, on n'attend pas : on passe directement a la
        # suivante apres 2s (decalage pour laisser voir le resultat)
        session = classroom_manager.get_session(code)
        if session and session.mode.value == "homework":
            # On ne passe PAS automatiquement en mode homework : chaque
            # eleve avance a son rythme. L'enseignant n'existe pas
            # vraiment dans ce mode. On laisse l'eleve voir son resultat.
            pass


async def _handle_start_quiz(code: str) -> None:
    """Lance le quiz : passe en mode live, broadcast quiz_started."""
    msg = classroom_manager.start_quiz(code)
    if msg:
        await classroom_manager.broadcast(code, msg)
        # Envoie la 1re question immediatement
        await _handle_next_question(code)


async def _handle_next_question(code: str) -> None:
    """Diffuse la question suivante."""
    msg = classroom_manager.next_question(code)
    if not msg:
        return
    await classroom_manager.broadcast(code, msg)


async def _handle_end_session(code: str) -> None:
    """Termine la session et diffuse les resultats."""
    results = classroom_manager.end_session(code)
    if not results:
        return
    await classroom_manager.broadcast(code, event(
        "session_ended",
        results=results.model_dump(mode="json"),
    ))


# ─── Endpoints REST ──────────────────────────────────────────────────
@router.post(
    "/classroom/create",
    response_model=Dict[str, Any],
    summary="Cree une session classe et retourne le code a 6 chiffres",
)
async def create_session(payload: SessionCreateRequest) -> Dict[str, Any]:
    """Cree une session (live ou devoir) et retourne le code + ws_url."""
    code = classroom_manager.create_session(payload)
    return {
        "session_code": code,
        "ws_url": f"/classroom/{code}",
        "mode": payload.mode.value,
        "question_count": len(payload.question_ids),
    }


@router.get(
    "/classroom/{code}/status",
    response_model=SessionStatusOut,
    summary="Statut public d'une session classe",
)
async def get_status(code: str) -> SessionStatusOut:
    """Retourne le statut (sans exposer les joueurs ni les reponses)."""
    return classroom_manager.get_status(code)


@router.get(
    "/classroom/{code}/results",
    response_model=SessionResultsOut,
    summary="Resultats finaux d'une session classe",
)
async def get_results(code: str) -> SessionResultsOut:
    """Retourne le classement complet + stats par question.

    Disponible meme si la session n'est pas encore terminee (classement
    partiel). Pour les resultats finaux, attendre status == 'ended'.
    """
    results = classroom_manager.get_results(code)
    if not results:
        # Retourne un resultat vide (session introuvable)
        return SessionResultsOut(
            session_code=code,
            status="ended",
        )
    return results


@router.post(
    "/classroom/{code}/end",
    response_model=SessionResultsOut,
    summary="Termine une session classe (REST)",
)
async def end_session(code: str) -> SessionResultsOut:
    """Termine une session via REST (alternative au message WS end_session)."""
    results = classroom_manager.end_session(code)
    if not results:
        # Peut-etre deja terminee : on renvoie le classement actuel
        results = classroom_manager.get_results(code)
        if not results:
            return SessionResultsOut(session_code=code, status="ended")
    # Diffuse aussi via WS aux clients connectes
    await classroom_manager.broadcast(code, event(
        "session_ended",
        results=results.model_dump(mode="json"),
    ))
    return results


@router.post(
    "/classroom/cleanup",
    summary="Nettoie les sessions terminees de plus de 24h",
)
async def cleanup_sessions() -> Dict[str, Any]:
    """Nettoyage memoire (a appeler via cron ou manuellement)."""
    classroom_manager.cleanup()
    return {
        "active_sessions": len(classroom_manager.sessions),
        "sessions": list(classroom_manager.sessions.keys()),
    }


@router.get(
    "/classroom",
    summary="Liste les codes de sessions actives (debug)",
)
async def list_sessions() -> Dict[str, Any]:
    """Liste les sessions actives (debug/admin uniquement)."""
    return {
        "count": len(classroom_manager.sessions),
        "sessions": [
            classroom_manager.get_status(code).model_dump(mode="json")
            for code in classroom_manager.sessions
        ],
    }
