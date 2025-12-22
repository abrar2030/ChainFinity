#!/usr/bin/env bash
# Startup script for ChainFinity Backend

set -e

echo "=== ChainFinity Backend Startup ==="

# Check Python version
echo "Checking Python version..."
python3 --version

# Check if virtual environment exists, create if not
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Warning: .env file not found. Using default settings."
    echo "Please create .env file from .env.example for production use."
fi

echo ""
echo "=== Starting ChainFinity Backend ==="
echo "API will be available at: http://localhost:8000"
echo "API Documentation: http://localhost:8000/docs"
echo ""

# Start the application
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
