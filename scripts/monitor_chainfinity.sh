#!/bin/bash
# ChainFinity Monitoring Script
# This script provides comprehensive monitoring for the ChainFinity platform
# including infrastructure, services, and blockchain components

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE="monitor_config.json"
LOG_DIR="./logs"
ALERT_THRESHOLD=80
CHECK_INTERVAL=300 # 5 minutes
REPORT_INTERVAL=86400 # 24 hours
SLACK_WEBHOOK=""
EMAIL_RECIPIENT=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    --log-dir)
      LOG_DIR="$2"
      shift 2
      ;;
    --alert-threshold)
      ALERT_THRESHOLD="$2"
      shift 2
      ;;
    --check-interval)
      CHECK_INTERVAL="$2"
      shift 2
      ;;
    --report-interval)
      REPORT_INTERVAL="$2"
      shift 2
      ;;
    --slack-webhook)
      SLACK_WEBHOOK="$2"
      shift 2
      ;;
    --email)
      EMAIL_RECIPIENT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --config FILE           Configuration file path (default: monitor_config.json)"
      echo "  --log-dir DIR           Log directory (default: ./logs)"
      echo "  --alert-threshold NUM   Alert threshold percentage (default: 80)"
      echo "  --check-interval SEC    Check interval in seconds (default: 300)"
      echo "  --report-interval SEC   Report interval in seconds (default: 86400)"
      echo "  --slack-webhook URL     Slack webhook URL for notifications"
      echo "  --email ADDRESS         Email address for notifications"
      echo "  --help                  Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log file
LOG_FILE="$LOG_DIR/monitor_$(date +%Y%m%d).log"

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

# Function to send alerts
send_alert() {
  local subject="$1"
  local message="$2"
  local severity="$3" # critical, warning, info
  
  log "WARNING" "Alert: $subject - $message"
  
  # Send to Slack if configured
  if [ -n "$SLACK_WEBHOOK" ]; then
    local color
    case $severity in
      "critical") color="#FF0000" ;; # Red
      "warning") color="#FFA500" ;; # Orange
      "info") color="#0000FF" ;; # Blue
      *) color="#808080" ;; # Gray
    esac
    
    curl -s -X POST -H 'Content-type: application/json' \
      --data "{\"attachments\":[{\"color\":\"$color\",\"title\":\"$subject\",\"text\":\"$message\"}]}" \
      "$SLACK_WEBHOOK"
  fi
  
  # Send email if configured
  if [ -n "$EMAIL_RECIPIENT" ]; then
    echo "$message" | mail -s "ChainFinity Monitor: $subject" "$EMAIL_RECIPIENT"
  fi
}

# Function to check system resources
check_system_resources() {
  log "INFO" "Checking system resources..."
  
  # Check CPU usage
  local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
  if (( $(echo "$cpu_usage > $ALERT_THRESHOLD" | bc -l) )); then
    send_alert "High CPU Usage" "CPU usage is at ${cpu_usage}%" "warning"
  fi
  
  # Check memory usage
  local mem_total=$(free -m | awk '/Mem:/ {print $2}')
  local mem_used=$(free -m | awk '/Mem:/ {print $3}')
  local mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
  
  if (( $(echo "$mem_usage > $ALERT_THRESHOLD" | bc -l) )); then
    send_alert "High Memory Usage" "Memory usage is at ${mem_usage}%" "warning"
  fi
  
  # Check disk usage
  local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
  if [ "$disk_usage" -gt "$ALERT_THRESHOLD" ]; then
    send_alert "High Disk Usage" "Disk usage is at ${disk_usage}%" "warning"
  fi
  
  log "SUCCESS" "System resource check completed"
}

# Function to check Docker containers
check_docker_containers() {
  log "INFO" "Checking Docker containers..."
  
  if ! command -v docker &> /dev/null; then
    log "WARNING" "Docker is not installed"
    return
  fi
  
  # Get all containers
  local containers=$(docker ps -a --format "{{.Names}}")
  
  for container in $containers; do
    local status=$(docker inspect --format='{{.State.Status}}' "$container")
    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' "$container")
    
    if [ "$status" != "running" ]; then
      send_alert "Container Not Running" "Container $container is $status" "critical"
    elif [ "$health" == "unhealthy" ]; then
      send_alert "Unhealthy Container" "Container $container is unhealthy" "critical"
    fi
    
    # Check container resource usage
    local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container" | tr -d '%')
    local mem_usage=$(docker stats --no-stream --format "{{.MemPerc}}" "$container" | tr -d '%')
    
    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD" | bc -l) )); then
      send_alert "High Container CPU Usage" "Container $container CPU usage is at ${cpu_usage}%" "warning"
    fi
    
    if (( $(echo "$mem_usage > $ALERT_THRESHOLD" | bc -l) )); then
      send_alert "High Container Memory Usage" "Container $container memory usage is at ${mem_usage}%" "warning"
    fi
  done
  
  log "SUCCESS" "Docker container check completed"
}

# Function to check database health
check_database_health() {
  log "INFO" "Checking database health..."
  
  # Check PostgreSQL
  if command -v psql &> /dev/null; then
    if ! psql -h localhost -U postgres -c "SELECT 1" &> /dev/null; then
      send_alert "Database Connection Failed" "Cannot connect to PostgreSQL database" "critical"
    else
      # Check database size
      local db_size=$(psql -h localhost -U postgres -t -c "SELECT pg_size_pretty(pg_database_size('chainfinity'))" | tr -d ' ')
      log "INFO" "Database size: $db_size"
      
      # Check connection count
      local connections=$(psql -h localhost -U postgres -t -c "SELECT count(*) FROM pg_stat_activity" | tr -d ' ')
      if [ "$connections" -gt 100 ]; then
        send_alert "High Database Connections" "PostgreSQL has $connections active connections" "warning"
      fi
      
      # Check long-running queries
      local long_queries=$(psql -h localhost -U postgres -t -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND now() - query_start > interval '5 minutes'" | tr -d ' ')
      if [ "$long_queries" -gt 0 ]; then
        send_alert "Long-Running Queries" "PostgreSQL has $long_queries queries running for more than 5 minutes" "warning"
      fi
    fi
  fi
  
  # Check Redis
  if command -v redis-cli &> /dev/null; then
    if ! redis-cli ping &> /dev/null; then
      send_alert "Redis Connection Failed" "Cannot connect to Redis" "critical"
    else
      # Check Redis memory usage
      local redis_memory=$(redis-cli info memory | grep "used_memory_human:" | cut -d: -f2 | tr -d '[:space:]')
      log "INFO" "Redis memory usage: $redis_memory"
      
      # Check Redis clients
      local redis_clients=$(redis-cli info clients | grep "connected_clients:" | cut -d: -f2 | tr -d '[:space:]')
      if [ "$redis_clients" -gt 100 ]; then
        send_alert "High Redis Connections" "Redis has $redis_clients connected clients" "warning"
      fi
    fi
  fi
  
  log "SUCCESS" "Database health check completed"
}

# Function to check API endpoints
check_api_endpoints() {
  log "INFO" "Checking API endpoints..."
  
  # Load endpoints from config
  if [ -f "$CONFIG_FILE" ]; then
    local endpoints=$(jq -r '.api_endpoints[] | .url' "$CONFIG_FILE")
    
    for endpoint in $endpoints; do
      local response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint")
      
      if [ "$response" != "200" ]; then
        local endpoint_name=$(jq -r ".api_endpoints[] | select(.url == \"$endpoint\") | .name" "$CONFIG_FILE")
        send_alert "API Endpoint Down" "Endpoint $endpoint_name ($endpoint) returned status code $response" "critical"
      fi
    done
  else
    log "WARNING" "Config file not found: $CONFIG_FILE"
  fi
  
  log "SUCCESS" "API endpoint check completed"
}

# Function to check blockchain nodes
check_blockchain_nodes() {
  log "INFO" "Checking blockchain nodes..."
  
  # Load blockchain nodes from config
  if [ -f "$CONFIG_FILE" ]; then
    local nodes=$(jq -r '.blockchain_nodes[] | .url' "$CONFIG_FILE")
    
    for node in $nodes; do
      local node_name=$(jq -r ".blockchain_nodes[] | select(.url == \"$node\") | .name" "$CONFIG_FILE")
      local node_type=$(jq -r ".blockchain_nodes[] | select(.url == \"$node\") | .type" "$CONFIG_FILE")
      
      case $node_type in
        "ethereum")
          # Check Ethereum node
          local response=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' "$node")
          if ! echo "$response" | jq -e '.result' &> /dev/null; then
            send_alert "Blockchain Node Down" "Ethereum node $node_name ($node) is not responding correctly" "critical"
          else
            local block_number=$(echo "$response" | jq -r '.result' | sed 's/0x//')
            local block_decimal=$((16#$block_number))
            log "INFO" "Ethereum node $node_name is at block $block_decimal"
          fi
          ;;
        
        "binance")
          # Check Binance Smart Chain node
          local response=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' "$node")
          if ! echo "$response" | jq -e '.result' &> /dev/null; then
            send_alert "Blockchain Node Down" "BSC node $node_name ($node) is not responding correctly" "critical"
          fi
          ;;
        
        *)
          log "WARNING" "Unknown blockchain node type: $node_type"
          ;;
      esac
    done
  else
    log "WARNING" "Config file not found: $CONFIG_FILE"
  fi
  
  log "SUCCESS" "Blockchain node check completed"
}

# Function to generate daily report
generate_report() {
  log "INFO" "Generating monitoring report..."
  
  local report_file="$LOG_DIR/report_$(date +%Y%m%d).html"
  
  # Create HTML report
  cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
  <title>ChainFinity Monitoring Report - $(date +%Y-%m-%d)</title>
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
  </style>
</head>
<body>
  <h1>ChainFinity Monitoring Report</h1>
  <p>Generated on: $(date +%Y-%m-%d\ %H:%M:%S)</p>
  
  <div class="section">
    <h2>System Resources</h2>
    <table>
      <tr>
        <th>Metric</th>
        <th>Value</th>
        <th>Status</th>
      </tr>
      <tr>
        <td>CPU Usage</td>
        <td>$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%</td>
        <td class="$(if (( $(echo "$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}') > $ALERT_THRESHOLD" | bc -l) )); then echo "warning"; else echo "success"; fi)">
          $(if (( $(echo "$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}') > $ALERT_THRESHOLD" | bc -l) )); then echo "HIGH"; else echo "OK"; fi)
        </td>
      </tr>
      <tr>
        <td>Memory Usage</td>
        <td>$(echo "scale=2; $(free -m | awk '/Mem:/ {print $3}') * 100 / $(free -m | awk '/Mem:/ {print $2}')" | bc)%</td>
        <td class="$(if (( $(echo "$(echo "scale=2; $(free -m | awk '/Mem:/ {print $3}') * 100 / $(free -m | awk '/Mem:/ {print $2}')" | bc) > $ALERT_THRESHOLD" | bc -l) )); then echo "warning"; else echo "success"; fi)">
          $(if (( $(echo "$(echo "scale=2; $(free -m | awk '/Mem:/ {print $3}') * 100 / $(free -m | awk '/Mem:/ {print $2}')" | bc) > $ALERT_THRESHOLD" | bc -l) )); then echo "HIGH"; else echo "OK"; fi)
        </td>
      </tr>
      <tr>
        <td>Disk Usage</td>
        <td>$(df -h / | awk 'NR==2 {print $5}')</td>
        <td class="$(if [ "$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')" -gt "$ALERT_THRESHOLD" ]; then echo "warning"; else echo "success"; fi)">
          $(if [ "$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')" -gt "$ALERT_THRESHOLD" ]; then echo "HIGH"; else echo "OK"; fi)
        </td>
      </tr>
    </table>
  </div>
  
  <div class="section">
    <h2>Docker Containers</h2>
    <table>
      <tr>
        <th>Container</th>
        <th>Status</th>
        <th>Health</th>
        <th>CPU Usage</th>
        <th>Memory Usage</th>
      </tr>
EOF
  
  # Add Docker container data
  if command -v docker &> /dev/null; then
    local containers=$(docker ps -a --format "{{.Names}}")
    
    for container in $containers; do
      local status=$(docker inspect --format='{{.State.Status}}' "$container")
      local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' "$container")
      local cpu_usage=$(docker stats --no-stream --format "{{.CPUPerc}}" "$container")
      local mem_usage=$(docker stats --no-stream --format "{{.MemPerc}}" "$container")
      
      cat >> "$report_file" << EOF
      <tr>
        <td>$container</td>
        <td class="$(if [ "$status" != "running" ]; then echo "error"; else echo "success"; fi)">$status</td>
        <td class="$(if [ "$health" == "unhealthy" ]; then echo "error"; elif [ "$health" == "healthy" ]; then echo "success"; else echo ""; fi)">$health</td>
        <td>$cpu_usage</td>
        <td>$mem_usage</td>
      </tr>
EOF
    done
  else
    cat >> "$report_file" << EOF
      <tr>
        <td colspan="5">Docker not installed</td>
      </tr>
EOF
  fi
  
  # Close the report
  cat >> "$report_file" << EOF
    </table>
  </div>
  
  <div class="section">
    <h2>Log Summary</h2>
    <table>
      <tr>
        <th>Log Level</th>
        <th>Count (Last 24h)</th>
      </tr>
      <tr>
        <td>ERROR</td>
        <td>$(grep -c "\[ERROR\]" "$LOG_FILE")</td>
      </tr>
      <tr>
        <td>WARNING</td>
        <td>$(grep -c "\[WARNING\]" "$LOG_FILE")</td>
      </tr>
      <tr>
        <td>INFO</td>
        <td>$(grep -c "\[INFO\]" "$LOG_FILE")</td>
      </tr>
      <tr>
        <td>SUCCESS</td>
        <td>$(grep -c "\[SUCCESS\]" "$LOG_FILE")</td>
      </tr>
    </table>
  </div>
  
  <div class="section">
    <h2>Recent Errors</h2>
    <pre>$(grep "\[ERROR\]" "$LOG_FILE" | tail -n 10)</pre>
  </div>
</body>
</html>
EOF
  
  log "SUCCESS" "Report generated: $report_file"
  
  # Send report if configured
  if [ -n "$EMAIL_RECIPIENT" ]; then
    cat "$report_file" | mail -a "Content-Type: text/html" -s "ChainFinity Daily Monitoring Report - $(date +%Y-%m-%d)" "$EMAIL_RECIPIENT"
    log "INFO" "Report sent to $EMAIL_RECIPIENT"
  fi
}

# Create default config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << EOF
{
  "api_endpoints": [
    {
      "name": "Backend API",
      "url": "http://localhost:8000/api/health"
    },
    {
      "name": "Frontend",
      "url": "http://localhost:3000"
    }
  ],
  "blockchain_nodes": [
    {
      "name": "Ethereum Mainnet",
      "url": "https://mainnet.infura.io/v3/YOUR_INFURA_KEY",
      "type": "ethereum"
    },
    {
      "name": "BSC Mainnet",
      "url": "https://bsc-dataseed.binance.org/",
      "type": "binance"
    }
  ],
  "services": [
    {
      "name": "Backend Service",
      "process": "uvicorn",
      "port": 8000
    },
    {
      "name": "Frontend Service",
      "process": "node",
      "port": 3000
    }
  ]
}
EOF
  log "INFO" "Created default config file: $CONFIG_FILE"
fi

# Main monitoring loop
log "INFO" "Starting ChainFinity monitoring..."
log "INFO" "Check interval: $CHECK_INTERVAL seconds"
log "INFO" "Report interval: $REPORT_INTERVAL seconds"

last_report_time=$(date +%s)

while true; do
  # Run all checks
  check_system_resources
  check_docker_containers
  check_database_health
  check_api_endpoints
  check_blockchain_nodes
  
  # Generate report if it's time
  current_time=$(date +%s)
  if [ $((current_time - last_report_time)) -ge "$REPORT_INTERVAL" ]; then
    generate_report
    last_report_time=$current_time
  fi
  
  # Sleep until next check
  log "INFO" "Sleeping for $CHECK_INTERVAL seconds..."
  sleep "$CHECK_INTERVAL"
done
