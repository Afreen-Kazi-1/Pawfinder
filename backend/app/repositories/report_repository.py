import uuid
from typing import Optional, List, Tuple
from sqlalchemy.orm import Session, joinedload
from app.models.pet_report import PetReport
from app.models.pet_image import PetImage
from app.schemas.report import PetReportCreate, PetReportUpdate


class ReportRepository:
    def __init__(self, db: Session):
        self.db = db

    def create(self, user_id: uuid.UUID, report_in: PetReportCreate) -> PetReport:
        report_data = report_in.model_dump()
        report = PetReport(
            user_id=user_id,
            **report_data,
        )
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)
        return report

    def get_by_id(self, report_id: uuid.UUID) -> Optional[PetReport]:
        return (
            self.db.query(PetReport)
            .options(joinedload(PetReport.images), joinedload(PetReport.user))
            .filter(PetReport.id == report_id)
            .first()
        )

    def list_reports(
        self,
        report_type: Optional[str] = None,
        animal_type: Optional[str] = None,
        status: Optional[str] = None,
        breed: Optional[str] = None,
        color: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> Tuple[List[PetReport], int]:
        query = self.db.query(PetReport).options(joinedload(PetReport.images))

        if report_type:
            query = query.filter(PetReport.report_type == report_type.upper())
        if animal_type:
            query = query.filter(PetReport.animal_type.ilike(f"%{animal_type}%"))
        if status:
            query = query.filter(PetReport.status == status)
        if breed:
            query = query.filter(PetReport.breed.ilike(f"%{breed}%"))
        if color:
            query = query.filter(PetReport.color.ilike(f"%{color}%"))

        total = query.count()
        items = query.order_by(PetReport.created_at.desc()).offset(skip).limit(limit).all()
        return items, total

    def get_by_user(
        self,
        user_id: uuid.UUID,
        skip: int = 0,
        limit: int = 50,
        report_type: Optional[str] = None,
        status_filter: Optional[str] = None,
    ) -> Tuple[List[PetReport], int]:
        query = (
            self.db.query(PetReport)
            .options(joinedload(PetReport.images))
            .filter(PetReport.user_id == user_id)
        )
        if report_type:
            query = query.filter(PetReport.report_type == report_type.upper())
        if status_filter:
            # Canonical normalization
            canonical_map = {
                "OPEN": "Open",
                "UNDER_REVIEW": "Under Review",
                "UNDER REVIEW": "Under Review",
                "RESOLVED": "Reunited / Resolved",
                "REUNITED / RESOLVED": "Reunited / Resolved",
                "CLOSED": "Closed",
            }
            norm_status = canonical_map.get(status_filter.strip().upper(), status_filter.strip().title())
            query = query.filter(PetReport.status == norm_status)

        total = query.count()
        items = query.order_by(PetReport.created_at.desc()).offset(skip).limit(limit).all()
        return items, total

    def update(self, report: PetReport, update_in: PetReportUpdate) -> PetReport:
        update_data = update_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(report, field, value)
        self.db.commit()
        self.db.refresh(report)
        return report

    def update_status(self, report: PetReport, status: str) -> PetReport:
        report.status = status
        self.db.commit()
        self.db.refresh(report)
        return report

    def delete(self, report: PetReport) -> None:
        self.db.delete(report)
        self.db.commit()

    # Pet Images
    def add_image(self, report_id: uuid.UUID, image_url: str, storage_path: str) -> PetImage:
        image = PetImage(
            report_id=report_id,
            image_url=image_url,
            storage_path=storage_path,
        )
        self.db.add(image)
        self.db.commit()
        self.db.refresh(image)
        return image

    def get_image_by_id(self, image_id: uuid.UUID) -> Optional[PetImage]:
        return (
            self.db.query(PetImage)
            .options(joinedload(PetImage.report))
            .filter(PetImage.id == image_id)
            .first()
        )

    def delete_image(self, image: PetImage) -> None:
        self.db.delete(image)
        self.db.commit()

    def get_images_by_report(self, report_id: uuid.UUID) -> List[PetImage]:
        return (
            self.db.query(PetImage)
            .filter(PetImage.report_id == report_id)
            .order_by(PetImage.uploaded_at.asc())
            .all()
        )

