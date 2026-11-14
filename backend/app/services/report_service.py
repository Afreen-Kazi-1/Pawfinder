import uuid
from typing import Optional, List, Tuple
from fastapi import HTTPException, status, UploadFile
from sqlalchemy.orm import Session

from app.models.pet_report import PetReport
from app.models.pet_image import PetImage
from app.models.user import User
from app.models.notification import Notification
from app.repositories.report_repository import ReportRepository
from app.schemas.report import PetReportCreate, PetReportUpdate
from app.services.storage_service import StorageService, storage_service


class ReportService:
    def __init__(self, db: Session, storage: StorageService = storage_service):
        self.db = db
        self.repo = ReportRepository(db)
        self.storage = storage

    def create_report(self, user_id: uuid.UUID, report_in: PetReportCreate) -> PetReport:
        return self.repo.create(user_id=user_id, report_in=report_in)

    def get_report(self, report_id: uuid.UUID) -> PetReport:
        report = self.repo.get_by_id(report_id)
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet report not found.",
            )
        return report

    def list_reports(
        self,
        report_type: Optional[str] = None,
        animal_type: Optional[str] = None,
        status_filter: Optional[str] = None,
        breed: Optional[str] = None,
        color: Optional[str] = None,
        page: int = 1,
        size: int = 20,
    ) -> Tuple[List[PetReport], int]:
        skip = (page - 1) * size
        return self.repo.list_reports(
            report_type=report_type,
            animal_type=animal_type,
            status=status_filter,
            breed=breed,
            color=color,
            skip=skip,
            limit=size,
        )

    def get_user_reports(
        self,
        user_id: uuid.UUID,
        page: int = 1,
        size: int = 50,
        report_type: Optional[str] = None,
        status_filter: Optional[str] = None,
    ) -> Tuple[List[PetReport], int]:
        skip = (page - 1) * size
        return self.repo.get_by_user(
            user_id=user_id,
            skip=skip,
            limit=size,
            report_type=report_type,
            status_filter=status_filter,
        )

    def update_report(
        self,
        report_id: uuid.UUID,
        update_in: PetReportUpdate,
        current_user: User,
    ) -> PetReport:
        report = self.get_report(report_id)
        self._check_ownership(report, current_user)
        return self.repo.update(report, update_in)

    def update_status(
        self,
        report_id: uuid.UUID,
        new_status: str,
        current_user: User,
    ) -> PetReport:
        report = self.get_report(report_id)
        self._check_ownership(report, current_user)
        updated_report = self.repo.update_status(report, new_status)

        # Generate notification for report owner
        pet_title = updated_report.pet_name or f"{updated_report.animal_type}"
        is_resolved = new_status.lower() in ["resolved", "reunited / resolved"]
        notif_type = "resolved" if is_resolved else "status_update"
        notif_title = "Report Resolved!" if is_resolved else "Report Status Updated"
        notif_msg = (
            f"Your report for '{pet_title}' has been marked as resolved."
            if is_resolved
            else f"Your report for '{pet_title}' status was updated to '{new_status}'."
        )

        notif = Notification(
            user_id=updated_report.user_id,
            title=notif_title,
            message=notif_msg,
            notification_type=notif_type,
            related_entity_id=updated_report.id,
            is_read=False,
        )
        self.db.add(notif)
        self.db.commit()

        return updated_report

    def delete_report(
        self,
        report_id: uuid.UUID,
        current_user: User,
    ) -> None:
        report = self.get_report(report_id)
        self._check_ownership(report, current_user)

        # Clean up images from storage
        for img in report.images:
            try:
                self.storage.delete_image(img.storage_path)
            except Exception:
                pass

        self.repo.delete(report)

    # Image handling
    def upload_report_images(
        self,
        report_id: uuid.UUID,
        files: List[UploadFile],
        current_user: User,
    ) -> List[PetImage]:
        report = self.get_report(report_id)
        self._check_ownership(report, current_user)

        created_images: List[PetImage] = []
        for file in files:
            file_bytes = file.file.read()
            content_type = file.content_type or "image/jpeg"
            filename = file.filename or "pet_image.jpg"

            image_url, storage_path = self.storage.upload_image(
                report_id=report.id,
                filename=filename,
                file_bytes=file_bytes,
                content_type=content_type,
            )

            pet_image = self.repo.add_image(
                report_id=report.id,
                image_url=image_url,
                storage_path=storage_path,
            )
            created_images.append(pet_image)

        return created_images

    def get_report_images(self, report_id: uuid.UUID) -> List[PetImage]:
        self.get_report(report_id)
        return self.repo.get_images_by_report(report_id)

    def delete_image(self, image_id: uuid.UUID, current_user: User) -> None:
        image = self.repo.get_image_by_id(image_id)
        if not image:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet image not found.",
            )

        self._check_ownership(image.report, current_user)

        try:
            self.storage.delete_image(image.storage_path)
        except Exception:
            pass

        self.repo.delete_image(image)

    def _check_ownership(self, report: PetReport, user: User) -> None:
        if report.user_id != user.id and user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to modify or delete this report.",
            )

