#!/bin/bash
# ChainFinity Backend Startup Script

set -e

echo "🚀 Starting ChainFinity Backend..."
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install --quiet --no-input -r requirements.txt

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please update .env with your configuration before running in production!"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start the backend server, run:"
echo "  uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"
echo ""
echo "Or in production mode:"
echo "  uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4"
echo ""
