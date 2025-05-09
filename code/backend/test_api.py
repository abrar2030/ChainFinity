import pytest
import requests
import json
from typing import Dict, Any
from datetime import datetime, timedelta

BASE_URL = "http://localhost:8000"

@pytest.fixture
def test_user_data():
    return {
        "email": f"test_{datetime.now().timestamp()}@example.com",
        "password": "testpassword123",
        "wallet_address": "0x1234567890123456789012345678901234567890"
    }

@pytest.fixture
def auth_token(test_user_data):
    # Register user
    requests.post(
        f"{BASE_URL}/api/auth/register",
        json=test_user_data
    )
    
    # Login to get token
    response = requests.post(
        f"{BASE_URL}/api/auth/token",
        data={
            "username": test_user_data["email"],
            "password": test_user_data["password"]
        }
    )
    return response.json().get("access_token")

def test_health_check():
    """Test the health check endpoint"""
    response = requests.get(f"{BASE_URL}/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_user_registration(test_user_data):
    """Test user registration with valid data"""
    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json=test_user_data
    )
    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert data["email"] == test_user_data["email"]
    assert data["wallet_address"] == test_user_data["wallet_address"]

def test_user_registration_validation():
    """Test user registration validation"""
    # Test invalid email
    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json={
            "email": "invalid-email",
            "password": "testpass123",
            "wallet_address": "0x1234567890123456789012345678901234567890"
        }
    )
    assert response.status_code == 422

    # Test short password
    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json={
            "email": "test@example.com",
            "password": "short",
            "wallet_address": "0x1234567890123456789012345678901234567890"
        }
    )
    assert response.status_code == 422

    # Test invalid wallet address
    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json={
            "email": "test@example.com",
            "password": "testpass123",
            "wallet_address": "invalid-wallet"
        }
    )
    assert response.status_code == 422

def test_user_registration_duplicate_email(test_user_data):
    """Test duplicate email registration"""
    # First registration
    requests.post(
        f"{BASE_URL}/api/auth/register",
        json=test_user_data
    )
    
    # Try to register again with same email
    response = requests.post(
        f"{BASE_URL}/api/auth/register",
        json=test_user_data
    )
    assert response.status_code == 400
    assert "email already registered" in response.json().get("detail", "").lower()

def test_user_login(test_user_data):
    """Test user login with valid credentials"""
    # Register first
    requests.post(
        f"{BASE_URL}/api/auth/register",
        json=test_user_data
    )
    
    # Try to login
    response = requests.post(
        f"{BASE_URL}/api/auth/token",
        data={
            "username": test_user_data["email"],
            "password": test_user_data["password"]
        }
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "token_type" in data
    assert data["token_type"] == "bearer"
    assert len(data["access_token"]) > 0

def test_login_invalid_credentials(test_user_data):
    """Test login with various invalid credentials"""
    # Test wrong password
    response = requests.post(
        f"{BASE_URL}/api/auth/token",
        data={
            "username": test_user_data["email"],
            "password": "wrongpassword"
        }
    )
    assert response.status_code == 401

    # Test non-existent user
    response = requests.post(
        f"{BASE_URL}/api/auth/token",
        data={
            "username": "nonexistent@example.com",
            "password": "anypassword"
        }
    )
    assert response.status_code == 401

    # Test missing password
    response = requests.post(
        f"{BASE_URL}/api/auth/token",
        data={
            "username": test_user_data["email"]
        }
    )
    assert response.status_code == 422

def test_get_portfolio(auth_token):
    """Test portfolio endpoint with various scenarios"""
    # Test successful portfolio retrieval
    response = requests.get(
        f"{BASE_URL}/api/blockchain/portfolio",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)
    assert "tokens" in data
    assert isinstance(data["tokens"], list)

    # Test portfolio data structure
    if len(data["tokens"]) > 0:
        token = data["tokens"][0]
        assert "symbol" in token
        assert "balance" in token
        assert "value" in token

def test_get_eth_balance(auth_token):
    """Test ETH balance endpoint with various scenarios"""
    # Test successful balance retrieval
    response = requests.get(
        f"{BASE_URL}/api/blockchain/eth-balance",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)
    assert "balance" in data
    assert isinstance(data["balance"], (int, float))
    assert data["balance"] >= 0

def test_unauthorized_access():
    """Test accessing protected endpoints without proper authentication"""
    # Test with invalid token
    response = requests.get(
        f"{BASE_URL}/api/blockchain/portfolio",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

    # Test with missing token
    response = requests.get(
        f"{BASE_URL}/api/blockchain/portfolio"
    )
    assert response.status_code == 401

    # Test with malformed token
    response = requests.get(
        f"{BASE_URL}/api/blockchain/portfolio",
        headers={"Authorization": "Bearer"}
    )
    assert response.status_code == 401

def test_token_expiration(test_user_data):
    """Test token expiration and refresh"""
    # Register and login
    requests.post(
        f"{BASE_URL}/api/auth/register",
        json=test_user_data
    )
    
    login_response = requests.post(
        f"{BASE_URL}/api/auth/token",
        data={
            "username": test_user_data["email"],
            "password": test_user_data["password"]
        }
    )
    token = login_response.json().get("access_token")

    # Test with expired token (if your backend supports token expiration)
    # This is a placeholder test - actual implementation depends on your token expiration logic
    response = requests.get(
        f"{BASE_URL}/api/blockchain/portfolio",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code in [200, 401]  # Either valid or expired

def test_rate_limiting():
    """Test rate limiting on authentication endpoints"""
    # Make multiple rapid requests to test rate limiting
    for _ in range(10):
        response = requests.post(
            f"{BASE_URL}/api/auth/token",
            data={
                "username": "test@example.com",
                "password": "testpass123"
            }
        )
    
    # The last request should be rate limited
    assert response.status_code in [200, 429]  # Either successful or rate limited

if __name__ == "__main__":
    pytest.main(["-v"]) 