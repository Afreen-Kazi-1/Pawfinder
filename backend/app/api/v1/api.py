from fastapi import APIRouter
from app.api.v1.endpoints import auth, reports, images

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(reports.router, prefix="/reports", tags=["Pet Reports"])
api_router.include_router(images.router, prefix="/images", tags=["Pet Images"])
