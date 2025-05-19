from web3 import Web3
from typing import List, Dict, Any, Optional, Union
import os
import json
import logging
import requests
from dotenv import load_dotenv
import time
from eth_account.messages import encode_defunct
from web3.middleware import geth_poa_middleware

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

class BlockchainService:
    """Enhanced blockchain service with multi-chain support and integrations"""
    
    def __init__(self):
        # Initialize RPC connections
        self.rpc_endpoints = {
            "ethereum": os.getenv("ETHEREUM_RPC", "https://mainnet.infura.io/v3/your-project-id"),
            "polygon": os.getenv("POLYGON_RPC", "https://polygon-rpc.com"),
            "arbitrum": os.getenv("ARBITRUM_RPC", "https://arb1.arbitrum.io/rpc"),
            "optimism": os.getenv("OPTIMISM_RPC", "https://mainnet.optimism.io"),
            "base": os.getenv("BASE_RPC", "https://mainnet.base.org")
        }
        
        # Initialize Web3 providers
        self.providers = {}
        for network, rpc in self.rpc_endpoints.items():
            try:
                provider = Web3(Web3.HTTPProvider(rpc))
                # Apply middleware for PoA chains
                if network in ["polygon", "optimism", "base"]:
                    provider.middleware_onion.inject(geth_poa_middleware, layer=0)
                self.providers[network] = provider
                logger.info(f"Connected to {network}: {provider.is_connected()}")
            except Exception as e:
                logger.error(f"Failed to connect to {network}: {str(e)}")
                self.providers[network] = None
        
        # Load contract ABIs
        self.abis = self._load_abis()
        
        # Initialize contract addresses
        self.contract_addresses = {
            "ethereum": {
                "assetVault": os.getenv("ETH_ASSET_VAULT"),
                "crossChainManager": os.getenv("ETH_CROSS_CHAIN_MANAGER"),
                "governanceToken": os.getenv("ETH_GOVERNANCE_TOKEN"),
                "governor": os.getenv("ETH_GOVERNOR"),
                "timelock": os.getenv("ETH_TIMELOCK")
            },
            "polygon": {
                "assetVault": os.getenv("POLYGON_ASSET_VAULT"),
                "crossChainManager": os.getenv("POLYGON_CROSS_CHAIN_MANAGER")
            },
            "arbitrum": {
                "assetVault": os.getenv("ARBITRUM_ASSET_VAULT"),
                "crossChainManager": os.getenv("ARBITRUM_CROSS_CHAIN_MANAGER")
            }
        }
        
        # Initialize price feed cache
        self.price_cache = {}
        self.price_cache_expiry = {}
        self.price_cache_ttl = 300  # 5 minutes
        
        # Initialize Chainlink data
        self.chainlink_feeds = {
            "ethereum": {
                "ETH/USD": "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419",
                "BTC/USD": "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c",
                "LINK/USD": "0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c"
            },
            "polygon": {
                "MATIC/USD": "0xAB594600376Ec9fD91F8e885dADF0CE036862dE0",
                "ETH/USD": "0xF9680D99D6C9589e2a93a78A04A279e509205945"
            }
        }
        
        # Initialize TheGraph endpoints
        self.graph_endpoints = {
            "ethereum": os.getenv("GRAPH_ENDPOINT_ETH", "https://api.thegraph.com/subgraphs/name/chainfinity/ethereum"),
            "polygon": os.getenv("GRAPH_ENDPOINT_POLYGON", "https://api.thegraph.com/subgraphs/name/chainfinity/polygon")
        }
        
        # Initialize Tenderly API
        self.tenderly_api_key = os.getenv("TENDERLY_API_KEY")
        self.tenderly_account = os.getenv("TENDERLY_ACCOUNT")
        self.tenderly_project = os.getenv("TENDERLY_PROJECT")
        
    def _load_abis(self) -> Dict[str, Any]:
        """Load contract ABIs from files"""
        abi_dir = os.path.join(os.path.dirname(__file__), "../blockchain/contracts/abis")
        abis = {}
        
        try:
            # Ensure directory exists
            os.makedirs(abi_dir, exist_ok=True)
            
            # Define standard ABIs for common operations
            abis["ERC20"] = [
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
                },
                {
                    "constant": False,
                    "inputs": [
                        {"name": "_spender", "type": "address"},
                        {"name": "_value", "type": "uint256"}
                    ],
                    "name": "approve",
                    "outputs": [{"name": "", "type": "bool"}],
                    "type": "function"
                },
                {
                    "constant": True,
                    "inputs": [
                        {"name": "_owner", "type": "address"},
                        {"name": "_spender", "type": "address"}
                    ],
                    "name": "allowance",
                    "outputs": [{"name": "", "type": "uint256"}],
                    "type": "function"
                }
            ]
            
            # Load ABIs from files if they exist
            for contract_name in ["AssetVault", "CrossChainManager", "GovernanceToken", "ChainFinityGovernor", "ChainFinityTimelock"]:
                file_path = os.path.join(abi_dir, f"{contract_name}.json")
                if os.path.exists(file_path):
                    with open(file_path, 'r') as f:
                        abis[contract_name] = json.load(f)
                else:
                    logger.warning(f"ABI file not found: {file_path}")
            
            return abis
            
        except Exception as e:
            logger.error(f"Error loading ABIs: {str(e)}")
            return {"ERC20": abis["ERC20"]} if "ERC20" in abis else {}
    
    def get_contract(self, contract_name: str, network: str = "ethereum") -> Optional[Any]:
        """Get contract instance by name and network"""
        try:
            if network not in self.providers or not self.providers[network]:
                raise ValueError(f"No provider available for network: {network}")
                
            if network not in self.contract_addresses or contract_name not in self.contract_addresses[network]:
                raise ValueError(f"Contract address not found for {contract_name} on {network}")
                
            address = self.contract_addresses[network][contract_name]
            if not address:
                raise ValueError(f"Contract address is empty for {contract_name} on {network}")
                
            abi_key = contract_name if contract_name in self.abis else "ERC20"
            if abi_key not in self.abis:
                raise ValueError(f"ABI not found for {contract_name}")
                
            return self.providers[network].eth.contract(
                address=address,
                abi=self.abis[abi_key]
            )
            
        except Exception as e:
            logger.error(f"Error getting contract {contract_name} on {network}: {str(e)}")
            return None
    
    def get_eth_balance(self, address: str, network: str = "ethereum") -> float:
        """Get native token balance for an address"""
        try:
            if network not in self.providers or not self.providers[network]:
                raise ValueError(f"No provider available for network: {network}")
                
            balance_wei = self.providers[network].eth.get_balance(address)
            return self.providers[network].from_wei(balance_wei, 'ether')
            
        except Exception as e:
            logger.error(f"Error getting balance on {network}: {str(e)}")
            return 0.0
    
    def get_token_balance(self, token_address: str, wallet_address: str, network: str = "ethereum") -> Dict[str, Any]:
        """Get token balance for a specific token"""
        try:
            if network not in self.providers or not self.providers[network]:
                raise ValueError(f"No provider available for network: {network}")
                
            w3 = self.providers[network]
            contract = w3.eth.contract(address=token_address, abi=self.abis["ERC20"])
            
            balance = contract.functions.balanceOf(wallet_address).call()
            decimals = contract.functions.decimals().call()
            symbol = contract.functions.symbol().call()
            
            return {
                "balance": balance / (10 ** decimals),
                "raw_balance": balance,
                "symbol": symbol,
                "decimals": decimals
            }
            
        except Exception as e:
            logger.error(f"Error getting token balance: {str(e)}")
            return {"balance": 0.0, "raw_balance": 0, "symbol": "UNKNOWN", "decimals": 18}
    
    def get_token_price(self, token_symbol: str, quote_currency: str = "USD") -> Optional[float]:
        """Get token price from cache or external API"""
        cache_key = f"{token_symbol}/{quote_currency}"
        current_time = time.time()
        
        # Return cached price if valid
        if cache_key in self.price_cache and current_time < self.price_cache_expiry.get(cache_key, 0):
            return self.price_cache[cache_key]
            
        try:
            # Try Chainlink price feed first
            price = self._get_chainlink_price(token_symbol, quote_currency)
            
            # Fall back to CoinGecko if Chainlink fails
            if price is None:
                price = self._get_coingecko_price(token_symbol, quote_currency)
                
            if price is not None:
                # Update cache
                self.price_cache[cache_key] = price
                self.price_cache_expiry[cache_key] = current_time + self.price_cache_ttl
                
            return price
            
        except Exception as e:
            logger.error(f"Error getting price for {token_symbol}: {str(e)}")
            return None
    
    def _get_chainlink_price(self, token_symbol: str, quote_currency: str = "USD") -> Optional[float]:
        """Get price from Chainlink oracle"""
        feed_key = f"{token_symbol}/{quote_currency}"
        
        for network, feeds in self.chainlink_feeds.items():
            if feed_key in feeds and network in self.providers and self.providers[network]:
                try:
                    w3 = self.providers[network]
                    abi = [
                        {
                            "inputs": [],
                            "name": "latestRoundData",
                            "outputs": [
                                {"name": "roundId", "type": "uint80"},
                                {"name": "answer", "type": "int256"},
                                {"name": "startedAt", "type": "uint256"},
                                {"name": "updatedAt", "type": "uint256"},
                                {"name": "answeredInRound", "type": "uint80"}
                            ],
                            "stateMutability": "view",
                            "type": "function"
                        },
                        {
                            "inputs": [],
                            "name": "decimals",
                            "outputs": [{"name": "", "type": "uint8"}],
                            "stateMutability": "view",
                            "type": "function"
                        }
                    ]
                    
                    contract = w3.eth.contract(address=feeds[feed_key], abi=abi)
                    latest_data = contract.functions.latestRoundData().call()
                    decimals = contract.functions.decimals().call()
                    
                    # Price with proper decimal handling
                    return latest_data[1] / (10 ** decimals)
                    
                except Exception as e:
                    logger.error(f"Error getting Chainlink price for {feed_key}: {str(e)}")
        
        return None
    
    def _get_coingecko_price(self, token_symbol: str, quote_currency: str = "USD") -> Optional[float]:
        """Get price from CoinGecko API"""
        try:
            # Map common symbols to CoinGecko IDs
            symbol_to_id = {
                "BTC": "bitcoin",
                "ETH": "ethereum",
                "LINK": "chainlink",
                "MATIC": "matic-network",
                "AAVE": "aave",
                "UNI": "uniswap",
                "CFG": "chainfinity-governance"  # This would need to be registered with CoinGecko
            }
            
            token_id = symbol_to_id.get(token_symbol.upper())
            if not token_id:
                return None
                
            quote_currency = quote_currency.lower()
            url = f"https://api.coingecko.com/api/v3/simple/price?ids={token_id}&vs_currencies={quote_currency}"
            
            response = requests.get(url, timeout=10)
            data = response.json()
            
            if token_id in data and quote_currency in data[token_id]:
                return float(data[token_id][quote_currency])
                
            return None
            
        except Exception as e:
            logger.error(f"Error getting CoinGecko price for {token_symbol}: {str(e)}")
            return None
    
    def get_portfolio_value(self, wallet_address: str, networks: List[str] = None) -> Dict[str, Any]:
        """Get total portfolio value across multiple networks"""
        if networks is None:
            networks = ["ethereum", "polygon", "arbitrum"]
            
        result = {
            "total_value_usd": 0.0,
            "networks": {},
            "assets": []
        }
        
        for network in networks:
            if network not in self.providers or not self.providers[network]:
                continue
                
            network_value = 0.0
            network_assets = []
            
            # Get native token balance
            native_balance = self.get_eth_balance(wallet_address, network)
            native_symbol = "ETH"
            if network == "polygon":
                native_symbol = "MATIC"
            elif network == "arbitrum":
                native_symbol = "ETH"  # Arbitrum uses ETH
                
            native_price = self.get_token_price(native_symbol)
            native_value = native_balance * (native_price or 0)
            network_value += native_value
            
            network_assets.append({
                "symbol": native_symbol,
                "balance": native_balance,
                "price_usd": native_price,
                "value_usd": native_value,
                "token_address": None,
                "type": "native"
            })
            
            # Get token balances from AssetVault if available
            try:
                vault_contract = self.get_contract("assetVault", network)
                if vault_contract:
                    user_assets = vault_contract.functions.getUserAssets(wallet_address).call()
                    
                    for asset in user_assets:
                        token_address = asset[0]
                        token_amount = asset[1]
                        
                        # Get token details
                        token_data = self.get_token_balance(token_address, wallet_address, network)
                        token_symbol = token_data["symbol"]
                        token_decimals = token_data["decimals"]
                        
                        # Calculate value
                        token_price = self.get_token_price(token_symbol)
                        token_value = (token_amount / (10 ** token_decimals)) * (token_price or 0)
                        network_value += token_value
                        
                        network_assets.append({
                            "symbol": token_symbol,
                            "balance": token_amount / (10 ** token_decimals),
                            "price_usd": token_price,
                            "value_usd": token_value,
                            "token_address": token_address,
                            "type": "erc20"
                        })
            except Exception as e:
                logger.error(f"Error getting vault assets on {network}: {str(e)}")
            
            # Add network data to result
            result["networks"][network] = {
                "value_usd": network_value,
                "assets": network_assets
            }
            
            # Add assets to global list
            result["assets"].extend(network_assets)
            
            # Update total value
            result["total_value_usd"] += network_value
        
        return result
    
    def get_governance_data(self, network: str = "ethereum") -> Dict[str, Any]:
        """Get governance data including proposals and voting power"""
        result = {
            "token_info": {},
            "governance_info": {},
            "proposals": [],
            "voting_power": {}
        }
        
        try:
            # Get governance token info
            token_contract = self.get_contract("governanceToken", network)
            if token_contract:
                result["token_info"] = {
                    "name": token_contract.functions.name().call(),
                    "symbol": token_contract.functions.symbol().call(),
                    "total_supply": token_contract.functions.totalSupply().call() / (10 ** 18),
                    "decimals": 18
                }
            
            # Get governor contract info
            governor_contract = self.get_contract("governor", network)
            if governor_contract:
                result["governance_info"] = {
                    "voting_delay": governor_contract.functions.votingDelay().call(),
                    "voting_period": governor_contract.functions.votingPeriod().call(),
                    "proposal_threshold": governor_contract.functions.proposalThreshold().call() / (10 ** 18),
                    "quorum_numerator": 4  # Default value, would be fetched from contract
                }
                
                # Get proposals from TheGraph
                proposals = self._get_proposals_from_graph(network)
                if proposals:
                    result["proposals"] = proposals
        except Exception as e:
            logger.error(f"Error getting governance data: {str(e)}")
        
        return result
    
    def _get_proposals_from_graph(self, network: str) -> List[Dict[str, Any]]:
        """Get proposals from TheGraph"""
        if network not in self.graph_endpoints:
            return []
            
        try:
            query = """
            {
              proposals(first: 10, orderBy: startBlock, orderDirection: desc) {
                id
                proposer
                description
                status
                forVotes
                againstVotes
                abstainVotes
                startBlock
                endBlock
                eta
                executed
              }
            }
            """
            
            response = requests.post(
                self.graph_endpoints[network],
                json={"query": query},
                timeout=10
            )
            
            data = response.json()
            if "data" in data and "proposals" in data["data"]:
                return data["data"]["proposals"]
                
            return []
            
        except Exception as e:
            logger.error(f"Error querying TheGraph: {str(e)}")
            return []
    
    def simulate_transaction(self, from_address: str, to_address: str, data: str, value: int = 0, network: str = "ethereum") -> Dict[str, Any]:
        """Simulate transaction using Tenderly API"""
        if not self.tenderly_api_key:
            return {"success": False, "error": "Tenderly API key not configured"}
            
        try:
            url = f"https://api.tenderly.co/api/v1/account/{self.tenderly_account}/project/{self.tenderly_project}/simulate"
            headers = {
                "X-Access-Key": self.tenderly_api_key,
                "Content-Type": "application/json"
            }
            
            # Get network ID
            network_id = {
                "ethereum": 1,
                "polygon": 137,
                "arbitrum": 42161,
                "optimism": 10,
                "base": 8453
            }.get(network, 1)
            
            payload = {
                "network_id": network_id,
                "from": from_address,
                "to": to_address,
                "input": data,
                "value": value,
                "save": True
            }
            
            response = requests.post(url, headers=headers, json=payload, timeout=30)
            result = response.json()
            
            return {
                "success": "result" in result and result.get("result", {}).get("status", False),
                "gas_used": result.get("result", {}).get("gas_used", 0),
                "logs": result.get("result", {}).get("logs", []),
                "transaction_info": {
                    "hash": result.get("simulation", {}).get("id", ""),
                    "url": f"https://dashboard.tenderly.co/{self.tenderly_account}/{self.tenderly_project}/simulator/{result.get('simulation', {}).get('id', '')}"
                }
            }
            
        except Exception as e:
            logger.error(f"Error simulating transaction: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def verify_signature(self, message: str, signature: str, expected_address: str) -> bool:
        """Verify an Ethereum signature"""
        try:
            w3 = self.providers.get("ethereum")
            if not w3:
                return False
                
            message_hash = encode_defunct(text=message)
            recovered_address = w3.eth.account.recover_message(message_hash, signature=signature)
            
            return recovered_address.lower() == expected_address.lower()
            
        except Exception as e:
            logger.error(f"Error verifying signature: {str(e)}")
            return False
    
    def get_cross_chain_transfers(self, address: str, network: str = "ethereum") -> List[Dict[str, Any]]:
        """Get cross-chain transfers for an address"""
        try:
            ccm_contract = self.get_contract("crossChainManager", network)
            if not ccm_contract:
                return []
                
            # This is a simplified implementation
            # In production, you'd query events or use TheGraph
            return []
            
        except Exception as e:
            logger.error(f"Error getting cross-chain transfers: {str(e)}")
            return []
