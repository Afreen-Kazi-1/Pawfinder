import uuid
from datetime import datetime, timedelta
from types import SimpleNamespace
import pytest
from fastapi.testclient import TestClient

from app.core.security import create_access_token
from app.models.user import User
from app.models.pet_report import PetReport
from app.services.matching_engine import MatchingEngine
from app.services.match_service import MatchService


# ====================================================================
# Unit Tests for MatchingEngine Component Scoring
# ====================================================================

class TestMatchingEngineUnit:
    def setup_method(self):
        self.engine = MatchingEngine()

    def test_animal_type_exact_match(self):
        score, explanation, active = self.engine.score_animal_type("Dog", "dog")
        assert score == 100.0
        assert active is True

    def test_animal_type_incompatible(self):
        score, explanation, active = self.engine.score_animal_type("Dog", "Cat")
        assert score == 0.0
        assert active is True

    def test_breed_exact_match(self):
        score, explanation, active = self.engine.score_breed("Golden Retriever", "golden retriever")
        assert score == 100.0

    def test_breed_alias_match(self):
        # "Alsatian" and "GSD" both map to "german shepherd"
        score, explanation, active = self.engine.score_breed("Alsatian", "German Shepherd Dog")
        assert score == 100.0

    def test_breed_partial_overlap(self):
        score, explanation, active = self.engine.score_breed("Labrador Retriever", "Retriever")
        assert score >= 70.0

    def test_breed_different(self):
        score, explanation, active = self.engine.score_breed("Poodle", "Bulldog")
        assert score <= 20.0

    def test_breed_unknown_handling(self):
        score, explanation, active = self.engine.score_breed("Unknown", "Golden Retriever")
        assert score == 60.0

        score_both_unknown, _, _ = self.engine.score_breed("Mixed", "Unknown")
        assert score_both_unknown == 50.0

    def test_color_exact_and_multiple_overlap(self):
        score, explanation, active = self.engine.score_color("Golden and White", "White, Golden")
        assert score >= 90.0

    def test_color_family_similarity(self):
        # 'tan' and 'brown' share the 'brown' family
        score, explanation, active = self.engine.score_color("Tan", "Chocolate brown")
        assert score >= 70.0

    def test_color_different(self):
        score, explanation, active = self.engine.score_color("Jet Black", "Snow White")
        assert score <= 20.0

    def test_location_nearby(self):
        # Points ~500m apart
        score, explanation, active = self.engine.score_location(37.7749, -122.4194, 37.7780, -122.4194)
        assert score == 100.0

    def test_location_medium_distance(self):
        # Points ~8km apart
        score, explanation, active = self.engine.score_location(37.7749, -122.4194, 37.8400, -122.4194)
        assert score == 65.0

    def test_location_distant(self):
        # SF to NYC (~4100 km)
        score, explanation, active = self.engine.score_location(37.7749, -122.4194, 40.7128, -74.0060)
        assert score == 0.0

    def test_location_missing_coordinates(self):
        score, explanation, active = self.engine.score_location(None, None, 37.7749, -122.4194)
        assert active is False

    def test_date_proximity_same_day(self):
        d1 = datetime(2026, 11, 10, 10, 0)
        d2 = datetime(2026, 11, 10, 15, 0)
        score, explanation, active = self.engine.score_date(d1, d2)
        assert score == 100.0

    def test_date_proximity_few_days_later(self):
        d1 = datetime(2026, 11, 10, 10, 0)
        d2 = datetime(2026, 11, 12, 10, 0)
        score, explanation, active = self.engine.score_date(d1, d2)
        assert score >= 90.0

    def test_date_large_difference(self):
        d1 = datetime(2026, 1, 1)
        d2 = datetime(2026, 11, 1)
        score, explanation, active = self.engine.score_date(d1, d2)
        assert score <= 15.0

    def test_description_overlap(self):
        feat1 = "Red leather collar, notched left ear"
        desc1 = "Friendly beagle answered to Cooper near park"
        feat2 = "Notched ear, red collar"
        desc2 = "Found gentle dog near park playground"
        score, explanation, active = self.engine.score_description(feat1, desc1, feat2, desc2)
        assert score >= 80.0

    def test_description_no_overlap(self):
        score, explanation, active = self.engine.score_description(
            "Sparkly harness", "Quiet bird", "Blue bandana", "Loud barker"
        )
        assert score <= 30.0

    def test_full_evaluation_high_potential_match(self):
        lost = SimpleNamespace(
            animal_type="Dog",
            breed="Golden Retriever",
            color="Golden",
            latitude=37.7749,
            longitude=-122.4194,
            event_datetime=datetime(2026, 11, 10, 10, 0),
            distinguishingFeatures="Red collar with bell",
            distinguishing_features="Red collar with bell",
            description="Lost in Golden Gate Park near the lake",
        )
        found = SimpleNamespace(
            animal_type="Dog",
            breed="Golden Retriever",
            color="Gold / Yellow",
            latitude=37.7760,
            longitude=-122.4200,
            event_datetime=datetime(2026, 11, 10, 14, 0),
            distinguishingFeatures="Wearing red collar with small bell",
            distinguishing_features="Wearing red collar with small bell",
            description="Found friendly dog near Golden Gate Park lake",
        )
        res = self.engine.evaluate(lost, found)
        assert res["is_match"] is True
        assert res["match_score"] >= 80.0
        assert res["match_category"] == "High potential match"
        assert "final_score" in res["reasons"]
        assert "animal_type" in res["reasons"]

    def test_full_evaluation_incompatible_animal_type_rejected(self):
        lost = SimpleNamespace(
            animal_type="Dog",
            breed="Labrador",
            color="Black",
            latitude=37.7749,
            longitude=-122.4194,
            event_datetime=datetime(2026, 11, 10),
            distinguishing_features="",
            description="",
        )
        found = SimpleNamespace(
            animal_type="Cat",
            breed="Persian",
            color="Black",
            latitude=37.7749,
            longitude=-122.4194,
            event_datetime=datetime(2026, 11, 10),
            distinguishing_features="",
            description="",
        )
        res = self.engine.evaluate(lost, found)
        assert res["is_match"] is False
        assert res["match_score"] == 0.0

    def test_weight_normalization_when_location_missing(self):
        lost = SimpleNamespace(
            animal_type="Dog",
            breed="Pug",
            color="Fawn",
            latitude=None,
            longitude=None,
            event_datetime=datetime(2026, 11, 10),
            distinguishing_features="",
            description="",
        )
        found = SimpleNamespace(
            animal_type="Dog",
            breed="Pug",
            color="Fawn",
            latitude=37.7749,
            longitude=-122.4194,
            event_datetime=datetime(2026, 11, 10),
            distinguishing_features="",
            description="",
        )
        res = self.engine.evaluate(lost, found)
        # Location was inactive; remaining weights should normalize to 100
        assert res["reasons"]["location"]["active"] is False
        assert 0.0 <= res["match_score"] <= 100.0


# ====================================================================
# Integration & Workflow Tests with Database and API Endpoint
# ====================================================================

@pytest.fixture
def match_user(db_session) -> User:
    user = User(
        name="Match Owner",
        email=f"matcher_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="fakehash",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def match_headers(match_user) -> dict:
    token = create_access_token(subject=str(match_user.id))
    return {"Authorization": f"Bearer {token}"}


class TestMatchingWorkflow:
    def test_run_matching_lost_to_found(self, client: TestClient, db_session, match_user, match_headers):
        # 1. Create a FOUND report in the DB
        found = PetReport(
            user_id=match_user.id,
            report_type="FOUND",
            pet_name=None,
            animal_type="Dog",
            breed="Beagle",
            color="Tricolor",
            latitude=37.7749,
            longitude=-122.4194,
            location_label="Park",
            event_datetime=datetime(2026, 11, 10, 12, 0),
            distinguishing_features="White tail tip",
            description="Found wandering near dog park",
            status="Open",
        )
        db_session.add(found)
        db_session.commit()
        db_session.refresh(found)

        # 2. Create a LOST report that matches
        lost = PetReport(
            user_id=match_user.id,
            report_type="LOST",
            pet_name="Charlie",
            animal_type="Dog",
            breed="Beagle",
            color="Tricolor",
            latitude=37.7755,
            longitude=-122.4200,
            location_label="Park Playground",
            event_datetime=datetime(2026, 11, 10, 11, 0),
            distinguishing_features="White tail tip and brown ears",
            description="Lost our friendly beagle Charlie near dog park",
            status="Open",
        )
        db_session.add(lost)
        db_session.commit()
        db_session.refresh(lost)

        # 3. Call POST /api/matches/run/{lost.id}
        resp = client.post(f"/api/matches/run/{lost.id}", headers=match_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["matches_found"] >= 1
        top_match = data["matches"][0]
        assert top_match["lost_report_id"] == str(lost.id)
        assert top_match["found_report_id"] == str(found.id)
        assert top_match["match_score"] >= 75.0
        assert "animal_type" in top_match["match_reasons"]

    def test_reverse_matching_found_to_lost(self, client: TestClient, db_session, match_user, match_headers):
        # Running matching from the FOUND report's perspective searches open LOST reports
        lost = PetReport(
            user_id=match_user.id,
            report_type="LOST",
            pet_name="Bella",
            animal_type="Cat",
            breed="Siamese",
            color="Cream / Seal Point",
            latitude=37.78,
            longitude=-122.41,
            location_label="Market St",
            event_datetime=datetime(2026, 11, 11, 10, 0),
            status="Open",
        )
        found = PetReport(
            user_id=match_user.id,
            report_type="FOUND",
            animal_type="Cat",
            breed="Siamese Cat",
            color="Cream and Dark Brown",
            latitude=37.782,
            longitude=-122.412,
            location_label="Near Market St",
            event_datetime=datetime(2026, 11, 11, 14, 0),
            status="Open",
        )
        db_session.add_all([lost, found])
        db_session.commit()

        resp = client.post(f"/api/matches/run/{found.id}", headers=match_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["matches_found"] >= 1
        assert data["matches"][0]["lost_report_id"] == str(lost.id)

    def test_duplicate_prevention_and_rerun_updates_existing(self, client: TestClient, db_session, match_user, match_headers):
        lost = PetReport(
            user_id=match_user.id,
            report_type="LOST",
            pet_name="Max",
            animal_type="Dog",
            breed="German Shepherd",
            color="Black and Tan",
            latitude=37.77,
            longitude=-122.42,
            location_label="Sunset",
            event_datetime=datetime(2026, 11, 10),
            status="Open",
        )
        found = PetReport(
            user_id=match_user.id,
            report_type="FOUND",
            animal_type="Dog",
            breed="Alsatian",
            color="Tan with Black Saddle",
            latitude=37.772,
            longitude=-122.422,
            location_label="Sunset",
            event_datetime=datetime(2026, 11, 10),
            status="Open",
        )
        db_session.add_all([lost, found])
        db_session.commit()

        # Run 1
        resp1 = client.post(f"/api/matches/run/{lost.id}", headers=match_headers)
        assert resp1.status_code == 200
        match_id_1 = resp1.json()["matches"][0]["id"]

        # Run 2 (re-run)
        resp2 = client.post(f"/api/matches/run/{lost.id}", headers=match_headers)
        assert resp2.status_code == 200
        # Must have updated the existing record without creating duplicate entries
        assert resp2.json()["matches_found"] == 1
        match_id_2 = resp2.json()["matches"][0]["id"]
        assert match_id_1 == match_id_2

    def test_closed_and_resolved_reports_excluded(self, client: TestClient, db_session, match_user, match_headers):
        closed_lost = PetReport(
            user_id=match_user.id,
            report_type="LOST",
            animal_type="Dog",
            breed="Poodle",
            color="White",
            latitude=37.77,
            longitude=-122.41,
            location_label="Closed area",
            event_datetime=datetime(2026, 11, 10),
            status="Closed",
        )
        found = PetReport(
            user_id=match_user.id,
            report_type="FOUND",
            animal_type="Dog",
            breed="Poodle",
            color="White",
            latitude=37.77,
            longitude=-122.41,
            location_label="Found area",
            event_datetime=datetime(2026, 11, 10),
            status="Open",
        )
        db_session.add_all([closed_lost, found])
        db_session.commit()

        resp = client.post(f"/api/matches/run/{found.id}", headers=match_headers)
        assert resp.status_code == 200
        # Closed report should not generate a match
        assert resp.json()["matches_found"] == 0

    def test_get_report_matches_endpoint(self, client: TestClient, db_session, match_user, match_headers):
        lost = PetReport(
            user_id=match_user.id,
            report_type="LOST",
            animal_type="Dog",
            breed="Collie",
            color="Sable",
            latitude=37.77,
            longitude=-122.41,
            location_label="Lakeside",
            event_datetime=datetime(2026, 11, 10),
            status="Open",
        )
        found = PetReport(
            user_id=match_user.id,
            report_type="FOUND",
            animal_type="Dog",
            breed="Collie",
            color="Sable",
            latitude=37.771,
            longitude=-122.411,
            location_label="Lakeside",
            event_datetime=datetime(2026, 11, 10),
            status="Open",
        )
        db_session.add_all([lost, found])
        db_session.commit()

        client.post(f"/api/matches/run/{lost.id}", headers=match_headers)

        # GET /api/matches/report/{id}
        resp = client.get(f"/api/matches/report/{lost.id}", headers=match_headers)
        assert resp.status_code == 200
        matches = resp.json()
        assert len(matches) >= 1
        assert matches[0]["lost_report_id"] == str(lost.id)

