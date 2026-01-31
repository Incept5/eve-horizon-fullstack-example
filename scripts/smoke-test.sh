#!/usr/bin/env bash
set -euo pipefail

# Determine environment and base URL
env_name="${1:-${EVE_ENV_NAME:-test}}"
if [[ -n "${EVE_ENV_NAMESPACE:-}" ]]; then
  base="http://${env_name}-api.${EVE_ENV_NAMESPACE}.svc.cluster.local:3000"
else
  echo "Warning: EVE_ENV_NAMESPACE not set, using external hostname" >&2
  base="http://api.${env_name}.fullstack.eve.local"
fi

echo "Running smoke tests against: $base"
echo ""

# Wait for API readiness with retry
max_retries=10
retry_delay=3
echo "Waiting for API to be ready..."
for i in $(seq 1 $max_retries); do
  if curl -fsSL --connect-timeout 5 "$base/health" >/dev/null 2>&1; then
    echo "  API ready after $i attempt(s)"
    break
  fi
  if [[ $i -eq $max_retries ]]; then
    echo "ERROR: API not ready after $max_retries attempts"
    exit 1
  fi
  echo "  Attempt $i/$max_retries - retrying in ${retry_delay}s..."
  sleep $retry_delay
done
echo ""

# Test 1: Health endpoint
echo "Testing /health endpoint..."
health_response=$(curl -fsSL -w "\nHTTP_CODE:%{http_code}" "$base/health")
http_code=$(echo "$health_response" | grep "HTTP_CODE:" | cut -d: -f2)
body=$(echo "$health_response" | grep -v "HTTP_CODE:")

if [[ "$http_code" != "200" ]]; then
  echo "FAIL: Health check returned HTTP $http_code"
  echo "Response: $body"
  exit 1
fi

if echo "$body" | grep -q '"ok":true'; then
  echo "  PASS: Health check (database connected)"
else
  echo "FAIL: Health check returned 200 but not ok"
  echo "Response: $body"
  exit 2
fi
echo ""

# Test 2: Notes endpoint (verifies app can query database)
echo "Testing /notes endpoint..."
notes_response=$(curl -fsSL -w "\nHTTP_CODE:%{http_code}" "$base/notes")
http_code=$(echo "$notes_response" | grep "HTTP_CODE:" | cut -d: -f2)
body=$(echo "$notes_response" | grep -v "HTTP_CODE:")

if [[ "$http_code" != "200" ]]; then
  echo "FAIL: Notes endpoint returned HTTP $http_code"
  echo "Response: $body"
  exit 3
fi

if echo "$body" | grep -qE '^\[.*\]$'; then
  note_count=$(echo "$body" | grep -o '"id"' | wc -l | tr -d ' ')
  echo "  PASS: Notes endpoint ($note_count notes)"
else
  echo "FAIL: Notes endpoint response is not a JSON array"
  echo "Response: $body"
  exit 4
fi
echo ""

echo "All smoke tests passed!"
exit 0
