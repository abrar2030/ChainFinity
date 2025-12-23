#!/bin/bash
# Start the server in background
python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > /tmp/server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 5

# Test health endpoint
HEALTH=$(curl -s http://localhost:8000/health 2>&1)
ROOT=$(curl -s http://localhost:8000/ 2>&1)

# Kill server
kill $SERVER_PID 2>/dev/null

echo "=== Server Output ==="
cat /tmp/server.log | head -50

echo ""
echo "=== Health Check Response ==="
echo "$HEALTH"

echo ""
echo "=== Root Response ==="
echo "$ROOT"

