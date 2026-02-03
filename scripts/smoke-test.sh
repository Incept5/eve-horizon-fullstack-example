#!/usr/bin/env bash
set -uo pipefail

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

failures=0

# Helper: HTTP GET with retries
http_get() {
  local url="$1" retries="${2:-3}" delay="${3:-2}"
  local attempt body http_code

  for attempt in $(seq 1 "$retries"); do
    body=$(curl -sSL --connect-timeout 5 --max-time 10 -w "\nHTTP_CODE:%{http_code}" "$url" 2>&1) && break
    echo "  Attempt $attempt/$retries failed, retrying in ${delay}s..." >&2
    sleep "$delay"
  done

  http_code=$(echo "$body" | grep "HTTP_CODE:" | tail -1 | cut -d: -f2)
  body=$(echo "$body" | grep -v "HTTP_CODE:" || true)

  echo "$http_code"
  echo "$body"
}

# Wait for API readiness
echo "Waiting for API to be ready..."
for i in $(seq 1 15); do
  if curl -sSL --connect-timeout 3 --max-time 5 "$base/health" >/dev/null 2>&1; then
    echo "  API ready after $i attempt(s)"
    break
  fi
  if [[ $i -eq 15 ]]; then
    echo "ERROR: API not ready after 15 attempts"
    exit 1
  fi
  echo "  Attempt $i/15 - retrying in 2s..."
  sleep 2
done
echo ""

# Test 1: Health endpoint
echo "Testing /health..."
result=$(http_get "$base/health" 3 2)
http_code=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)

if [[ "$http_code" == "200" ]] && echo "$body" | grep -q '"ok":true'; then
  echo "  PASS: /health (database connected)"
else
  echo "  FAIL: /health (HTTP $http_code)"
  echo "  Response: $body"
  failures=$((failures + 1))
fi
echo ""

# Test 2: Notes endpoint
echo "Testing /notes..."
result=$(http_get "$base/notes" 3 2)
http_code=$(echo "$result" | head -1)
body=$(echo "$result" | tail -n +2)

if [[ "$http_code" == "200" ]] && echo "$body" | grep -qE '^\['; then
  note_count=$(echo "$body" | grep -o '"id"' | wc -l | tr -d ' ')
  echo "  PASS: /notes ($note_count notes)"
else
  echo "  FAIL: /notes (HTTP $http_code)"
  echo "  Response: $body"
  failures=$((failures + 1))
fi
echo ""

if [[ $failures -eq 0 ]]; then
  echo "All smoke tests passed!"
  exit 0
else
  echo "FAILED: $failures test(s) failed"
  exit 1
fi
