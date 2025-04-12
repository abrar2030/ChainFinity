import requests
import json
from typing import Dict, Any

BASE_URL = "http://localhost:8000"

def test_health_check() -> bool:
    """Test the health check endpoint"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        return response.status_code == 200 and response.json()["status"] == "healthy"
    except Exception as e:
        print(f"Health check test failed: {e}")
        return False

def test_user_registration(email: str, password: str, wallet_address: str) -> Dict[str, Any]:
    """Test user registration"""
    try:
        response = requests.post(
            f"{BASE_URL}/api/auth/register",
            json={
                "email": email,
                "password": password,
                "wallet_address": wallet_address
            }
        )
        return response.json()
    except Exception as e:
        print(f"Registration test failed: {e}")
        return {}

def test_user_login(email: str, password: str) -> Dict[str, Any]:
    """Test user login"""
    try:
        response = requests.post(
            f"{BASE_URL}/api/auth/token",
            data={
                "username": email,
                "password": password
            }
        )
        return response.json()
    except Exception as e:
        print(f"Login test failed: {e}")
        return {}

def test_get_portfolio(token: str) -> Dict[str, Any]:
    """Test portfolio endpoint"""
    try:
        response = requests.get(
            f"{BASE_URL}/api/blockchain/portfolio",
            headers={"Authorization": f"Bearer {token}"}
        )
        return response.json()
    except Exception as e:
        print(f"Portfolio test failed: {e}")
        return {}

def test_get_eth_balance(token: str) -> Dict[str, Any]:
    """Test ETH balance endpoint"""
    try:
        response = requests.get(
            f"{BASE_URL}/api/blockchain/eth-balance",
            headers={"Authorization": f"Bearer {token}"}
        )
        return response.json()
    except Exception as e:
        print(f"ETH balance test failed: {e}")
        return {}

def run_tests():
    """Run all tests"""
    print("Running API tests...")
    
    # Test health check
    print("\n1. Testing health check...")
    health_check_result = test_health_check()
    print(f"Health check: {'✓' if health_check_result else '✗'}")
    
    # Test user registration
    print("\n2. Testing user registration...")
    test_email = "test@example.com"
    test_password = "testpassword123"
    test_wallet = "0x1234567890123456789012345678901234567890"
    registration_result = test_user_registration(test_email, test_password, test_wallet)
    print(f"Registration: {'✓' if registration_result else '✗'}")
    
    # Test user login
    print("\n3. Testing user login...")
    login_result = test_user_login(test_email, test_password)
    token = login_result.get("access_token", "")
    print(f"Login: {'✓' if token else '✗'}")
    
    if token:
        # Test portfolio endpoint
        print("\n4. Testing portfolio endpoint...")
        portfolio_result = test_get_portfolio(token)
        print(f"Portfolio: {'✓' if portfolio_result else '✗'}")
        
        # Test ETH balance endpoint
        print("\n5. Testing ETH balance endpoint...")
        eth_balance_result = test_get_eth_balance(token)
        print(f"ETH Balance: {'✓' if eth_balance_result else '✗'}")
    
    print("\nTests completed!")

if __name__ == "__main__":
    run_tests() 