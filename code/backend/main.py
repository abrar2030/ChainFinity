from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

from database import engine, Base
from auth_routes import router as auth_router
from blockchain_routes import router as blockchain_router

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="ChainFinity API",
    description="API for ChainFinity - A blockchain portfolio tracker",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/api/auth", tags=["authentication"])
app.include_router(blockchain_router, prefix="/api/blockchain", tags=["blockchain"])

# Health check endpoint
@app.get("/health")
async def health_check():
    return JSONResponse(
        content={"status": "healthy"},
        status_code=200
    )

# Root endpoint
@app.get("/")
async def root():
    return {
        "message": "Welcome to ChainFinity API",
        "docs_url": "/docs",
        "redoc_url": "/redoc"
    } 