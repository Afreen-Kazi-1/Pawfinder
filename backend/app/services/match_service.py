import uuid
from typing import List, Optional, Tuple
from sqlalchemy.orm import Session, joinedload
from fastapi import HTTPException, status

from app.models.pet_report import PetReport
from app.models.match import Match
from app.models.user import User
from app.services.matching_engine import MatchingEngine

# Permitted state transitions for the Match lifecycle
PERMITTED_TRANSITIONS = {
    "Suggested": {"Relevant", "Dismissed", "Resolved"},
    "Relevant": {"Dismissed", "Resolved"},
    "Dismissed": {"Relevant", "Suggested"},
    "Resolved": set(),  # Terminal state
}


class MatchService:
    def __init__(self, db: Session, engine: Optional[MatchingEngine] = None):
        self.db = db
        self.engine = engine or MatchingEngine()

    def run_matching_for_report(self, report_id: uuid.UUID) -> List[Match]:
        """Runs the matching engine for a given report (LOST or FOUND).
        Compares against active counterparts in the database.
        Persists qualifying matches (>= possible threshold) and updates existing match records.
        """
        report = self.db.query(PetReport).filter(PetReport.id == report_id).first()
        if not report:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Pet report not found.",
            )

        # Do not generate active recommendations for closed or resolved reports
        if report.status in {"Closed", "Resolved", "Reunited / Resolved"}:
            return []

        # Find target reports: opposite report_type and active
        target_type = "FOUND" if report.report_type.upper() == "LOST" else "LOST"
        candidates = (
            self.db.query(PetReport)
            .filter(
                PetReport.report_type == target_type,
                PetReport.status.notin_(["Closed", "Resolved", "Reunited / Resolved"]),
                PetReport.id != report.id,
                PetReport.animal_type.ilike(report.animal_type),
            )
            .all()
        )

        persisted_matches: List[Match] = []

        for candidate in candidates:
            lost_rep = report if report.report_type.upper() == "LOST" else candidate
            found_rep = candidate if report.report_type.upper() == "LOST" else report

            eval_res = self.engine.evaluate(lost_rep, found_rep)

            if eval_res["is_match"]:
                existing_match = (
                    self.db.query(Match)
                    .filter(
                        Match.lost_report_id == lost_rep.id,
                        Match.found_report_id == found_rep.id,
                    )
                    .first()
                )

                if existing_match:
                    existing_match.match_score = eval_res["match_score"]
                    existing_match.match_category = eval_res["match_category"]
                    existing_match.match_reasons = eval_res["reasons"]
                    self.db.add(existing_match)
                    persisted_matches.append(existing_match)
                else:
                    new_match = Match(
                        lost_report_id=lost_rep.id,
                        found_report_id=found_rep.id,
                        match_score=eval_res["match_score"],
                        match_category=eval_res["match_category"],
                        match_reasons=eval_res["reasons"],
                        status="Suggested",
                    )
                    self.db.add(new_match)
                    persisted_matches.append(new_match)

        self.db.commit()
        for m in persisted_matches:
            self.db.refresh(m)

        persisted_matches.sort(key=lambda m: m.match_score, reverse=True)
        return persisted_matches

    def get_user_matches(
        self,
        current_user: User,
        status_filter: Optional[str] = None,
        page: int = 1,
        size: int = 20,
    ) -> Tuple[List[Match], int]:
        """Returns matches where either the lost_report or found_report belongs to current_user.
        Excludes actionable matches whose associated reports are Closed or Reunited / Resolved.
        """
        # User's report IDs
        user_report_ids = [
            r.id
            for r in self.db.query(PetReport.id)
            .filter(PetReport.user_id == current_user.id)
            .all()
        ]

        if not user_report_ids and current_user.role != "admin":
            return [], 0

        query = (
            self.db.query(Match)
            .options(
                joinedload(Match.lost_report).joinedload(PetReport.images),
                joinedload(Match.found_report).joinedload(PetReport.images),
            )
        )

        if current_user.role != "admin":
            query = query.filter(
                (Match.lost_report_id.in_(user_report_ids))
                | (Match.found_report_id.in_(user_report_ids))
            )

        if status_filter:
            query = query.filter(Match.status == status_filter.title())

        total = query.count()
        skip = (page - 1) * size
        items = query.order_by(Match.match_score.desc()).offset(skip).limit(size).all()
        return items, total

    def get_match_by_id(self, match_id: uuid.UUID, current_user: User) -> Match:
        """Retrieves an individual match ensuring authorization check."""
        match = (
            self.db.query(Match)
            .options(
                joinedload(Match.lost_report).joinedload(PetReport.images),
                joinedload(Match.found_report).joinedload(PetReport.images),
            )
            .filter(Match.id == match_id)
            .first()
        )
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match record not found.",
            )

        # Authorization: user must own lost_report or found_report, or be admin
        is_owner = (
            match.lost_report.user_id == current_user.id
            or match.found_report.user_id == current_user.id
        )
        if not is_owner and current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to view this match.",
            )

        return match

    def update_match_status(
        self,
        match_id: uuid.UUID,
        new_status: str,
        current_user: User,
    ) -> Match:
        """Updates match status (Suggested -> Relevant / Dismissed / Resolved) with lifecycle checks."""
        match = self.get_match_by_id(match_id, current_user)
        normalized_status = new_status.strip().title()

        if normalized_status == match.status:
            return match

        allowed_next = PERMITTED_TRANSITIONS.get(match.status, set())
        if normalized_status not in allowed_next:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Invalid status transition from '{match.status}' to '{normalized_status}'. "
                    f"Allowed transitions: {', '.join(sorted(allowed_next)) if allowed_next else 'None (terminal state)'}."
                ),
            )

        match.status = normalized_status
        self.db.commit()
        self.db.refresh(match)
        return match

    def get_matches_for_report(self, report_id: uuid.UUID) -> List[Match]:
        """Retrieves stored matches for a specific report."""
        return (
            self.db.query(Match)
            .options(
                joinedload(Match.lost_report).joinedload(PetReport.images),
                joinedload(Match.found_report).joinedload(PetReport.images),
            )
            .filter(
                (Match.lost_report_id == report_id) | (Match.found_report_id == report_id)
            )
            .order_by(Match.match_score.desc())
            .all()
        )
