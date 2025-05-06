#!/bin/bash

# ChainFinity Project Setup Script

# Exit immediately if a command exits with a non-zero status.
set -e

# Prerequisites (ensure these are installed and configured):
# - Python 3.x (the script will use python3.11 available in the environment)
# - pip (Python package installer)
# - Node.js (for frontend, mobile-frontend, and blockchain components)
# - npm (Node package manager)
# - Docker & Docker Compose (for running services via docker-compose.prod.yml)
# - TimescaleDB (ensure it's running and accessible if not using Dockerized version)
# - Redis (ensure it's running and accessible if not using Dockerized version)
# - Hardhat (globally or as a project dependency for blockchain tasks: `npm install -g hardhat` or similar)

echo "Starting ChainFinity project setup..."

PROJECT_DIR="/home/ubuntu/projects_extracted/ChainFinity"

if [ ! -d "${PROJECT_DIR}" ]; then
  echo "Error: Project directory ${PROJECT_DIR} not found."
  echo "Please ensure the project is extracted correctly."
  exit 1
fi

cd "${PROJECT_DIR}"
echo "Changed directory to $(pwd)"

# --- Environment Configuration (.env file) ---
echo ""
echo "IMPORTANT: Configure environment variables."
if [ -f ".env.example" ]; then
    echo "An .env.example file exists in ${PROJECT_DIR}.
    echo "Please copy it to .env (cp .env.example .env) and fill in your API keys, chain configurations, database credentials, etc."
elif [ -f ".env" ]; then
    echo "An .env file already exists. Please ensure it is correctly configured."
else
    echo "Warning: No .env.example or .env file found in ${PROJECT_DIR}. Manual configuration of environment variables might be required as per project documentation."
fi

# --- AI Models Setup (Python) ---
echo ""
echo "Setting up ChainFinity AI Models environment..."
AI_MODELS_DIR="${PROJECT_DIR}/code/ai_models"

if [ ! -d "${AI_MODELS_DIR}" ]; then
    echo "Warning: AI Models directory ${AI_MODELS_DIR} not found. Skipping AI models setup."
else
    cd "${AI_MODELS_DIR}"
    echo "Changed directory to $(pwd) for AI Models setup."

    if [ ! -f "requirements.txt" ]; then
        echo "Warning: requirements.txt not found in ${AI_MODELS_DIR}. Skipping Python dependency installation for AI Models."
    else
        echo "Creating Python virtual environment for AI Models (venv_chainfinity_ai)..."
        if ! python3.11 -m venv venv_chainfinity_ai; then
            echo "Failed to create AI Models virtual environment. Please check your Python installation."
        else
            source venv_chainfinity_ai/bin/activate
            echo "AI Models Python virtual environment created and activated."
            echo "Installing AI Models Python dependencies from requirements.txt..."
            pip3 install -r requirements.txt
            echo "AI Models dependencies installed."
            echo "To activate the AI Models virtual environment later, run: source ${AI_MODELS_DIR}/venv_chainfinity_ai/bin/activate"
            deactivate
            echo "AI Models virtual environment deactivated."
        fi
    fi
    cd "${PROJECT_DIR}" # Return to the main project directory
fi

# --- Backend Setup (Python/FastAPI) ---
echo ""
echo "Setting up ChainFinity Backend environment..."
BACKEND_DIR="${PROJECT_DIR}/code/backend"

if [ ! -d "${BACKEND_DIR}" ]; then
    echo "Warning: Backend directory ${BACKEND_DIR} not found. Skipping Backend setup."
else
    cd "${BACKEND_DIR}"
    echo "Changed directory to $(pwd) for Backend setup."

    if [ ! -f "requirements.txt" ]; then
        echo "Warning: requirements.txt not found in ${BACKEND_DIR}. Skipping Python dependency installation for Backend."
    else
        echo "Creating Python virtual environment for Backend (venv_chainfinity_backend)..."
        if ! python3.11 -m venv venv_chainfinity_backend; then
            echo "Failed to create Backend Python virtual environment. Please check your Python installation."
        else
            source venv_chainfinity_backend/bin/activate
            echo "Backend Python virtual environment created and activated."
            echo "Installing Backend Python dependencies from requirements.txt..."
            pip3 install -r requirements.txt
            echo "Backend dependencies installed."
            echo "To activate the Backend Python virtual environment later, run: source ${BACKEND_DIR}/venv_chainfinity_backend/bin/activate"
            echo "To run the backend (from ${BACKEND_DIR} with venv activated): uvicorn app:app --reload (as per README)"
            deactivate
            echo "Backend Python virtual environment deactivated."
        fi
    fi
    cd "${PROJECT_DIR}" # Return to the main project directory
fi

# --- Web Frontend Setup (React) ---
echo ""
echo "Setting up ChainFinity Web Frontend environment..."
WEB_FRONTEND_DIR="${PROJECT_DIR}/code/web-frontend"

if [ ! -d "${WEB_FRONTEND_DIR}" ]; then
    echo "Warning: Web Frontend directory ${WEB_FRONTEND_DIR} not found. Skipping Web Frontend setup."
else
    cd "${WEB_FRONTEND_DIR}"
    echo "Changed directory to $(pwd) for Web Frontend setup."

    if [ ! -f "package.json" ]; then
        echo "Warning: package.json not found in ${WEB_FRONTEND_DIR}. Skipping Node.js dependency installation for Web Frontend."
    else
        echo "Installing Web Frontend Node.js dependencies using npm..."
        if ! command -v npm &> /dev/null; then echo "npm command not found."; else npm install; fi
        echo "Web Frontend dependencies installed."
        echo "To start the Web Frontend (from ${WEB_FRONTEND_DIR}): npm start (as per README)"
    fi
    cd "${PROJECT_DIR}" # Return to the main project directory
fi

# --- Mobile Frontend Setup (Next.js) ---
echo ""
echo "Setting up ChainFinity Mobile Frontend environment..."
MOBILE_FRONTEND_DIR="${PROJECT_DIR}/mobile-frontend"

if [ ! -d "${MOBILE_FRONTEND_DIR}" ]; then
    echo "Warning: Mobile Frontend directory ${MOBILE_FRONTEND_DIR} not found. Skipping Mobile Frontend setup."
else
    cd "${MOBILE_FRONTEND_DIR}"
    echo "Changed directory to $(pwd) for Mobile Frontend setup."

    if [ ! -f "package.json" ]; then
        echo "Warning: package.json not found in ${MOBILE_FRONTEND_DIR}. Skipping Node.js dependency installation for Mobile Frontend."
    else
        echo "Installing Mobile Frontend Node.js dependencies using npm (or pnpm if specified by packageManager in package.json)..."
        # Check for pnpm in package.json, otherwise use npm
        if grep -q "pnpm" package.json && command -v pnpm &> /dev/null; then
            pnpm install
            echo "Mobile Frontend dependencies installed using pnpm."
            echo "To start the Mobile Frontend (from ${MOBILE_FRONTEND_DIR}): pnpm dev (or as per its scripts)"
        elif command -v npm &> /dev/null; then
            npm install
            echo "Mobile Frontend dependencies installed using npm."
            echo "To start the Mobile Frontend (from ${MOBILE_FRONTEND_DIR}): npm run dev (or as per its scripts)"
        else
            echo "Neither pnpm nor npm command found, or package.json doesn't specify pnpm. Please install dependencies manually."
        fi
    fi
    cd "${PROJECT_DIR}" # Return to the main project directory
fi

# --- Blockchain Setup (Node.js/Hardhat) ---
echo ""
echo "Setting up ChainFinity Blockchain environment..."
# README says 'cd blockchain && npm install'. Let's check for this directory structure.
# The `ls -a` output for ChainFinity root did not show a top-level `blockchain` dir.
# Let's assume it might be under `code/` or the README refers to a structure not perfectly matching the zip.
BLOCKCHAIN_DIR_CODE="${PROJECT_DIR}/code/blockchain"
BLOCKCHAIN_DIR_ROOT="${PROJECT_DIR}/blockchain"
ACTUAL_BLOCKCHAIN_DIR=""

if [ -d "${BLOCKCHAIN_DIR_ROOT}" ] && [ -f "${BLOCKCHAIN_DIR_ROOT}/package.json" ]; then
    ACTUAL_BLOCKCHAIN_DIR="${BLOCKCHAIN_DIR_ROOT}"
elif [ -d "${BLOCKCHAIN_DIR_CODE}" ] && [ -f "${BLOCKCHAIN_DIR_CODE}/package.json" ]; then
    ACTUAL_BLOCKCHAIN_DIR="${BLOCKCHAIN_DIR_CODE}"
fi

if [ -n "${ACTUAL_BLOCKCHAIN_DIR}" ]; then
    cd "${ACTUAL_BLOCKCHAIN_DIR}"
    echo "Changed directory to $(pwd) for Blockchain setup."
    echo "Installing Blockchain Node.js dependencies using npm..."
    if ! command -v npm &> /dev/null; then echo "npm command not found."; else npm install; fi
    echo "Blockchain dependencies installed."
    echo "To run a local Hardhat node (from ${ACTUAL_BLOCKCHAIN_DIR}): npx hardhat node (as per README)"
    echo "To deploy contracts (from ${ACTUAL_BLOCKCHAIN_DIR}): npx hardhat deploy --network <your_network> --tags <your_tags>"
    cd "${PROJECT_DIR}" # Return to the main project directory
else
    echo "Warning: Blockchain directory with package.json not found at ${BLOCKCHAIN_DIR_ROOT} or ${BLOCKCHAIN_DIR_CODE} as suggested by README."
    echo "Manual setup for blockchain components might be required. The README mentions: 'cd blockchain && npm install' and 'npx hardhat ...' commands."
fi

# --- Docker Compose ---
echo ""
echo "Docker Compose for running services:"
DOCKER_COMPOSE_FILE="${PROJECT_DIR}/infrastructure/docker-compose.prod.yml"
if [ -f "${DOCKER_COMPOSE_FILE}" ]; then
    echo "A Docker Compose file is available at: ${DOCKER_COMPOSE_FILE}"
    echo "To start services using Docker Compose (ensure Docker daemon is running):"
    echo "  cd ${PROJECT_DIR} && docker-compose -f infrastructure/docker-compose.prod.yml up -d"
else
    echo "Warning: Docker Compose file ${DOCKER_COMPOSE_FILE} mentioned in README not found. Dockerized setup might not be directly available."
fi

# --- General Instructions & Reminders ---
echo ""
echo "ChainFinity project setup script finished."
echo "Please ensure all prerequisites are met: Python, Node.js, npm/pnpm, Docker, Docker Compose, TimescaleDB, Redis, Hardhat."
echo "Remember to configure your .env file in ${PROJECT_DIR} with necessary API keys, database connections, and blockchain details."
echo "Refer to the project's README.md for detailed instructions on training AI models, deploying contracts, deploying subgraphs, applying infrastructure with Terraform, and monitoring."

echo "Key commands from README to remember (execute from appropriate directories and with active venvs where needed):"
echo "  AI Model Training: python ai_models/train_correlation_model.py --data ./market_data.csv"
echo "  Contract Deployment: npx hardhat deploy --network arbitrum --tags CrossChainManager (from blockchain dir)"
echo "  Subgraph Deployment: graph deploy --node https://api.thegraph.com/deploy/ ccamp (ensure graph-cli is installed)"
echo "  Terraform: cd infrastructure/terraform && terraform init && terraform apply -auto-approve"

echo "Setup complete. Review warnings and consult README for next steps."
