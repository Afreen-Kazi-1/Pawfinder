import uuid
from datetime import timedelta
from fastapi import Depends
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, verify_password
from app.models.user import User
from app.api.deps import get_current_admin
from app.main import app

# Add a test-only admin endpoint to verify get_current_admin dependency
@app.get("/api/test-admin-only", tags=["Test"])
def admin_route_handler(admin_user: User = Depends(get_current_admin)):
    return {"message": "Admin access granted", "admin_id": str(admin_user.id)}


def test_successful_registration(client: TestClient):
    """Test successful user registration returns 201 and safe user profile without password."""
    payload = {
        "name": "Sarah Connor",
        "email": "sarah@example.com",
        "password": "Password123!",
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Sarah Connor"
    assert data["email"] == "sarah@example.com"
    assert data["role"] == "user"
    assert "id" in data
    # Security requirement: passwords and hashes must never appear in response
    assert "password" not in data
    assert "password_hash" not in data


def test_duplicate_registration(client: TestClient):
    """Test that registering an already registered email returns 409 Conflict."""
    payload = {
        "name": "John Doe",
        "email": "johndoe@example.com",
        "password": "Password123!",
    }
    res1 = client.post("/api/auth/register", json=payload)
    assert res1.status_code == 201

    # Second registration with exact same email
    res2 = client.post("/api/auth/register", json=payload)
    assert res2.status_code == 409
    assert "already exists" in res2.json()["detail"]


def test_invalid_email_registration(client: TestClient):
    """Test that invalid email format is rejected with 422 validation error."""
    payload = {
        "name": "Test User",
        "email": "invalid-email-address",
        "password": "Password123!",
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 422


def test_weak_password_registration(client: TestClient):
    """Test that passwords failing complexity criteria are rejected."""
    # Too short (< 8 chars)
    res_short = client.post(
        "/api/auth/register",
        json={"name": "User", "email": "short@example.com", "password": "Pass1"},
    )
    assert res_short.status_code == 422

    # No digits
    res_no_digits = client.post(
        "/api/auth/register",
        json={"name": "User", "email": "nodigit@example.com", "password": "PasswordOnly"},
    )
    assert res_no_digits.status_code == 422

    # No letters
    res_no_letters = client.post(
        "/api/auth/register",
        json={"name": "User", "email": "noletter@example.com", "password": "1234567890"},
    )
    assert res_no_letters.status_code == 422


def test_password_hashing(client: TestClient, db_session: Session):
    """Test that passwords are never stored in plaintext and use bcrypt hashing."""
    plain_pw = "SuperSecurePassword123!"
    payload = {
        "name": "Crypto User",
        "email": "crypto@example.com",
        "password": plain_pw,
    }
    res = client.post("/api/auth/register", json=payload)
    assert res.status_code == 201

    user = db_session.query(User).filter(User.email == "crypto@example.com").first()
    assert user is not None
    # Must not be plaintext
    assert user.password_hash != plain_pw
    # Must verify with bcrypt
    assert verify_password(plain_pw, user.password_hash) is True
    # Must reject incorrect password
    assert verify_password("WrongPassword123", user.password_hash) is False


def test_successful_login(client: TestClient):
    """Test login returns access and refresh tokens with bearer token type."""
    # Register first
    client.post(
        "/api/auth/register",
        json={"name": "Login User", "email": "login@example.com", "password": "LoginPassword123"},
    )

    # Login
    response = client.post(
        "/api/auth/login",
        json={"email": "login@example.com", "password": "LoginPassword123"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] > 0


def test_incorrect_password_and_user_enumeration_protection(client: TestClient):
    """Test incorrect password and nonexistent user return identical 401 error."""
    client.post(
        "/api/auth/register",
        json={"name": "Target User", "email": "target@example.com", "password": "RealPassword123"},
    )

    # Wrong password for existing user
    res_wrong_pw = client.post(
        "/api/auth/login",
        json={"email": "target@example.com", "password": "WrongPassword999"},
    )
    assert res_wrong_pw.status_code == 401

    # Nonexistent user
    res_nonexistent = client.post(
        "/api/auth/login",
        json={"email": "nobody_exists@example.com", "password": "WrongPassword999"},
    )
    assert res_nonexistent.status_code == 401

    # Identical detail prevents account enumeration
    assert res_wrong_pw.json()["detail"] == res_nonexistent.json()["detail"]


def test_access_token_validation(client: TestClient):
    """Test authenticated profile access using valid Bearer access token."""
    client.post(
        "/api/auth/register",
        json={"name": "Token User", "email": "token@example.com", "password": "TokenPassword123"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "token@example.com", "password": "TokenPassword123"},
    )
    access_token = login_res.json()["access_token"]

    # Access /api/auth/me
    response = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "token@example.com"
    assert data["name"] == "Token User"


def test_expired_access_token(client: TestClient):
    """Test that expired access tokens are rejected with 401 Unauthorized."""
    expired_token = create_access_token(
        subject=str(uuid.uuid4()), expires_delta=timedelta(seconds=-10)
    )
    response = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {expired_token}"},
    )
    assert response.status_code == 401
    assert "credentials" in response.json()["detail"].lower()


def test_invalid_token(client: TestClient):
    """Test that malformed or non-access tokens are rejected on protected endpoints."""
    # Malformed garbage
    res_garbage = client.get(
        "/api/auth/me",
        headers={"Authorization": "Bearer not.a.valid.jwt"},
    )
    assert res_garbage.status_code == 401

    # Pass refresh token to an access token endpoint
    client.post(
        "/api/auth/register",
        json={"name": "Type Test", "email": "typetest@example.com", "password": "Password123!"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "typetest@example.com", "password": "Password123!"},
    )
    refresh_token = login_res.json()["refresh_token"]

    res_refresh_as_access = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {refresh_token}"},
    )
    assert res_refresh_as_access.status_code == 401


def test_refresh_token_rotation(client: TestClient):
    """Test refresh token rotation issues new pair and revokes the old refresh token."""
    client.post(
        "/api/auth/register",
        json={"name": "Rotator", "email": "rotator@example.com", "password": "Password123!"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "rotator@example.com", "password": "Password123!"},
    )
    old_refresh_token = login_res.json()["refresh_token"]

    # Rotate refresh token
    refresh_res = client.post(
        "/api/auth/refresh",
        json={"refresh_token": old_refresh_token},
    )
    assert refresh_res.status_code == 200
    new_tokens = refresh_res.json()
    assert "access_token" in new_tokens
    assert "refresh_token" in new_tokens
    assert new_tokens["refresh_token"] != old_refresh_token

    # Verify new access token works
    me_res = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {new_tokens['access_token']}"},
    )
    assert me_res.status_code == 200
    assert me_res.json()["email"] == "rotator@example.com"


def test_refresh_token_reuse_revocation(client: TestClient):
    """Test that attempting to reuse an already rotated refresh token is detected and rejected."""
    client.post(
        "/api/auth/register",
        json={"name": "Reuser", "email": "reuser@example.com", "password": "Password123!"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "reuser@example.com", "password": "Password123!"},
    )
    first_refresh_token = login_res.json()["refresh_token"]

    # First rotation (succeeds)
    res_rotation = client.post(
        "/api/auth/refresh",
        json={"refresh_token": first_refresh_token},
    )
    assert res_rotation.status_code == 200

    # Second attempt with the SAME first_refresh_token (must fail)
    res_reuse = client.post(
        "/api/auth/refresh",
        json={"refresh_token": first_refresh_token},
    )
    assert res_reuse.status_code == 401
    assert "reuse" in res_reuse.json()["detail"].lower()


def test_logout(client: TestClient):
    """Test logout revokes the specified refresh token."""
    client.post(
        "/api/auth/register",
        json={"name": "Logout User", "email": "logout@example.com", "password": "Password123!"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "logout@example.com", "password": "Password123!"},
    )
    tokens = login_res.json()

    # Logout
    logout_res = client.post(
        "/api/auth/logout",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert logout_res.status_code == 200
    assert "logged out" in logout_res.json()["message"].lower()

    # Attempting to refresh with the logged-out refresh token must be rejected
    refresh_res = client.post(
        "/api/auth/refresh",
        json={"refresh_token": tokens["refresh_token"]},
    )
    assert refresh_res.status_code == 401


def test_unauthorized_profile_access(client: TestClient):
    """Test accessing /api/auth/me without token returns 401."""
    response = client.get("/api/auth/me")
    assert response.status_code == 401


def test_profile_update(client: TestClient):
    """Test authenticated user can update name and phone number."""
    client.post(
        "/api/auth/register",
        json={"name": "Initial Name", "email": "profile@example.com", "password": "Password123!"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "profile@example.com", "password": "Password123!"},
    )
    token = login_res.json()["access_token"]

    # Update profile
    update_res = client.put(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
        json={"name": "Updated Name", "phone": "+1-555-0199"},
    )
    assert update_res.status_code == 200
    data = update_res.json()
    assert data["name"] == "Updated Name"
    assert data["phone"] == "+1-555-0199"

    # Confirm persistence
    get_res = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert get_res.json()["name"] == "Updated Name"
    assert get_res.json()["phone"] == "+1-555-0199"


def test_password_change_workflow(client: TestClient):
    """Test secure password change workflow requires correct current password and revokes old tokens."""
    client.post(
        "/api/auth/register",
        json={"name": "PW Changer", "email": "pwchange@example.com", "password": "OriginalPassword123"},
    )
    login_res = client.post(
        "/api/auth/login",
        json={"email": "pwchange@example.com", "password": "OriginalPassword123"},
    )
    old_tokens = login_res.json()

    # Attempt change with incorrect current password
    fail_res = client.post(
        "/api/auth/change-password",
        headers={"Authorization": f"Bearer {old_tokens['access_token']}"},
        json={"current_password": "WrongPassword999", "new_password": "NewValidPassword456"},
    )
    assert fail_res.status_code == 400
    assert "incorrect" in fail_res.json()["detail"].lower()

    # Change with correct current password
    success_res = client.post(
        "/api/auth/change-password",
        headers={"Authorization": f"Bearer {old_tokens['access_token']}"},
        json={"current_password": "OriginalPassword123", "new_password": "NewValidPassword456"},
    )
    assert success_res.status_code == 200

    # Old refresh token should now be revoked
    refresh_fail = client.post(
        "/api/auth/refresh",
        json={"refresh_token": old_tokens["refresh_token"]},
    )
    assert refresh_fail.status_code == 401

    # Login with old password must fail
    old_login_fail = client.post(
        "/api/auth/login",
        json={"email": "pwchange@example.com", "password": "OriginalPassword123"},
    )
    assert old_login_fail.status_code == 401

    # Login with new password must succeed
    new_login_success = client.post(
        "/api/auth/login",
        json={"email": "pwchange@example.com", "password": "NewValidPassword456"},
    )
    assert new_login_success.status_code == 200
    assert "access_token" in new_login_success.json()


def test_admin_authorization(client: TestClient, db_session: Session):
    """Test that admin endpoints allow admin users but reject standard users with 403 Forbidden."""
    # Create standard user
    client.post(
        "/api/auth/register",
        json={"name": "Normal User", "email": "normal@example.com", "password": "Password123!"},
    )
    login_normal = client.post(
        "/api/auth/login",
        json={"email": "normal@example.com", "password": "Password123!"},
    )
    normal_token = login_normal.json()["access_token"]

    # Normal user accesses admin endpoint -> 403 Forbidden
    res_forbidden = client.get(
        "/api/test-admin-only",
        headers={"Authorization": f"Bearer {normal_token}"},
    )
    assert res_forbidden.status_code == 403
    assert "privileges" in res_forbidden.json()["detail"].lower()

    # Promote user to admin in DB
    user = db_session.query(User).filter(User.email == "normal@example.com").first()
    user.role = "admin"
    db_session.commit()

    # Re-access admin endpoint -> 200 OK
    res_allowed = client.get(
        "/api/test-admin-only",
        headers={"Authorization": f"Bearer {normal_token}"},
    )
    assert res_allowed.status_code == 200
    assert res_allowed.json()["message"] == "Admin access granted"
