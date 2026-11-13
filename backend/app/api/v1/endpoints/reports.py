import uuid
from typing import Optional, List
from fastapi import APIRouter, Depends, Query, status, UploadFile, File
from sqlalchemy.orm import Session

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.report import (
    PetReportCreate,
    PetReportUpdate,
    PetReportStatusUpdate,
    PetReportResponse,
    PetReportListResponse,
)
from app.schemas.image import PetImageResponse
from app.services.report_service import ReportService

router = APIRouter()


@router.post(
    "",
    response_model=PetReportResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a lost or found pet report",
)
def create_report(
    report_in: PetReportCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReportService(db)
    return service.create_report(user_id=current_user.id, report_in=report_in)


@router.get(
    "",
    response_model=PetReportListResponse,
    summary="Retrieve pet reports with optional search and filters",
)
def list_reports(
    report_type: Optional[str] = Query(None, description="LOST or FOUND"),
    animal_type: Optional[str] = Query(None, description="Dog, Cat, etc."),
    status: Optional[str] = Query(None, description="Open, Under Review, etc."),
    breed: Optional[str] = Query(None, description="Breed name"),
    color: Optional[str] = Query(None, description="Pet color"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
):
    service = ReportService(db)
    items, total = service.list_reports(
        report_type=report_type,
        animal_type=animal_type,
        status_filter=status,
        breed=breed,
        color=color,
        page=page,
        size=size,
    )
    return PetReportListResponse(items=items, total=total, page=page, size=size)


@router.get(
    "/mine",
    response_model=PetReportListResponse,
    summary="Retrieve current user's submitted reports",
)
def get_my_reports(
    page: int = Query(1, ge=1),
    size: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReportService(db)
    items, total = service.get_user_reports(user_id=current_user.id, page=page, size=size)
    return PetReportListResponse(items=items, total=total, page=page, size=size)


@router.get(
    "/{id}",
    response_model=PetReportResponse,
    summary="Retrieve an individual pet report by ID",
)
def get_report(
    id: uuid.UUID,
    db: Session = Depends(get_db),
):
    service = ReportService(db)
    return service.get_report(id)


@router.put(
    "/{id}",
    response_model=PetReportResponse,
    summary="Update a pet report (owner or admin only)",
)
def update_report(
    id: uuid.UUID,
    update_in: PetReportUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReportService(db)
    return service.update_report(report_id=id, update_in=update_in, current_user=current_user)


@router.patch(
    "/{id}/status",
    response_model=PetReportResponse,
    summary="Update report status (owner or admin only)",
)
def update_report_status(
    id: uuid.UUID,
    status_in: PetReportStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReportService(db)
    return service.update_status(report_id=id, new_status=status_in.status, current_user=current_user)


@router.delete(
    "/{id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a pet report (owner or admin only)",
)
def delete_report(
    id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReportService(db)
    service.delete_report(report_id=id, current_user=current_user)
    return None


# Image upload & retrieval on report resource
@router.post(
    "/{id}/images",
    response_model=List[PetImageResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Upload one or more images for a report (owner or admin only)",
)
def upload_report_images(
    id: uuid.UUID,
    files: List[UploadFile] = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    service = ReportService(db)
    return service.upload_report_images(report_id=id, files=files, current_user=current_user)


@router.get(
    "/{id}/images",
    response_model=List[PetImageResponse],
    summary="Retrieve all images associated with a report",
)
def get_report_images(
    id: uuid.UUID,
    db: Session = Depends(get_db),
):
    service = ReportService(db)
    return service.get_report_images(report_id=id)

