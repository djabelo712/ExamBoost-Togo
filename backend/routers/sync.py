"""routers/sync.py — Endpoints de synchronisation cloud offline-first.

L'app mobile pousse ses actions (reponses SRS, maj BKT, simulations, ...)
vers ces endpoints. Le serveur applique la logique metier (SM-2, BKT, etc.)
avec resolution de conflits CRDT-like et idempotence via ``action_id``.

Endpoints :
    POST /sync/action    : recoit une action unique
    POST /sync/batch     : recoit un batch (max 50 actions)
    GET  /sync/status    : statut de sync pour l'utilisateur courant
    GET  /sync/pull      : recupere les mises a jour serveur depuis ``since``
"""

from __future__ import annotations

from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from database import get_db
from models.db_models import User
from routers.auth import get_current_user
from services import sync_service


router = APIRouter()


# ─── POST /sync/action ──────────────────────────────────────────────
@router.post(
    "/action",
    response_model=sync_service.SyncActionResponse,
    status_code=status.HTTP_200_OK,
    summary="Recoit une action depuis l'app mobile",
    tags=["sync"],
)
def receive_action(
    payload: sync_service.SyncActionRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Recoit une action et l'applique a l'etat serveur.

    L'action est identifiee par ``action_id`` (UUID v4 cote client) qui sert
    de cle d'idempotence : si la meme action est re-envoyee (retry reseau),
    le serveur la reconnait et renvoie ``applied=False`` sans la rejouer.

    Types d'actions supportees :
        - ``reviewAnswer``     : applique SM-2 + BKT + insert Response
        - ``bktUpdate``        : maj BKT isolee
        - ``simulationResult`` : insert Simulation
        - ``userProgress``     : maj compteurs (max monotone)
        - ``badgeUnlock``      : enregistre un badge debloque (placeholder)
    """
    result = sync_service.apply_action(db, current_user, payload)
    db.commit()

    return sync_service.SyncActionResponse(
        action_id=payload.action_id,
        applied=result.applied,
        result=result.result,
        conflict=result.conflict,
        error=result.error,
    )


# ─── POST /sync/batch ───────────────────────────────────────────────
@router.post(
    "/batch",
    response_model=sync_service.SyncBatchResponse,
    status_code=status.HTTP_200_OK,
    summary="Recoit un batch d'actions (max 50)",
    tags=["sync"],
)
def receive_batch(
    batch: sync_service.SyncBatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Recoit un batch d'actions et les applique une par une.

    Le batch est transactionnel cote DB : si une action echoue, on continue
    les autres (pas de rollback global) mais on signale les echecs dans la
    reponse. L'idempotence est garantie par ``action_id``.
    """
    if len(batch.actions) > 50:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Un batch ne peut pas depasser 50 actions",
        )

    results: List[sync_service.SyncActionResponse] = []
    applied = 0
    skipped = 0
    failed = 0

    for action in batch.actions:
        try:
            res = sync_service.apply_action(db, current_user, action)
            if res.error is not None:
                failed += 1
            elif res.applied:
                applied += 1
            else:
                skipped += 1

            results.append(
                sync_service.SyncActionResponse(
                    action_id=action.action_id,
                    applied=res.applied,
                    result=res.result,
                    conflict=res.conflict,
                    error=res.error,
                )
            )
        except Exception as e:
            failed += 1
            results.append(
                sync_service.SyncActionResponse(
                    action_id=action.action_id,
                    applied=False,
                    error=str(e),
                )
            )

    db.commit()

    return sync_service.SyncBatchResponse(
        total=len(batch.actions),
        applied=applied,
        skipped=skipped,
        failed=failed,
        results=results,
    )


# ─── GET /sync/status ───────────────────────────────────────────────
@router.get(
    "/status",
    response_model=sync_service.SyncStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Statut de sync pour l'utilisateur courant",
    tags=["sync"],
)
def get_sync_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Retourne le timestamp de la derniere action appliquee, etc.

    L'app peut appeler cet endpoint au demarrage pour :
        - verifier que le serveur est joinable
        - afficher un indicateur de "derniere sync cote serveur"
        - detecter un decalage (actions appliquees par un autre device)
    """
    return sync_service.get_sync_status(db, current_user)


# ─── GET /sync/pull ─────────────────────────────────────────────────
@router.get(
    "/pull",
    response_model=sync_service.PullUpdatesResponse,
    status_code=status.HTTP_200_OK,
    summary="Recupere les mises a jour serveur depuis une date",
    tags=["sync"],
)
def pull_updates(
    since: datetime = Query(
        ...,
        description="Date ISO8601 depuis laquelle recuperer les maj "
        "(ex: 2026-06-01T00:00:00Z)",
    ),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Recupere les mises a jour serveur depuis ``since``.

    L'app appelle cet endpoint periodiquement (ou apres login) pour :
        - Recuperer les ReviewCard modifiees par un autre device
        - Recuperer l'etat BKT global (au cas ou le serveur aurait corrige)
        - Recuperer les compteurs utilisateur
        - (Future) recuperer les nouveaux parametres IRT calibres et les
          nouvelles questions ajoutees par les admins

    Cote client, le [ConflictResolver] est applique pour merger ces donnees
    avec l'etat local (CRDT Last-Write-Wins).
    """
    return sync_service.pull_updates(db, current_user, since)


# ─── Healthcheck interne (pour debug) ───────────────────────────────
@router.get(
    "/health",
    status_code=status.HTTP_200_OK,
    summary="Healthcheck du module sync",
    tags=["sync"],
)
def sync_health():
    """Verifie que les tables d'idempotence existent."""
    try:
        sync_service.ensure_sync_tables()
        return {"status": "ok", "tables": "ready"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}
