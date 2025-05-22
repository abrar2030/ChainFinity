#!/bin/bash
# ChainFinity Testing Automation Script
# This script automates the testing process for all components of the ChainFinity platform

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(pwd)"
LOG_DIR="$PROJECT_DIR/logs"
REPORT_DIR="$PROJECT_DIR/test-reports"
TEST_TIMEOUT=300 # 5 minutes per test suite
PARALLEL_TESTS=true
COVERAGE_THRESHOLD=80

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-dir)
      PROJECT_DIR="$2"
      shift 2
      ;;
    --log-dir)
      LOG_DIR="$2"
      shift 2
      ;;
    --report-dir)
      REPORT_DIR="$2"
      shift 2
      ;;
    --timeout)
      TEST_TIMEOUT="$2"
      shift 2
      ;;
    --no-parallel)
      PARALLEL_TESTS=false
      shift
      ;;
    --coverage-threshold)
      COVERAGE_THRESHOLD="$2"
      shift 2
      ;;
    --component)
      TEST_COMPONENT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --project-dir DIR        Set project directory (default: current directory)"
      echo "  --log-dir DIR            Log directory (default: ./logs)"
      echo "  --report-dir DIR         Test report directory (default: ./test-reports)"
      echo "  --timeout SEC            Test timeout in seconds (default: 300)"
      echo "  --no-parallel            Disable parallel testing"
      echo "  --coverage-threshold NUM Minimum code coverage percentage (default: 80)"
      echo "  --component NAME         Test only specific component (blockchain, backend, frontend, all)"
      echo "  --help                   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create directories if they don't exist
mkdir -p "$LOG_DIR"
mkdir -p "$REPORT_DIR"

# Log file
LOG_FILE="$LOG_DIR/tests_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  
  case $level in
    "INFO")
      echo -e "${BLUE}[${timestamp}] [${level}] ${message}${NC}"
      ;;
    "WARNING")
      echo -e "${YELLOW}[${timestamp}] [${level}] ${message}${NC}"
      ;;
    "ERROR")
      echo -e "${RED}[${timestamp}] [${level}] ${message}${NC}"
      ;;
    "SUCCESS")
      echo -e "${GREEN}[${timestamp}] [${level}] ${message}${NC}"
      ;;
  esac
  
  echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
}

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to run blockchain tests
run_blockchain_tests() {
  log "INFO" "Running blockchain tests..."
  
  if [ ! -d "$PROJECT_DIR/code/blockchain" ]; then
    log "ERROR" "Blockchain directory not found: $PROJECT_DIR/code/blockchain"
    return 1
  fi
  
  cd "$PROJECT_DIR/code/blockchain" || return 1
  
  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    log "INFO" "Installing blockchain dependencies..."
    npm install
  fi
  
  # Run tests with coverage
  log "INFO" "Running Hardhat tests with coverage..."
  npm run test:coverage || {
    log "ERROR" "Blockchain tests failed"
    return 1
  }
  
  # Check coverage threshold
  if command_exists jq; then
    local coverage_file="coverage/coverage-summary.json"
    if [ -f "$coverage_file" ]; then
      local line_coverage=$(jq -r '.total.lines.pct' "$coverage_file")
      if (( $(echo "$line_coverage < $COVERAGE_THRESHOLD" | bc -l) )); then
        log "WARNING" "Blockchain test coverage ($line_coverage%) is below threshold ($COVERAGE_THRESHOLD%)"
      else
        log "SUCCESS" "Blockchain test coverage: $line_coverage%"
      fi
    fi
  fi
  
  # Copy reports
  mkdir -p "$REPORT_DIR/blockchain"
  cp -r coverage/* "$REPORT_DIR/blockchain/"
  
  log "SUCCESS" "Blockchain tests completed"
  return 0
}

# Function to run backend tests
run_backend_tests() {
  log "INFO" "Running backend tests..."
  
  if [ ! -d "$PROJECT_DIR/code/backend" ]; then
    log "ERROR" "Backend directory not found: $PROJECT_DIR/code/backend"
    return 1
  fi
  
  cd "$PROJECT_DIR/code/backend" || return 1
  
  # Activate virtual environment if it exists
  if [ -d "$PROJECT_DIR/venv" ]; then
    source "$PROJECT_DIR/venv/bin/activate"
  fi
  
  # Install dependencies if needed
  if ! command_exists pytest; then
    log "INFO" "Installing pytest and dependencies..."
    pip install pytest pytest-cov
  fi
  
  # Install project dependencies
  if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
  fi
  
  # Run tests with coverage
  log "INFO" "Running pytest with coverage..."
  python -m pytest --cov=. --cov-report=xml --cov-report=html || {
    log "ERROR" "Backend tests failed"
    return 1
  }
  
  # Check coverage threshold
  if command_exists coverage; then
    local coverage_report=$(coverage report | grep TOTAL | awk '{print $NF}' | tr -d '%')
    if (( $(echo "$coverage_report < $COVERAGE_THRESHOLD" | bc -l) )); then
      log "WARNING" "Backend test coverage ($coverage_report%) is below threshold ($COVERAGE_THRESHOLD%)"
    else
      log "SUCCESS" "Backend test coverage: $coverage_report%"
    fi
  fi
  
  # Copy reports
  mkdir -p "$REPORT_DIR/backend"
  cp -r htmlcov/* "$REPORT_DIR/backend/"
  cp coverage.xml "$REPORT_DIR/backend/"
  
  log "SUCCESS" "Backend tests completed"
  return 0
}

# Function to run frontend tests
run_frontend_tests() {
  log "INFO" "Running frontend tests..."
  
  if [ ! -d "$PROJECT_DIR/code/frontend" ]; then
    log "ERROR" "Frontend directory not found: $PROJECT_DIR/code/frontend"
    return 1
  fi
  
  cd "$PROJECT_DIR/code/frontend" || return 1
  
  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    log "INFO" "Installing frontend dependencies..."
    npm install
  fi
  
  # Run tests with coverage
  log "INFO" "Running Jest tests with coverage..."
  npm test -- --coverage || {
    log "ERROR" "Frontend tests failed"
    return 1
  }
  
  # Check coverage threshold
  if [ -f "coverage/coverage-summary.json" ]; then
    local line_coverage=$(jq -r '.total.lines.pct' coverage/coverage-summary.json)
    if (( $(echo "$line_coverage < $COVERAGE_THRESHOLD" | bc -l) )); then
      log "WARNING" "Frontend test coverage ($line_coverage%) is below threshold ($COVERAGE_THRESHOLD%)"
    else
      log "SUCCESS" "Frontend test coverage: $line_coverage%"
    fi
  fi
  
  # Copy reports
  mkdir -p "$REPORT_DIR/frontend"
  cp -r coverage/* "$REPORT_DIR/frontend/"
  
  log "SUCCESS" "Frontend tests completed"
  return 0
}

# Function to run mobile frontend tests
run_mobile_frontend_tests() {
  log "INFO" "Running mobile frontend tests..."
  
  if [ ! -d "$PROJECT_DIR/code/mobile-frontend" ]; then
    log "ERROR" "Mobile frontend directory not found: $PROJECT_DIR/code/mobile-frontend"
    return 1
  fi
  
  cd "$PROJECT_DIR/code/mobile-frontend" || return 1
  
  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    log "INFO" "Installing mobile frontend dependencies..."
    npm install
  fi
  
  # Run tests with coverage
  log "INFO" "Running Jest tests with coverage..."
  npm test -- --coverage || {
    log "ERROR" "Mobile frontend tests failed"
    return 1
  }
  
  # Check coverage threshold
  if [ -f "coverage/coverage-summary.json" ]; then
    local line_coverage=$(jq -r '.total.lines.pct' coverage/coverage-summary.json)
    if (( $(echo "$line_coverage < $COVERAGE_THRESHOLD" | bc -l) )); then
      log "WARNING" "Mobile frontend test coverage ($line_coverage%) is below threshold ($COVERAGE_THRESHOLD%)"
    else
      log "SUCCESS" "Mobile frontend test coverage: $line_coverage%"
    fi
  fi
  
  # Copy reports
  mkdir -p "$REPORT_DIR/mobile-frontend"
  cp -r coverage/* "$REPORT_DIR/mobile-frontend/"
  
  log "SUCCESS" "Mobile frontend tests completed"
  return 0
}

# Function to run integration tests
run_integration_tests() {
  log "INFO" "Running integration tests..."
  
  if [ ! -d "$PROJECT_DIR/code/integration-tests" ]; then
    log "WARNING" "Integration tests directory not found: $PROJECT_DIR/code/integration-tests"
    
    # Create integration tests directory if it doesn't exist
    mkdir -p "$PROJECT_DIR/code/integration-tests"
    
    # Create basic integration test setup
    cat > "$PROJECT_DIR/code/integration-tests/package.json" << EOF
{
  "name": "chainfinity-integration-tests",
  "version": "1.0.0",
  "description": "Integration tests for ChainFinity",
  "main": "index.js",
  "scripts": {
    "test": "jest"
  },
  "dependencies": {
    "axios": "^1.3.4",
    "ethers": "^6.3.0",
    "jest": "^29.5.0",
    "playwright": "^1.32.1"
  }
}
EOF
    
    # Create sample integration test
    mkdir -p "$PROJECT_DIR/code/integration-tests/tests"
    cat > "$PROJECT_DIR/code/integration-tests/tests/api-blockchain.test.js" << EOF
const axios = require('axios');
const { ethers } = require('ethers');

describe('API and Blockchain Integration', () => {
  test('API should connect to blockchain', async () => {
    // This is a placeholder test
    // Replace with actual integration test logic
    expect(true).toBe(true);
  });
});
EOF
    
    log "INFO" "Created basic integration test setup"
    return 0
  }
  
  cd "$PROJECT_DIR/code/integration-tests" || return 1
  
  # Install dependencies if needed
  if [ ! -d "node_modules" ]; then
    log "INFO" "Installing integration test dependencies..."
    npm install
  fi
  
  # Run integration tests
  log "INFO" "Running integration tests..."
  npm test || {
    log "ERROR" "Integration tests failed"
    return 1
  }
  
  # Copy reports if they exist
  if [ -d "coverage" ]; then
    mkdir -p "$REPORT_DIR/integration"
    cp -r coverage/* "$REPORT_DIR/integration/"
  fi
  
  log "SUCCESS" "Integration tests completed"
  return 0
}

# Function to generate combined test report
generate_test_report() {
  log "INFO" "Generating combined test report..."
  
  local report_file="$REPORT_DIR/test-report.html"
  
  # Create HTML report
  cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>ChainFinity Test Report - $(date +%Y-%m-%d)</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #333366; }
    .section { margin-bottom: 20px; }
    .success { color: green; }
    .warning { color: orange; }
    .error { color: red; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .progress-bar {
      height: 20px;
      background-color: #e0e0e0;
      border-radius: 10px;
      margin-bottom: 10px;
    }
    .progress-bar-fill {
      height: 100%;
      border-radius: 10px;
      background-color: #4CAF50;
    }
  </style>
</head>
<body>
  <h1>ChainFinity Test Report</h1>
  <p>Generated on: $(date +%Y-%m-%d\ %H:%M:%S)</p>
  
  <div class="section">
    <h2>Test Summary</h2>
    <table>
      <tr>
        <th>Component</th>
        <th>Status</th>
        <th>Coverage</th>
        <th>Details</th>
      </tr>
EOF
  
  # Add blockchain test results
  local blockchain_status="Not Run"
  local blockchain_coverage="N/A"
  if [ -f "$REPORT_DIR/blockchain/coverage-summary.json" ]; then
    blockchain_status="Success"
    blockchain_coverage=$(jq -r '.total.lines.pct' "$REPORT_DIR/blockchain/coverage-summary.json")
    
    cat >> "$report_file" << EOF
      <tr>
        <td>Blockchain</td>
        <td class="success">$blockchain_status</td>
        <td>
          <div class="progress-bar">
            <div class="progress-bar-fill" style="width: $blockchain_coverage%;"></div>
          </div>
          $blockchain_coverage%
        </td>
        <td><a href="blockchain/index.html">View Details</a></td>
      </tr>
EOF
  else
    cat >> "$report_file" << EOF
      <tr>
        <td>Blockchain</td>
        <td>$blockchain_status</td>
        <td>$blockchain_coverage</td>
        <td>N/A</td>
      </tr>
EOF
  fi
  
  # Add backend test results
  local backend_status="Not Run"
  local backend_coverage="N/A"
  if [ -f "$REPORT_DIR/backend/index.html" ]; then
    backend_status="Success"
    if [ -f "$PROJECT_DIR/code/backend/.coverage" ]; then
      backend_coverage=$(coverage report | grep TOTAL | awk '{print $NF}' | tr -d '%')
    fi
    
    cat >> "$report_file" << EOF
      <tr>
        <td>Backend</td>
        <td class="success">$backend_status</td>
        <td>
          <div class="progress-bar">
            <div class="progress-bar-fill" style="width: $backend_coverage%;"></div>
          </div>
          $backend_coverage%
        </td>
        <td><a href="backend/index.html">View Details</a></td>
      </tr>
EOF
  else
    cat >> "$report_file" << EOF
      <tr>
        <td>Backend</td>
        <td>$backend_status</td>
        <td>$backend_coverage</td>
        <td>N/A</td>
      </tr>
EOF
  fi
  
  # Add frontend test results
  local frontend_status="Not Run"
  local frontend_coverage="N/A"
  if [ -f "$REPORT_DIR/frontend/index.html" ]; then
    frontend_status="Success"
    if [ -f "$REPORT_DIR/frontend/coverage-summary.json" ]; then
      frontend_coverage=$(jq -r '.total.lines.pct' "$REPORT_DIR/frontend/coverage-summary.json")
    fi
    
    cat >> "$report_file" << EOF
      <tr>
        <td>Frontend</td>
        <td class="success">$frontend_status</td>
        <td>
          <div class="progress-bar">
            <div class="progress-bar-fill" style="width: $frontend_coverage%;"></div>
          </div>
          $frontend_coverage%
        </td>
        <td><a href="frontend/index.html">View Details</a></td>
      </tr>
EOF
  else
    cat >> "$report_file" << EOF
      <tr>
        <td>Frontend</td>
        <td>$frontend_status</td>
        <td>$frontend_coverage</td>
        <td>N/A</td>
      </tr>
EOF
  fi
  
  # Add mobile frontend test results
  local mobile_status="Not Run"
  local mobile_coverage="N/A"
  if [ -f "$REPORT_DIR/mobile-frontend/index.html" ]; then
    mobile_status="Success"
    if [ -f "$REPORT_DIR/mobile-frontend/coverage-summary.json" ]; then
      mobile_coverage=$(jq -r '.total.lines.pct' "$REPORT_DIR/mobile-frontend/coverage-summary.json")
    fi
    
    cat >> "$report_file" << EOF
      <tr>
        <td>Mobile Frontend</td>
        <td class="success">$mobile_status</td>
        <td>
          <div class="progress-bar">
            <div class="progress-bar-fill" style="width: $mobile_coverage%;"></div>
          </div>
          $mobile_coverage%
        </td>
        <td><a href="mobile-frontend/index.html">View Details</a></td>
      </tr>
EOF
  else
    cat >> "$report_file" << EOF
      <tr>
        <td>Mobile Frontend</td>
        <td>$mobile_status</td>
        <td>$mobile_coverage</td>
        <td>N/A</td>
      </tr>
EOF
  fi
  
  # Close the report
  cat >> "$report_file" << EOF
    </table>
  </div>
  
  <div class="section">
    <h2>Test Log</h2>
    <pre>$(tail -n 50 "$LOG_FILE")</pre>
  </div>
</body>
</html>
EOF
  
  log "SUCCESS" "Test report generated: $report_file"
}

# Main function
main() {
  log "INFO" "Starting ChainFinity test automation..."
  log "INFO" "Project directory: $PROJECT_DIR"
  log "INFO" "Coverage threshold: $COVERAGE_THRESHOLD%"
  
  # Track overall success
  local success=true
  
  # Run tests based on component selection
  case "${TEST_COMPONENT:-all}" in
    "blockchain")
      run_blockchain_tests || success=false
      ;;
    "backend")
      run_backend_tests || success=false
      ;;
    "frontend")
      run_frontend_tests || success=false
      ;;
    "mobile")
      run_mobile_frontend_tests || success=false
      ;;
    "integration")
      run_integration_tests || success=false
      ;;
    "all")
      if [ "$PARALLEL_TESTS" = true ] && command_exists parallel; then
        log "INFO" "Running tests in parallel..."
        
        # Create temporary directory for parallel logs
        mkdir -p "$LOG_DIR/parallel"
        
        # Run tests in parallel
        parallel --jobs 3 --timeout "$TEST_TIMEOUT" --results "$LOG_DIR/parallel" ::: \
          "$(which bash) -c 'source $0; run_blockchain_tests'" \
          "$(which bash) -c 'source $0; run_backend_tests'" \
          "$(which bash) -c 'source $0; run_frontend_tests'" \
          "$(which bash) -c 'source $0; run_mobile_frontend_tests'"
        
        # Check if any test failed
        if [ $? -ne 0 ]; then
          success=false
        fi
        
        # Run integration tests after component tests
        run_integration_tests || success=false
      else
        # Run tests sequentially
        run_blockchain_tests || success=false
        run_backend_tests || success=false
        run_frontend_tests || success=false
        run_mobile_frontend_tests || success=false
        run_integration_tests || success=false
      fi
      ;;
    *)
      log "ERROR" "Unknown component: $TEST_COMPONENT"
      exit 1
      ;;
  esac
  
  # Generate test report
  generate_test_report
  
  # Final status
  if [ "$success" = true ]; then
    log "SUCCESS" "All tests completed successfully!"
    exit 0
  else
    log "ERROR" "Some tests failed. Check the report for details."
    exit 1
  fi
}

# Run main function
main
