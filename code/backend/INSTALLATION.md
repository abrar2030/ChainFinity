# ChainFinity Backend - Installation and Startup Guide

## Quick Start (Without Database)

The backend can now be imported and the API structure can be verified without a database connection:

```bash
cd code/backend
python3 test_startup.py
```

## Full Installation

### 1. Install Dependencies

```bash
# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install email-validator qrcode pillow
```

### 2. Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Or use the provided .env file for development
# Edit .env with your configuration if needed
```

### 3. Start Services (Docker Compose - Recommended)

```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Wait for services to be ready (about 10 seconds)
sleep 10
```

### 4. Run Database Migrations

```bash
# Run migrations
alembic upgrade head
```

### 5. Start the Application

```bash
# Development mode with auto-reload
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Or use the startup script
./start.sh
```

## Alternative: Start Without External Dependencies

If you don't have PostgreSQL/Redis, the app will start but database operations will fail:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Access the API documentation at: http://localhost:8000/docs

## API Endpoints

The backend includes the following endpoint groups:

- **/api/v1/auth** - Authentication (register, login, logout, MFA)
- **/api/v1/users** - User management and profiles
- **/api/v1/portfolios** - Portfolio management
- **/api/v1/transactions** - Transaction tracking
- **/api/v1/compliance** - Compliance checks and audit logs
- **/api/v1/risk** - Risk assessment and metrics
- **/api/v1/blockchain** - Blockchain network and contract information

## Health Check

```bash
curl http://localhost:8000/health
```

## Testing

```bash
# Run tests (requires test dependencies)
pytest

# With coverage
pytest --cov=app --cov-report=html
```

## Troubleshooting

### Issue: Module import errors

**Solution**: Ensure all dependencies are installed:

```bash
pip install -r requirements.txt
pip install email-validator qrcode pillow
```

### Issue: Database connection errors

**Solution**: Verify PostgreSQL is running:

```bash
docker-compose ps
```

### Issue: Redis connection errors

**Solution**: Check Redis status:

```bash
docker-compose logs redis
```

## Production Deployment

For production deployment, see DEPLOYMENT.md for detailed instructions including:

- Docker containerization
- Kubernetes deployment
- Environment configuration
- Security best practices
