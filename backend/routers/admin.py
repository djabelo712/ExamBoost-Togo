r"""routers/admin.py — Endpoints admin pour la gestion du contenu.

Toutes les routes sont préfixées par ``/admin`` (côté main.py) et
nécessitent une authentification admin (JWT + flag ``is_admin=True``).
Elles exposent le CRUD complet sur les questions, l'import/export batch
et les statistiques contenu.

Branchement dans main.py (documenté dans backend/README.md) :

    from routers import admin
    app.include_router(admin.router, prefix="/admin", tags=["admin"])

Le module utilise la dépendance ``get_admin_user`` déjà définie dans
``routers/auth.py`` (qui appelle ``get_current_user`` puis vérifie
``user.is_admin``).
"""

from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from database import get_db
from models.admin_schemas import (
    AdminActionLog,
    AdminStats,
    BatchResult,
    ExportResult,
    QuestionBatchExport,
    QuestionBatchImport,
    QuestionCreate,
    QuestionOut,
    QuestionUpdate,
)
from models.db_models import User
from routers.auth import get_admin_user
from services.admin_service import AdminService


router = APIRouter()


# ─── Helper : conversion ORM -> schema ───────────────────────────────
def _to_out(q) -> QuestionOut:
    """Convertit une Question ORM en schema QuestionOut."""
    return QuestionOut(
        id=q.id,
        enonce=q.enonce,
        reponse=q.reponse,
        explication=q.explication,
        matiere=q.matiere,
        chapitre=q.chapitre,
        competence_id=q.competence_id,
        examen=q.examen,
        serie=q.serie,
        annee=q.annee,
        type=q.type,
        choix=q.choix,
        points=q.points,
        irt_a=q.irt_a,
        irt_b=q.irt_b,
        irt_c=q.irt_c,
        irt_calibrated=q.irt_calibrated,
        created_at=q.created_at,
    )


# ─── 1. GET /admin/questions — Liste paginee avec filtres ───────────
@router.get(
    "/questions",
    response_model=Dict[str, Any],
    summary="Liste paginee de questions (admin)",
)
async def list_questions(
    matiere: Optional[str] = Query(None),
    examen: Optional[str] = Query(None),
    serie: Optional[str] = Query(None),
    annee: Optional[int] = Query(None),
    recherche: Optional[str] = Query(
        None, description="Recherche full-text dans l'enonce"
    ),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Liste les questions avec filtres optionnels et pagination.

    Reserve aux administrateurs.
    """
    service = AdminService(db)
    result = await service.list_questions(
        matiere=matiere,
        examen=examen,
        serie=serie,
        annee=annee,
        recherche=recherche,
        limit=limit,
        offset=offset,
    )
    return {
        "items": [_to_out(q) for q in result["items"]],
        "total": result["total"],
        "limit": result["limit"],
        "offset": result["offset"],
    }


# ─── 2. GET /admin/questions/{question_id} — Detail ─────────────────
@router.get(
    "/questions/{question_id}",
    response_model=QuestionOut,
    summary="Detail d'une question (admin)",
)
async def get_question(
    question_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Recupere une question par son ID."""
    from models.db_models import Question

    q = db.get(Question, question_id)
    if q is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Question {question_id} introuvable",
        )
    return _to_out(q)


# ─── 3. POST /admin/questions — Creation ────────────────────────────
@router.post(
    "/questions",
    response_model=QuestionOut,
    status_code=status.HTTP_201_CREATED,
    summary="Cree une nouvelle question (admin)",
)
async def create_question(
    question: QuestionCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Cree une nouvelle question dans la banque.

    Le corps doit contenir un ID unique respectant la convention
    ``TG-<EXAMEN>-<MATIERE>-<ANNEE>-Q<NN>``.
    """
    service = AdminService(db)
    try:
        q = await service.create_question(question, admin.id)
        return _to_out(q)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


# ─── 4. PUT /admin/questions/{question_id} — Update ─────────────────
@router.put(
    "/questions/{question_id}",
    response_model=QuestionOut,
    summary="Met a jour une question (admin)",
)
async def update_question(
    question_id: str,
    update: QuestionUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Met a jour partiellement une question (PATCH-like)."""
    service = AdminService(db)
    try:
        q = await service.update_question(question_id, update, admin.id)
        return _to_out(q)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


# ─── 5. DELETE /admin/questions/{question_id} — Suppression ─────────
@router.delete(
    "/questions/{question_id}",
    response_model=Dict[str, str],
    summary="Supprime une question (admin)",
)
async def delete_question(
    question_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Supprime une question de la banque (irreversible)."""
    service = AdminService(db)
    try:
        await service.delete_question(question_id, admin.id)
        return {"message": f"Question {question_id} supprimee"}
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        )


# ─── 6. POST /admin/questions/batch-import ──────────────────────────
@router.post(
    "/questions/batch-import",
    response_model=BatchResult,
    summary="Import batch de questions (admin)",
)
async def batch_import(
    batch: QuestionBatchImport,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Importe un lot de questions (JSON).

    Si ``overwrite_existing=True``, les questions de meme ID sont
    ecrasees ; sinon elles sont ignorees (skipped).
    """
    service = AdminService(db)
    results = await service.batch_import(
        batch.questions, admin.id, batch.overwrite_existing
    )
    return results


# ─── 7. POST /admin/questions/batch-export ──────────────────────────
@router.post(
    "/questions/batch-export",
    response_model=ExportResult,
    summary="Export batch de questions (admin)",
)
async def batch_export(
    export: QuestionBatchExport,
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Exporte les questions filtrees en JSON ou CSV.

    Le contenu est retourne inline dans la reponse (clé ``content``).
    Pour des volumes importants (> 10k), preferer le script CLI
    ``scripts/export_questions.py`` qui ecrit directement dans un fichier.
    """
    service = AdminService(db)
    try:
        result = await service.batch_export(export.format, export.filters)
        # Log de l'action export
        from services.admin_service import AdminActionLog
        from datetime import datetime, timezone
        import uuid as _uuid

        db.add(
            AdminActionLog(
                id=_uuid.uuid4().hex,
                admin_id=admin.id,
                action="export",
                question_id=None,
                timestamp=datetime.now(timezone.utc),
                details={
                    "format": export.format,
                    "filters": export.filters,
                    "count": result["count"],
                },
            )
        )
        db.commit()
        return ExportResult(**result)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        )


# ─── 8. POST /admin/questions/upload-json ───────────────────────────
@router.post(
    "/questions/upload-json",
    response_model=BatchResult,
    summary="Upload d'un fichier JSON de questions (admin)",
)
async def upload_json(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Upload d'un fichier JSON contenant une liste de questions.

    Le fichier doit etre un tableau JSON d'objets respectant le schema
    ``QuestionCreate``. L'import se fait sans ecrasement (overwrite=False).
    """
    if not file.filename or not file.filename.lower().endswith(".json"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le fichier doit avoir l'extension .json",
        )

    try:
        raw = await file.read()
        data = json.loads(raw.decode("utf-8"))
    except json.JSONDecodeError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"JSON invalide: {exc}",
        )

    if not isinstance(data, list):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le fichier doit contenir un tableau JSON de questions",
        )

    # Conversion en QuestionCreate avec validation Pydantic
    questions: List[QuestionCreate] = []
    parse_errors: List[Dict[str, Any]] = []
    for idx, item in enumerate(data):
        try:
            questions.append(QuestionCreate(**item))
        except Exception as exc:  # noqa: BLE001
            parse_errors.append(
                {"index": idx, "id": item.get("id"), "error": str(exc)}
            )

    service = AdminService(db)
    results = await service.batch_import(questions, admin.id, overwrite=False)
    # On merge les erreurs de parsing avec les erreurs d'import
    results["errors"] = parse_errors + results.get("errors", [])
    return results


# ─── 9. GET /admin/stats — Stats contenu ────────────────────────────
@router.get(
    "/stats",
    response_model=AdminStats,
    summary="Statistiques contenu (admin)",
)
async def get_stats(
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Retourne les statistiques globales du contenu :
    total, repartition par matiere/examen/serie/annee/type,
    taux de calibration IRT, questions sans explication, doublons potentiels.
    """
    service = AdminService(db)
    return await service.get_stats()


# ─── 10. GET /admin/logs — Logs actions ─────────────────────────────
@router.get(
    "/logs",
    response_model=List[AdminActionLog],
    summary="Logs des actions admin",
)
async def get_logs(
    limit: int = Query(50, ge=1, le=500),
    db: Session = Depends(get_db),
    admin: User = Depends(get_admin_user),
):
    """Retourne les derniers logs d'actions admin (creees / updates /
    deletes / imports / exports)."""
    service = AdminService(db)
    return await service.get_logs(limit=limit)
