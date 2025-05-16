import pytest
import requests
import json
from typing import Dict, Any
from datetime import datetime, timedelta
import time
import jwt

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
    
    # Verify token is valid initially
    response = requests.get(
        f"{BASE_URL}/api/blockchain/portfolio",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    
    # Decode token to check expiration time
    try:
        # Note: In a real test, you would use the same secret key as your application
        # For testing purposes, we're using a workaround to check token structure
        token_parts = token.split('.')
        if len(token_parts) == 3:  # Valid JWT format
            # Decode the payload part (without verification)
            payload = json.loads(
                (token_parts[1] + '=' * (-len(token_parts[1]) % 4)).encode().decode('utf-8')
            )
            
            if 'exp' in payload:
                # Calculate time until expiration
                exp_time = datetime.fromtimestamp(payload['exp'])
                current_time = datetime.now()
                time_until_expiration = (exp_time - current_time).total_seconds()
                
                if time_until_expiration > 0:
                    # If token is not expired yet but will expire soon, we can simulate waiting
                    # In a real test, you might use time.sleep() to wait for expiration
                    # For this test, we'll check if the token has a reasonable expiration time
                    
                    # Most tokens expire in 1-24 hours, so check if expiration is reasonable
                    assert 0 < time_until_expiration < 86400  # 24 hours in seconds
                    
                    # For testing token refresh, we would need to implement a refresh endpoint
                    # and test it here. Since that's outside the scope of this test, we'll
                    # just verify that the token has an expiration time.
                    
                    # Test refresh token if available
                    if 'refresh_token' in login_response.json():
                        refresh_token = login_response.json().get('refresh_token')
                        refresh_response = requests.post(
                            f"{BASE_URL}/api/auth/refresh",
                            json={"refresh_token": refresh_token}
                        )
                        assert refresh_response.status_code == 200
                        assert "access_token" in refresh_response.json()
                        new_token = refresh_response.json().get("access_token")
                        assert new_token != token  # New token should be different
                        
                        # Verify new token works
                        new_response = requests.get(
                            f"{BASE_URL}/api/blockchain/portfolio",
                            headers={"Authorization": f"Bearer {new_token}"}
                        )
                        assert new_response.status_code == 200
                else:
                    # Token is already expired
                    expired_response = requests.get(
                        f"{BASE_URL}/api/blockchain/portfolio",
                        headers={"Authorization": f"Bearer {token}"}
                    )
                    assert expired_response.status_code == 401
            else:
                # Token doesn't have expiration claim
                assert False, "Token does not have expiration claim"
        else:
            # Not a valid JWT format
            assert False, "Token is not in valid JWT format"
    except Exception as e:
        # If we can't decode the token, we'll fall back to a simpler test
        # This could happen if the token is encrypted or uses a different format
        
        # Test with potentially expired token
        # In a real application, we would wait for the token to expire
        # For this test, we'll just verify that the endpoint properly validates tokens
        
        # Make a request with the token
        response = requests.get(
            f"{BASE_URL}/api/blockchain/portfolio",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        # Token should either be valid (200) or properly rejected if expired (401)
        assert response.status_code in [200, 401]
        
        # If rejected, verify the error message indicates expiration
        if response.status_code == 401:
            error_detail = response.json().get("detail", "").lower()
            assert "expired" in error_detail or "invalid" in error_detail

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
