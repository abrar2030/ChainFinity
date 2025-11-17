"""
Integration tests for authentication endpoints
"""

import pytest
from fastapi import status
from httpx import AsyncClient


class TestAuthEndpoints:
    """Test cases for authentication endpoints"""

    @pytest.mark.asyncio
    async def test_register_user_success(
        self, async_client: AsyncClient, sample_user_data
    ):
        """Test successful user registration"""
        response = await async_client.post(
            "/api/v1/auth/register", json=sample_user_data
        )

        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["email"] == sample_user_data["email"]
        assert "id" in data
        assert "hashed_password" not in data  # Should not expose password

    @pytest.mark.asyncio
    async def test_register_user_invalid_email(
        self, async_client: AsyncClient, sample_user_data
    ):
        """Test registration with invalid email"""
        sample_user_data["email"] = "invalid-email"

        response = await async_client.post(
            "/api/v1/auth/register", json=sample_user_data
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
        data = response.json()
        assert "validation error" in data["error"].lower()

    @pytest.mark.asyncio
    async def test_register_user_weak_password(
        self, async_client: AsyncClient, sample_user_data
    ):
        """Test registration with weak password"""
        sample_user_data["password"] = "weak"
        sample_user_data["confirm_password"] = "weak"

        response = await async_client.post(
            "/api/v1/auth/register", json=sample_user_data
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    @pytest.mark.asyncio
    async def test_register_user_password_mismatch(
        self, async_client: AsyncClient, sample_user_data
    ):
        """Test registration with password mismatch"""
        sample_user_data["confirm_password"] = "DifferentPassword123!"

        response = await async_client.post(
            "/api/v1/auth/register", json=sample_user_data
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    @pytest.mark.asyncio
    async def test_login_success(self, async_client: AsyncClient, test_user):
        """Test successful login"""
        login_data = {"email": test_user.email, "password": "testpassword"}

        response = await async_client.post("/api/v1/auth/login", json=login_data)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
        assert "expires_in" in data

    @pytest.mark.asyncio
    async def test_login_invalid_credentials(
        self, async_client: AsyncClient, test_user
    ):
        """Test login with invalid credentials"""
        login_data = {"email": test_user.email, "password": "wrongpassword"}

        response = await async_client.post("/api/v1/auth/login", json=login_data)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        data = response.json()
        assert "invalid credentials" in data["error"].lower()

    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, async_client: AsyncClient):
        """Test login with nonexistent user"""
        login_data = {"email": "nonexistent@example.com", "password": "testpassword"}

        response = await async_client.post("/api/v1/auth/login", json=login_data)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    @pytest.mark.asyncio
    async def test_get_current_user(
        self, async_client: AsyncClient, test_user, auth_headers
    ):
        """Test getting current user information"""
        response = await async_client.get("/api/v1/auth/me", headers=auth_headers)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["id"] == str(test_user.id)
        assert data["email"] == test_user.email
        assert "hashed_password" not in data

    @pytest.mark.asyncio
    async def test_get_current_user_invalid_token(self, async_client: AsyncClient):
        """Test getting current user with invalid token"""
        headers = {"Authorization": "Bearer invalid_token"}

        response = await async_client.get("/api/v1/auth/me", headers=headers)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    @pytest.mark.asyncio
    async def test_get_current_user_no_token(self, async_client: AsyncClient):
        """Test getting current user without token"""
        response = await async_client.get("/api/v1/auth/me")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    @pytest.mark.asyncio
    async def test_change_password_success(
        self, async_client: AsyncClient, test_user, auth_headers
    ):
        """Test successful password change"""
        password_data = {
            "current_password": "testpassword",
            "new_password": "NewPassword123!",
            "confirm_password": "NewPassword123!",
        }

        response = await async_client.post(
            "/api/v1/auth/change-password", json=password_data, headers=auth_headers
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["success"] is True
        assert "changed successfully" in data["message"]

    @pytest.mark.asyncio
    async def test_change_password_invalid_current(
        self, async_client: AsyncClient, test_user, auth_headers
    ):
        """Test password change with invalid current password"""
        password_data = {
            "current_password": "wrongpassword",
            "new_password": "NewPassword123!",
            "confirm_password": "NewPassword123!",
        }

        response = await async_client.post(
            "/api/v1/auth/change-password", json=password_data, headers=auth_headers
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    @pytest.mark.asyncio
    async def test_logout_success(
        self, async_client: AsyncClient, test_user, auth_headers
    ):
        """Test successful logout"""
        response = await async_client.post("/api/v1/auth/logout", headers=auth_headers)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["success"] is True
        assert "logged out" in data["message"].lower()

    @pytest.mark.asyncio
    async def test_logout_invalid_token(self, async_client: AsyncClient):
        """Test logout with invalid token"""
        headers = {"Authorization": "Bearer invalid_token"}

        response = await async_client.post("/api/v1/auth/logout", headers=headers)

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    @pytest.mark.asyncio
    async def test_oauth2_login_form(self, async_client: AsyncClient, test_user):
        """Test OAuth2 compatible login form"""
        form_data = {"username": test_user.email, "password": "testpassword"}

        response = await async_client.post(
            "/api/v1/auth/login/form",
            data=form_data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
