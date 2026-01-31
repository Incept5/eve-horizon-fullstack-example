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

echo "🔍 Running smoke tests against: $base"
echo ""

# Test 1: Health endpoint (includes database connectivity check)
echo "✓ Testing /health endpoint (verifies database connectivity)..."
health_response=$(curl -fsSL -w "\nHTTP_CODE:%{http_code}" "$base/health")
http_code=$(echo "$health_response" | grep "HTTP_CODE:" | cut -d: -f2)
body=$(echo "$health_response" | grep -v "HTTP_CODE:")

if [[ "$http_code" != "200" ]]; then
  echo "❌ Health check failed with HTTP $http_code"
  echo "Response: $body"
  exit 1
fi

# Verify the response indicates DB is OK
if echo "$body" | grep -q '"ok":true'; then
  echo "  ✓ Health check passed (Database connected)"
  echo "  Response: $body"
else
  echo "❌ Health check returned 200 but database check failed"
  echo "Response: $body"
  exit 2
fi
echo ""

# Test 2: Todos endpoint (verifies app can query database)
echo "✓ Testing /todos endpoint (verifies database read operations)..."
todos_response=$(curl -fsSL -w "\nHTTP_CODE:%{http_code}" "$base/todos")
http_code=$(echo "$todos_response" | grep "HTTP_CODE:" | cut -d: -f2)
body=$(echo "$todos_response" | grep -v "HTTP_CODE:")

if [[ "$http_code" != "200" ]]; then
  echo "❌ Todos endpoint failed with HTTP $http_code"
  echo "Response: $body"
  exit 3
fi

# Verify we got valid JSON array response
if echo "$body" | grep -qE '^\[.*\]$'; then
  todo_count=$(echo "$body" | grep -o '"id"' | wc -l | tr -d ' ')
  echo "  ✓ Todos endpoint passed (Retrieved $todo_count todos)"
  echo "  Response: $body"
else
  echo "❌ Todos endpoint returned 200 but response is not a valid array"
  echo "Response: $body"
  exit 4
fi
echo ""

echo "✅ All smoke tests passed!"
exit 0
