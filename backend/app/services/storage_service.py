import os
import uuid
from typing import Tuple, Set
import httpx
from fastapi import HTTPException, status
from app.core.config import settings

ALLOWED_MIME_TYPES: Set[str] = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/gif",
}

MAX_FILE_SIZE_BYTES: int = 5 * 1024 * 1024  # 5 MB


class StorageService:
    def __init__(
        self,
        supabase_url: str = settings.SUPABASE_URL,
        service_role_key: str = settings.SUPABASE_SERVICE_ROLE_KEY,
        bucket_name: str = settings.SUPABASE_STORAGE_BUCKET,
    ):
        self.supabase_url = supabase_url.rstrip("/") if supabase_url else ""
        self.service_role_key = service_role_key
        self.bucket_name = bucket_name
        self.local_fallback_dir = os.path.join(os.getcwd(), "uploads", self.bucket_name)

    def validate_file(self, content_type: str, file_size: int) -> None:
        """Validates MIME type and file size limits."""
        if content_type not in ALLOWED_MIME_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported image type '{content_type}'. Allowed types are: {', '.join(sorted(ALLOWED_MIME_TYPES))}",
            )

        if file_size > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image size ({file_size} bytes) exceeds maximum allowed size of {MAX_FILE_SIZE_BYTES} bytes (5 MB).",
            )

    def upload_image(
        self,
        report_id: uuid.UUID,
        filename: str,
        file_bytes: bytes,
        content_type: str,
    ) -> Tuple[str, str]:
        """
        Uploads image to Supabase Storage or local fallback directory.
        Returns (image_url, storage_path).
        """
        self.validate_file(content_type, len(file_bytes))

        # Generate unique storage path
        ext = os.path.splitext(filename)[1].lower()
        if not ext:
            ext = ".jpg" if "jpeg" in content_type else ".png"
        unique_id = uuid.uuid4().hex
        storage_path = f"reports/{report_id}/{unique_id}{ext}"

        # If Supabase credentials are configured and not dummy/placeholder, upload to Supabase Storage
        has_real_supabase = (
            bool(self.supabase_url)
            and bool(self.service_role_key)
            and "your-project" not in self.supabase_url
            and "your-supabase" not in self.service_role_key
        )
        if has_real_supabase:
            try:
                upload_url = f"{self.supabase_url}/storage/v1/object/{self.bucket_name}/{storage_path}"
                headers = {
                    "Authorization": f"Bearer {self.service_role_key}",
                    "Content-Type": content_type,
                    "x-upsert": "true",
                }
                with httpx.Client(timeout=20.0) as client:
                    response = client.post(upload_url, headers=headers, content=file_bytes)
                    if response.status_code not in (200, 201):
                        raise HTTPException(
                            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                            detail=f"Supabase Storage upload failed with status {response.status_code}: {response.text}",
                        )
                image_url = f"{self.supabase_url}/storage/v1/object/public/{self.bucket_name}/{storage_path}"
                return image_url, storage_path
            except httpx.RequestError as e:
                raise HTTPException(
                    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                    detail=f"Failed to communicate with Supabase Storage: {str(e)}",
                )

        # Fallback to local disk storage for offline testing and development
        os.makedirs(os.path.dirname(os.path.join(self.local_fallback_dir, storage_path)), exist_ok=True)
        local_full_path = os.path.join(self.local_fallback_dir, storage_path)
        with open(local_full_path, "wb") as f:
            f.write(file_bytes)

        image_url = f"/static/uploads/{self.bucket_name}/{storage_path}"
        return image_url, storage_path

    def delete_image(self, storage_path: str) -> bool:
        """Deletes image from Supabase Storage or local fallback directory."""
        has_real_supabase = (
            bool(self.supabase_url)
            and bool(self.service_role_key)
            and "your-project" not in self.supabase_url
            and "your-supabase" not in self.service_role_key
        )
        if has_real_supabase:
            try:
                delete_url = f"{self.supabase_url}/storage/v1/object/{self.bucket_name}/{storage_path}"
                headers = {"Authorization": f"Bearer {self.service_role_key}"}
                with httpx.Client(timeout=10.0) as client:
                    response = client.delete(delete_url, headers=headers)
                    return response.status_code in (200, 204, 404)
            except Exception:
                return False

        local_full_path = os.path.join(self.local_fallback_dir, storage_path)
        if os.path.exists(local_full_path):
            try:
                os.remove(local_full_path)
                return True
            except Exception:
                return False
        return True


storage_service = StorageService()

