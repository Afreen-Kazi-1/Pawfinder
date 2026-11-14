from fastapi import APIRouter
from app.api.v1.endpoints import auth, reports, images, discovery, matches, contact_requests

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(reports.router, prefix="/reports", tags=["Pet Reports"])
api_router.include_router(images.router, prefix="/images", tags=["Pet Images"])
api_router.include_router(discovery.router, prefix="/discovery", tags=["Discovery"])
api_router.include_router(matches.router, prefix="/matches", tags=["Matches"])
api_router.include_router(contact_requests.router, prefix="/contact-requests", tags=["Contact Requests"])
