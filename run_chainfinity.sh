#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting ChainFinity Application...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for required commands
if ! command_exists npm || ! command_exists python3 || ! command_exists docker; then
    echo -e "${YELLOW}Please ensure you have npm, python3, and docker installed.${NC}"
    exit 1
fi

# Start infrastructure services
echo -e "${GREEN}Starting infrastructure services...${NC}"
docker-compose -f infrastructure/docker-compose.prod.yml up -d

# Start blockchain node in background
echo -e "${GREEN}Starting blockchain node...${NC}"
cd code/blockchain
npx hardhat node &
BLOCKCHAIN_PID=$!
cd ../..

# Start backend server in background
echo -e "${GREEN}Starting backend server...${NC}"
cd code/backend
python3 -m uvicorn app:app --reload &
BACKEND_PID=$!
cd ../..

# Start frontend application in background
echo -e "${GREEN}Starting frontend application...${NC}"
cd code/frontend
npm start &
FRONTEND_PID=$!
cd ../..

echo -e "${GREEN}All services started!${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "${GREEN}Stopping all services...${NC}"
    kill $BLOCKCHAIN_PID $BACKEND_PID $FRONTEND_PID
    docker-compose -f infrastructure/docker-compose.prod.yml down
    exit 0
}

# Trap Ctrl+C and call cleanup
trap cleanup SIGINT

# Keep script running
while true; do
    sleep 1
done 