import uuid
from math import radians, sin, cos, sqrt, asin
from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, func

from app.api.deps import get_db, get_current_user
from app.models.pet_report import PetReport
from app.schemas.report import PetReportListResponse, PetReportPublicListResponse

router = APIRouter()

# Earth radius in km
_EARTH_RADIUS_KM = 6371.0


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate great-circle distance between two points in kilometres."""
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = sin(dlat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    return 2 * _EARTH_RADIUS_KM * asin(sqrt(a))


def _bounding_box_filter(query, latitude: float, longitude: float, radius_km: float):
    """Approximate bounding-box pre-filter for distance queries."""
    lat_deg = radius_km / 111.0
    lon_deg = radius_km / (111.0 * cos(radians(latitude)))
    return query.filter(
        and_(
            PetReport.latitude.between(latitude - lat_deg, latitude + lat_deg),
            PetReport.longitude.between(longitude - lon_deg, longitude + lon_deg),
        )
    )


def _active_reports_query(db: Session):
    """Base query: active reports only, eager-load images and user to avoid N+1."""
    return (
        db.query(PetReport)
        .options(joinedload(PetReport.images), joinedload(PetReport.user))
        .filter(PetReport.status.notin_(["Closed", "Resolved", "Reunited / Resolved"]))
    )


def _to_public_item(r: PetReport, distance_km: float = None) -> dict:
    """Convert a PetReport to a public dict with rounded coordinates."""
    return {
        "id": r.id,
        "user_id": r.user_id,
        "report_type": r.report_type,
        "pet_name": r.pet_name,
        "animal_type": r.animal_type,
        "breed": r.breed,
        "color": r.color,
        "gender": r.gender,
        "approximate_age": r.approximate_age,
        "distinguishing_features": r.distinguishing_features,
        "description": r.description,
        "approx_latitude": round(r.latitude, 3),
        "approx_longitude": round(r.longitude, 3),
        "location_label": r.location_label,
        "event_datetime": r.event_datetime,
        "reward": r.reward,
        "status": r.status,
        "created_at": r.created_at,
        "updated_at": r.updated_at,
        "images": r.images,
        "distance_km": round(distance_km, 2) if distance_km is not None else None,
        "user": r.user,
    }


# ---------------------------------------------------------------------------
# GET /api/discovery  –  general discovery with filters, pagination, sorting
# ---------------------------------------------------------------------------
@router.get(
    "",
    response_model=PetReportListResponse,
    summary="Discover active pet reports with filters, pagination, and sorting",
)
def discover_reports(
    report_type: Optional[str] = Query(None, description="LOST or FOUND"),
    animal_type: Optional[str] = Query(None, description="Dog, Cat, etc."),
    breed: Optional[str] = Query(None, description="Breed name"),
    color: Optional[str] = Query(None, description="Pet colour"),
    latitude: Optional[float] = Query(None, ge=-90, le=90, description="Latitude for distance filter"),
    longitude: Optional[float] = Query(None, ge=-180, le=180, description="Longitude for distance filter"),
    radius_km: Optional[float] = Query(None, gt=0, description="Search radius in km"),
    start_date: Optional[str] = Query(None, description="ISO date – start of event date range"),
    end_date: Optional[str] = Query(None, description="ISO date – end of event date range"),
    sort_by: Optional[str] = Query("created_at", description="Sort field: created_at, event_datetime, reward"),
    sort_order: Optional[str] = Query("desc", description="Sort order: asc or desc"),
    search: Optional[str] = Query(None, description="Free-text search across pet_name, breed, description"),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _=Depends(get_current_user),
):
    """Return discoverable (open) pet reports.
    Excludes CLOSED and RESOLVED reports.
    """
    query = _active_reports_query(db)

    if report_type:
        query = query.filter(PetReport.report_type == report_type.upper())
    if animal_type:
        query = query.filter(PetReport.animal_type.ilike(f"%{animal_type}%"))
    if breed:
        query = query.filter(PetReport.breed.ilike(f"%{breed}%"))
    if color:
        query = query.filter(PetReport.color.ilike(f"%{color}%"))
    if search:
        term = f"%{search}%"
        query = query.filter(
            PetReport.pet_name.ilike(term)
            | PetReport.breed.ilike(term)
            | PetReport.description.ilike(term)
            | PetReport.animal_type.ilike(term)
        )
    if latitude is not None and longitude is not None and radius_km is not None:
        query = _bounding_box_filter(query, latitude, longitude, radius_km)
    if start_date:
        query = query.filter(PetReport.event_datetime >= start_date)
    if end_date:
        query = query.filter(PetReport.event_datetime <= end_date)

    # Sorting
    sort_col = getattr(PetReport, sort_by, None) if sort_by else None
    if sort_col is None:
        sort_col = PetReport.created_at
    sort_col = sort_col.desc() if (sort_order or "desc").lower() == "desc" else sort_col.asc()
    query = query.order_by(sort_col)

    total = query.count()
    items = query.offset((page - 1) * size).limit(size).all()
    return PetReportListResponse(items=items, total=total, page=page, size=size)


# ---------------------------------------------------------------------------
# GET /api/discovery/nearby  –  Haversine-based proximity search
# ---------------------------------------------------------------------------
@router.get(
    "/nearby",
    response_model=PetReportPublicListResponse,
    summary="Nearby pet reports based on geographical distance",
)
def nearby_reports(
    latitude: float = Query(..., ge=-90, le=90, description="Reference latitude"),
    longitude: float = Query(..., ge=-180, le=180, description="Reference longitude"),
    radius_km: float = Query(10.0, gt=0, description="Search radius in km (default 10)"),
    report_type: Optional[str] = Query(None, description="LOST or FOUND"),
    animal_type: Optional[str] = Query(None, description="Dog, Cat, etc."),
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    _=Depends(get_current_user),
):
    """Return public reports within a radius, sorted by distance.
    Coordinates are rounded to ~100 m for location privacy.
    """
    query = _active_reports_query(db)
    if report_type:
        query = query.filter(PetReport.report_type == report_type.upper())
    if animal_type:
        query = query.filter(PetReport.animal_type.ilike(f"%{animal_type}%"))

    # Bounding-box pre-filter then exact Haversine
    query = _bounding_box_filter(query, latitude, longitude, radius_km)
    candidates = query.all()

    enriched = []
    for r in candidates:
        dist = _haversine(latitude, longitude, r.latitude, r.longitude)
        if dist <= radius_km:
            enriched.append((dist, r))
    enriched.sort(key=lambda x: x[0])

    total = len(enriched)
    start_idx = (page - 1) * size
    page_items = [_to_public_item(r, dist) for dist, r in enriched[start_idx:start_idx + size]]
    return PetReportPublicListResponse(items=page_items, total=total, page=page, size=size)


# ---------------------------------------------------------------------------
# GET /api/discovery/map  –  map view with approximate locations
# ---------------------------------------------------------------------------
@router.get(
    "/map",
    response_model=PetReportPublicListResponse,
    summary="Map view of pet reports – returns approximate locations",
)
def map_reports(
    latitude: Optional[float] = Query(None, ge=-90, le=90, description="Centre latitude"),
    longitude: Optional[float] = Query(None, ge=-180, le=180, description="Centre longitude"),
    radius_km: Optional[float] = Query(None, gt=0, description="Optional radius filter"),
    report_type: Optional[str] = Query(None, description="LOST or FOUND"),
    animal_type: Optional[str] = Query(None, description="Dog, Cat, etc."),
    page: int = Query(1, ge=1),
    size: int = Query(200, ge=1, le=500),
    db: Session = Depends(get_db),
    _=Depends(get_current_user),
):
    """Return active reports with rounded coordinates for map markers."""
    query = _active_reports_query(db)
    if report_type:
        query = query.filter(PetReport.report_type == report_type.upper())
    if animal_type:
        query = query.filter(PetReport.animal_type.ilike(f"%{animal_type}%"))

    if latitude is not None and longitude is not None and radius_km is not None:
        query = _bounding_box_filter(query, latitude, longitude, radius_km)
        candidates = query.all()
        # Exact Haversine filter
        items = []
        for r in candidates:
            dist = _haversine(latitude, longitude, r.latitude, r.longitude)
            if dist <= radius_km:
                items.append(_to_public_item(r, dist))
    else:
        all_reports = query.order_by(PetReport.created_at.desc()).all()
        items = [_to_public_item(r) for r in all_reports]

    total = len(items)
    start_idx = (page - 1) * size
    paged = items[start_idx:start_idx + size]
    return PetReportPublicListResponse(items=paged, total=total, page=page, size=size)
