import os
import logging
import requests
from fastapi import FastAPI, Depends, HTTPException, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Dict, Any, Optional
from pydantic import BaseModel, Field
import time
from datetime import datetime, timedelta

from services.risk_engine import EnhancedRiskEngine
from services.auth import get_current_user, User
from blockchain import BlockchainService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="ChainFinity API",
    description="Enhanced API for ChainFinity blockchain governance platform",
    version="2.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
risk_engine = EnhancedRiskEngine()
blockchain_service = BlockchainService()

# Cache for API responses
response_cache = {}
cache_ttl = {}

# Models
class PortfolioRequest(BaseModel):
    address: str
    networks: List[str] = ["ethereum", "polygon", "arbitrum"]

class RiskScoreRequest(BaseModel):
    portfolio: Dict[str, float]
    market_conditions: Optional[Dict[str, float]] = None

class StressTestRequest(BaseModel):
    portfolio: Dict[str, float]
    scenarios: List[Dict[str, Any]]

class ProposalCreateRequest(BaseModel):
    title: str
    description: str
    actions: List[Dict[str, Any]]
    
class VoteRequest(BaseModel):
    proposal_id: str
    support: int  # 0=against, 1=for, 2=abstain
    
class DelegateRequest(BaseModel):
    delegatee: str

class TransferRequest(BaseModel):
    token: str
    amount: float
    target_chain_id: int
    target_address: str

# Cache decorator
def cached(ttl_seconds=300):
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Create cache key from function name and arguments
            key = f"{func.__name__}:{str(args)}:{str(kwargs)}"
            current_time = time.time()
            
            # Return cached response if valid
            if key in response_cache and current_time < cache_ttl.get(key, 0):
                return response_cache[key]
            
            # Call function and cache result
            result = func(*args, **kwargs)
            response_cache[key] = result
            cache_ttl[key] = current_time + ttl_seconds
            return result
        return wrapper
    return decorator

# Health check endpoint
@app.get("/health")
def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

# Portfolio endpoints
@app.post("/api/portfolio")
async def get_portfolio(request: PortfolioRequest, current_user: User = Depends(get_current_user)):
    try:
        portfolio = blockchain_service.get_portfolio_value(request.address, request.networks)
        return portfolio
    except Exception as e:
        logger.error(f"Error getting portfolio: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/portfolio/{address}")
@cached(ttl_seconds=60)
async def get_portfolio_by_address(address: str, networks: str = None):
    try:
        network_list = networks.split(",") if networks else ["ethereum", "polygon", "arbitrum"]
        portfolio = blockchain_service.get_portfolio_value(address, network_list)
        return portfolio
    except Exception as e:
        logger.error(f"Error getting portfolio: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Risk engine endpoints
@app.post("/api/risk/score")
async def calculate_risk_score(request: RiskScoreRequest, current_user: User = Depends(get_current_user)):
    try:
        # Update market data first
        if not risk_engine.market_data:
            # Mock market data update for demo
            mock_data = {asset: [100, 101, 99, 102] for asset in request.portfolio.keys()}
            risk_engine.update_market_data(mock_data)
            
        risk_score = risk_engine.risk_score(request.portfolio, request.market_conditions)
        return risk_score
    except Exception as e:
        logger.error(f"Error calculating risk score: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/risk/stress-test")
async def run_stress_test(request: StressTestRequest, current_user: User = Depends(get_current_user)):
    try:
        results = risk_engine.stress_test(request.portfolio, request.scenarios)
        return results
    except Exception as e:
        logger.error(f"Error running stress test: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/risk/report")
async def generate_risk_report(
    request: PortfolioRequest, 
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_user)
):
    try:
        # This would be a long-running task, so we run it in the background
        background_tasks.add_task(
            risk_engine.generate_risk_report, 
            blockchain_service.get_portfolio_value(request.address)
        )
        return {"status": "Report generation started", "report_id": f"report_{int(time.time())}"}
    except Exception as e:
        logger.error(f"Error generating risk report: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Governance endpoints
@app.get("/api/governance/data")
@cached(ttl_seconds=300)
async def get_governance_data(network: str = "ethereum"):
    try:
        data = blockchain_service.get_governance_data(network)
        return data
    except Exception as e:
        logger.error(f"Error getting governance data: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/governance/propose")
async def create_proposal(
    request: ProposalCreateRequest, 
    current_user: User = Depends(get_current_user)
):
    try:
        # This would interact with the blockchain in production
        return {
            "status": "success",
            "message": "Proposal created successfully",
            "proposal_id": f"proposal_{int(time.time())}"
        }
    except Exception as e:
        logger.error(f"Error creating proposal: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/governance/vote")
async def cast_vote(
    request: VoteRequest, 
    current_user: User = Depends(get_current_user)
):
    try:
        # This would interact with the blockchain in production
        return {
            "status": "success",
            "message": f"Vote cast successfully for proposal {request.proposal_id}"
        }
    except Exception as e:
        logger.error(f"Error casting vote: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/governance/delegate")
async def delegate_voting_power(
    request: DelegateRequest, 
    current_user: User = Depends(get_current_user)
):
    try:
        # This would interact with the blockchain in production
        return {
            "status": "success",
            "message": f"Voting power delegated to {request.delegatee}"
        }
    except Exception as e:
        logger.error(f"Error delegating voting power: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Cross-chain endpoints
@app.post("/api/cross-chain/transfer")
async def initiate_transfer(
    request: TransferRequest, 
    current_user: User = Depends(get_current_user)
):
    try:
        # This would interact with the blockchain in production
        return {
            "status": "success",
            "message": "Transfer initiated successfully",
            "transfer_id": f"transfer_{int(time.time())}"
        }
    except Exception as e:
        logger.error(f"Error initiating transfer: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/cross-chain/transfers/{address}")
@cached(ttl_seconds=60)
async def get_transfers(address: str, network: str = "ethereum"):
    try:
        transfers = blockchain_service.get_cross_chain_transfers(address, network)
        return {"transfers": transfers}
    except Exception as e:
        logger.error(f"Error getting transfers: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Transaction simulation endpoint
@app.post("/api/simulate")
async def simulate_transaction(
    from_address: str,
    to_address: str,
    data: str,
    value: int = 0,
    network: str = "ethereum",
    current_user: User = Depends(get_current_user)
):
    try:
        result = blockchain_service.simulate_transaction(
            from_address, to_address, data, value, network
        )
        return result
    except Exception as e:
        logger.error(f"Error simulating transaction: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Market data endpoints
@app.get("/api/market/price/{token}")
@cached(ttl_seconds=60)
async def get_token_price(token: str, quote_currency: str = "USD"):
    try:
        price = blockchain_service.get_token_price(token, quote_currency)
        if price is None:
            raise HTTPException(status_code=404, detail=f"Price not found for {token}")
        return {"token": token, "quote_currency": quote_currency, "price": price}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting token price: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Webhook for governance events
@app.post("/api/webhooks/governance")
async def governance_webhook(payload: Dict[str, Any]):
    try:
        # Process governance event
        event_type = payload.get("event_type")
        logger.info(f"Received governance event: {event_type}")
        
        # In production, this would trigger notifications or other actions
        return {"status": "success", "message": f"Processed {event_type} event"}
    except Exception as e:
        logger.error(f"Error processing webhook: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# GraphQL integration (simplified)
@app.post("/api/graph/query")
async def graph_query(query: str, network: str = "ethereum"):
    try:
        if network not in blockchain_service.graph_endpoints:
            raise HTTPException(status_code=400, detail=f"Graph endpoint not configured for {network}")
            
        response = requests.post(
            blockchain_service.graph_endpoints[network],
            json={"query": query},
            timeout=10
        )
        
        return response.json()
    except Exception as e:
        logger.error(f"Error querying graph: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Error handler
@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": "An unexpected error occurred. Please try again later."}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
