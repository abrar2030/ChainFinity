from web3 import Web3
from typing import List, Dict, Any
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Web3 connections
ETHEREUM_RPC = os.getenv("ETHEREUM_RPC", "https://mainnet.infura.io/v3/your-project-id")
POLYGON_RPC = os.getenv("POLYGON_RPC", "https://polygon-rpc.com")

w3_eth = Web3(Web3.HTTPProvider(ETHEREUM_RPC))
w3_poly = Web3(Web3.HTTPProvider(POLYGON_RPC))

# ERC20 ABI for token interactions
ERC20_ABI = [
    {
        "constant": True,
        "inputs": [{"name": "_owner", "type": "address"}],
        "name": "balanceOf",
        "outputs": [{"name": "balance", "type": "uint256"}],
        "type": "function"
    },
    {
        "constant": True,
        "inputs": [],
        "name": "decimals",
        "outputs": [{"name": "", "type": "uint8"}],
        "type": "function"
    },
    {
        "constant": True,
        "inputs": [],
        "name": "symbol",
        "outputs": [{"name": "", "type": "string"}],
        "type": "function"
    }
]

def get_eth_balance(address: str) -> float:
    """Get ETH balance for an address"""
    try:
        balance_wei = w3_eth.eth.get_balance(address)
        return w3_eth.from_wei(balance_wei, 'ether')
    except Exception as e:
        print(f"Error getting ETH balance: {e}")
        return 0.0

def get_token_balance(token_address: str, wallet_address: str, network: str = "ethereum") -> Dict[str, Any]:
    """Get token balance for a specific token"""
    try:
        w3 = w3_eth if network == "ethereum" else w3_poly
        contract = w3.eth.contract(address=token_address, abi=ERC20_ABI)
        
        balance = contract.functions.balanceOf(wallet_address).call()
        decimals = contract.functions.decimals().call()
        symbol = contract.functions.symbol().call()
        
        return {
            "balance": balance / (10 ** decimals),
            "symbol": symbol,
            "decimals": decimals
        }
    except Exception as e:
        print(f"Error getting token balance: {e}")
        return {"balance": 0.0, "symbol": "UNKNOWN", "decimals": 18}

def get_transactions(address: str, network: str = "ethereum", limit: int = 10) -> List[Dict[str, Any]]:
    """Get recent transactions for an address"""
    try:
        w3 = w3_eth if network == "ethereum" else w3_poly
        # Note: This is a simplified version. In production, you'd want to use a service like Etherscan API
        # or similar for better transaction history
        return []
    except Exception as e:
        print(f"Error getting transactions: {e}")
        return []

def get_portfolio_value(wallet_address: str) -> Dict[str, Any]:
    """Get total portfolio value including ETH and tokens"""
    try:
        eth_balance = get_eth_balance(wallet_address)
        # Add logic to fetch token balances from a predefined list of tokens
        # This is a simplified version
        return {
            "total_value": eth_balance,  # In production, add token values
            "assets": [
                {
                    "symbol": "ETH",
                    "balance": eth_balance,
                    "value_usd": eth_balance * 2000  # Example price, use real price feed
                }
            ]
        }
    except Exception as e:
        print(f"Error getting portfolio value: {e}")
        return {"total_value": 0.0, "assets": []} 