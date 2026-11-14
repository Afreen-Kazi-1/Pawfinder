import uuid
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status

from app.models.pet_report import PetReport
from app.models.match import Match
from app.services.matching_engine import MatchingEngine


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
                # Pre-filter by animal type (case-insensitive) for performance
                PetReport.animal_type.ilike(report.animal_type),
            )
            .all()
        )

        persisted_matches: List[Match] = []

        for candidate in candidates:
            # Determine which is lost and which is found
            lost_rep = report if report.report_type.upper() == "LOST" else candidate
            found_rep = candidate if report.report_type.upper() == "LOST" else report

            eval_res = self.engine.evaluate(lost_rep, found_rep)

            if eval_res["is_match"]:
                # Check for existing match record (prevent duplicate error via UniqueConstraint)
                existing_match = (
                    self.db.query(Match)
                    .filter(
                        Match.lost_report_id == lost_rep.id,
                        Match.found_report_id == found_rep.id,
                    )
                    .first()
                )

                if existing_match:
                    # Update score, category, and reasons
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

        # Sort matches by score descending
        persisted_matches.sort(key=lambda m: m.match_score, reverse=True)
        return persisted_matches

    def get_matches_for_report(self, report_id: uuid.UUID) -> List[Match]:
        """Retrieves existing matches for a report (either lost or found)."""
        return (
            self.db.query(Match)
            .filter(
                (Match.lost_report_id == report_id) | (Match.found_report_id == report_id)
            )
            .order_by(Match.match_score.desc())
            .all()
        )

