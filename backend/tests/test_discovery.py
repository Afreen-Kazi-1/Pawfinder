"""Tests for Module 05 (Discovery & Search) and Module 06 (Location & Maps)."""
import uuid
import pytest
from fastapi.testclient import TestClient
from app.core.security import create_access_token
from app.models.user import User


# --------------- fixtures ---------------

@pytest.fixture
def disc_user(db_session) -> User:
    user = User(
        name="Discovery Tester",
        email=f"disc_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="fakehash",
        role="user",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def disc_headers(disc_user) -> dict:
    token = create_access_token(subject=str(disc_user.id))
    return {"Authorization": f"Bearer {token}"}


def _make_report(client, headers, overrides=None):
    """Helper: create a report and return the JSON response."""
    payload = {
        "report_type": "LOST",
        "pet_name": "Buddy",
        "animal_type": "Dog",
        "breed": "Golden Retriever",
        "color": "Golden",
        "latitude": 37.7749,
        "longitude": -122.4194,
        "location_label": "San Francisco",
        "event_datetime": "2026-11-01T10:00:00Z",
    }
    if overrides:
        payload.update(overrides)
    resp = client.post("/api/reports", json=payload, headers=headers)
    assert resp.status_code == 201, resp.text
    return resp.json()


# ====================================================================
# MODULE 05 – DISCOVERY & SEARCH TESTS
# ====================================================================

class TestDiscoveryFiltering:
    """Report-type, animal-type, breed, color, and combined filters."""

    def test_filter_by_report_type_lost(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"report_type": "LOST", "pet_name": "Lost1"})
        _make_report(client, disc_headers, {"report_type": "FOUND", "pet_name": "Found1"})

        resp = client.get("/api/discovery?report_type=LOST", headers=disc_headers)
        assert resp.status_code == 200
        data = resp.json()
        for item in data["items"]:
            assert item["report_type"] == "LOST"

    def test_filter_by_report_type_found(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"report_type": "FOUND", "pet_name": None})

        resp = client.get("/api/discovery?report_type=FOUND", headers=disc_headers)
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            assert item["report_type"] == "FOUND"

    def test_filter_by_animal_type(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"animal_type": "Cat", "color": "Black"})
        _make_report(client, disc_headers, {"animal_type": "Dog"})

        resp = client.get("/api/discovery?animal_type=Cat", headers=disc_headers)
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            assert "cat" in item["animal_type"].lower()

    def test_filter_by_breed(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"breed": "Siamese", "animal_type": "Cat", "color": "White"})

        resp = client.get("/api/discovery?breed=Siamese", headers=disc_headers)
        assert resp.status_code == 200
        assert any("Siamese" in (it.get("breed") or "") for it in resp.json()["items"])

    def test_filter_by_color(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"color": "Tabby"})

        resp = client.get("/api/discovery?color=Tabby", headers=disc_headers)
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            assert "tabby" in item["color"].lower()

    def test_combined_filters(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {
            "report_type": "LOST", "animal_type": "Dog", "breed": "Poodle", "color": "White",
        })
        _make_report(client, disc_headers, {
            "report_type": "FOUND", "animal_type": "Cat", "color": "Grey",
        })

        resp = client.get(
            "/api/discovery?report_type=LOST&animal_type=Dog&breed=Poodle",
            headers=disc_headers,
        )
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            assert item["report_type"] == "LOST"
            assert "dog" in item["animal_type"].lower()

    def test_empty_results(self, client: TestClient, disc_headers):
        resp = client.get(
            "/api/discovery?animal_type=Elephant",
            headers=disc_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["items"] == []
        assert resp.json()["total"] == 0

    def test_free_text_search(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"description": "has a blue collar with sparkles"})

        resp = client.get("/api/discovery?search=sparkles", headers=disc_headers)
        assert resp.status_code == 200
        assert any("sparkles" in it.get("description", "").lower() for it in resp.json()["items"])


class TestDiscoveryDateFiltering:
    """Date range filters."""

    def test_filter_by_start_date(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"event_datetime": "2026-11-10T10:00:00Z"})
        _make_report(client, disc_headers, {"event_datetime": "2026-10-01T10:00:00Z"})

        resp = client.get("/api/discovery?start_date=2026-11-01", headers=disc_headers)
        assert resp.status_code == 200
        # All returned items should have event_datetime >= 2026-11-01
        for item in resp.json()["items"]:
            assert item["event_datetime"] >= "2026-11-01"

    def test_filter_by_end_date(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"event_datetime": "2026-09-15T10:00:00Z"})

        resp = client.get("/api/discovery?end_date=2026-10-01", headers=disc_headers)
        assert resp.status_code == 200


class TestDiscoveryPagination:
    """Pagination, page size, and invalid values."""

    def test_pagination_returns_metadata(self, client: TestClient, disc_headers):
        for i in range(3):
            _make_report(client, disc_headers, {"pet_name": f"Page{i}"})

        resp = client.get("/api/discovery?page=1&size=2", headers=disc_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["page"] == 1
        assert data["size"] == 2
        assert len(data["items"]) <= 2
        assert data["total"] >= 3

    def test_page_two(self, client: TestClient, disc_headers):
        for i in range(5):
            _make_report(client, disc_headers, {"pet_name": f"Pg{i}"})

        resp = client.get("/api/discovery?page=2&size=2", headers=disc_headers)
        assert resp.status_code == 200
        assert resp.json()["page"] == 2

    def test_invalid_page_zero(self, client: TestClient, disc_headers):
        resp = client.get("/api/discovery?page=0", headers=disc_headers)
        assert resp.status_code == 422  # validation error

    def test_invalid_negative_page(self, client: TestClient, disc_headers):
        resp = client.get("/api/discovery?page=-1", headers=disc_headers)
        assert resp.status_code == 422

    def test_max_page_size_enforced(self, client: TestClient, disc_headers):
        resp = client.get("/api/discovery?size=999", headers=disc_headers)
        assert resp.status_code == 422  # le=100 constraint


class TestClosedReportExclusion:
    """Closed and resolved reports must not appear in discovery."""

    def test_closed_reports_excluded(self, client: TestClient, disc_headers):
        report = _make_report(client, disc_headers, {"pet_name": "ClosedPet"})
        # Close it
        client.patch(
            f"/api/reports/{report['id']}/status",
            json={"status": "Closed"},
            headers=disc_headers,
        )

        resp = client.get("/api/discovery", headers=disc_headers)
        assert resp.status_code == 200
        ids = [it["id"] for it in resp.json()["items"]]
        assert report["id"] not in ids

    def test_resolved_reports_excluded(self, client: TestClient, disc_headers):
        report = _make_report(client, disc_headers, {"pet_name": "ResolvedPet"})
        client.patch(
            f"/api/reports/{report['id']}/status",
            json={"status": "Reunited / Resolved"},
            headers=disc_headers,
        )

        resp = client.get("/api/discovery", headers=disc_headers)
        ids = [it["id"] for it in resp.json()["items"]]
        assert report["id"] not in ids


class TestDiscoverySorting:
    """Sort options."""

    def test_sort_by_created_at_desc(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers)
        resp = client.get("/api/discovery?sort_by=created_at&sort_order=desc", headers=disc_headers)
        assert resp.status_code == 200

    def test_sort_by_event_datetime_asc(self, client: TestClient, disc_headers):
        resp = client.get(
            "/api/discovery?sort_by=event_datetime&sort_order=asc",
            headers=disc_headers,
        )
        assert resp.status_code == 200

    def test_invalid_sort_field_falls_back(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers)
        resp = client.get("/api/discovery?sort_by=nonexistent", headers=disc_headers)
        assert resp.status_code == 200  # Falls back to created_at


# ====================================================================
# MODULE 06 – NEARBY & MAP TESTS
# ====================================================================

class TestNearbyEndpoint:
    """GET /api/discovery/nearby – Haversine proximity search."""

    def test_nearby_returns_reports_within_radius(self, client: TestClient, disc_headers):
        # Report at San Francisco (37.7749, -122.4194)
        _make_report(client, disc_headers, {
            "latitude": 37.7749, "longitude": -122.4194,
            "location_label": "SF Downtown",
        })
        # Query from same location, 10 km radius
        resp = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194&radius_km=10",
            headers=disc_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] >= 1
        # distance should be ~0
        assert data["items"][0]["distance_km"] is not None

    def test_nearby_excludes_reports_outside_radius(self, client: TestClient, disc_headers):
        # Report in San Francisco
        _make_report(client, disc_headers, {
            "latitude": 37.7749, "longitude": -122.4194,
            "location_label": "SF",
        })
        # Query from New York (~4000 km away), tiny radius
        resp = client.get(
            "/api/discovery/nearby?latitude=40.7128&longitude=-74.0060&radius_km=5",
            headers=disc_headers,
        )
        assert resp.status_code == 200
        # SF report should NOT be in results
        data = resp.json()
        sf_reports = [it for it in data["items"] if "SF" in it.get("location_label", "")]
        assert len(sf_reports) == 0

    def test_nearby_different_radii(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {
            "latitude": 37.78, "longitude": -122.42,
            "location_label": "Near SF",
        })
        # Very small radius
        r1 = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194&radius_km=0.1",
            headers=disc_headers,
        )
        # Larger radius
        r2 = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194&radius_km=50",
            headers=disc_headers,
        )
        assert r1.status_code == 200
        assert r2.status_code == 200
        assert r2.json()["total"] >= r1.json()["total"]

    def test_nearby_sorted_by_distance(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {
            "latitude": 37.80, "longitude": -122.42, "location_label": "Farther",
        })
        _make_report(client, disc_headers, {
            "latitude": 37.775, "longitude": -122.419, "location_label": "Closer",
        })

        resp = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194&radius_km=50",
            headers=disc_headers,
        )
        data = resp.json()
        if len(data["items"]) >= 2:
            distances = [it["distance_km"] for it in data["items"] if it["distance_km"] is not None]
            assert distances == sorted(distances)

    def test_nearby_pagination(self, client: TestClient, disc_headers):
        for i in range(5):
            _make_report(client, disc_headers, {
                "latitude": 37.7749 + i * 0.001,
                "longitude": -122.4194,
                "location_label": f"NearPag{i}",
            })
        resp = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194&radius_km=50&page=1&size=2",
            headers=disc_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["items"]) <= 2
        assert data["page"] == 1

    def test_nearby_default_radius(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {
            "latitude": 37.7749, "longitude": -122.4194,
            "location_label": "DefaultRadius",
        })
        # Omit radius_km → default 10 km
        resp = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194",
            headers=disc_headers,
        )
        assert resp.status_code == 200


class TestLocationPrivacy:
    """Public API must NOT leak exact private coordinates."""

    def test_nearby_returns_approximate_coordinates(self, client: TestClient, disc_headers):
        exact_lat = 37.77491234567
        exact_lng = -122.41941234567
        _make_report(client, disc_headers, {
            "latitude": exact_lat,
            "longitude": exact_lng,
            "location_label": "Precise Location",
        })

        resp = client.get(
            "/api/discovery/nearby?latitude=37.7749&longitude=-122.4194&radius_km=10",
            headers=disc_headers,
        )
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            if item["location_label"] == "Precise Location":
                # approx_latitude/longitude should be rounded to 3 decimals
                assert item["approx_latitude"] != exact_lat
                assert item["approx_longitude"] != exact_lng
                # Should be rounded to 3 decimal places
                approx_str = str(item["approx_latitude"])
                if "." in approx_str:
                    decimals = len(approx_str.split(".")[1])
                    assert decimals <= 3

    def test_map_returns_approximate_coordinates(self, client: TestClient, disc_headers):
        exact_lat = 37.77495555555
        exact_lng = -122.41945555555
        _make_report(client, disc_headers, {
            "latitude": exact_lat,
            "longitude": exact_lng,
            "location_label": "Map Privacy",
        })

        resp = client.get("/api/discovery/map", headers=disc_headers)
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            if item["location_label"] == "Map Privacy":
                assert item["approx_latitude"] != exact_lat
                assert item["approx_longitude"] != exact_lng

    def test_public_response_does_not_contain_exact_lat_lng(self, client: TestClient, disc_headers):
        """Public responses should not have latitude/longitude fields at all, only approx_*."""
        _make_report(client, disc_headers, {
            "latitude": 37.12345678, "longitude": -122.98765432,
            "location_label": "Privacy Check",
        })

        resp = client.get("/api/discovery/nearby?latitude=37.12&longitude=-122.99&radius_km=50", headers=disc_headers)
        for item in resp.json()["items"]:
            if item["location_label"] == "Privacy Check":
                assert "latitude" not in item or item.get("latitude") is None
                assert "longitude" not in item or item.get("longitude") is None
                assert "approx_latitude" in item
                assert "approx_longitude" in item


class TestMapEndpoint:
    """GET /api/discovery/map."""

    def test_map_returns_all_active_reports(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"location_label": "MapTest"})

        resp = client.get("/api/discovery/map", headers=disc_headers)
        assert resp.status_code == 200
        assert resp.json()["total"] >= 1

    def test_map_with_radius_filter(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {
            "latitude": 37.7749, "longitude": -122.4194,
            "location_label": "MapRadius",
        })

        resp = client.get(
            "/api/discovery/map?latitude=37.7749&longitude=-122.4194&radius_km=10",
            headers=disc_headers,
        )
        assert resp.status_code == 200

    def test_map_with_report_type_filter(self, client: TestClient, disc_headers):
        _make_report(client, disc_headers, {"report_type": "FOUND", "location_label": "MapFound"})

        resp = client.get("/api/discovery/map?report_type=FOUND", headers=disc_headers)
        assert resp.status_code == 200
        for item in resp.json()["items"]:
            assert item["report_type"] == "FOUND"


class TestDiscoveryAuth:
    """Discovery endpoints require authentication."""

    def test_discovery_requires_auth(self, client: TestClient):
        resp = client.get("/api/discovery")
        assert resp.status_code == 401

    def test_nearby_requires_auth(self, client: TestClient):
        resp = client.get("/api/discovery/nearby?latitude=0&longitude=0")
        assert resp.status_code == 401

    def test_map_requires_auth(self, client: TestClient):
        resp = client.get("/api/discovery/map")
        assert resp.status_code == 401

