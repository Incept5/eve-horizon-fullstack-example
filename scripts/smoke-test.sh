#!/usr/bin/env bash
set -euo pipefail

env_name="${1:-${EVE_ENV_NAME:-test}}"
base="http://api.${env_name}.fullstack.eve.local"

curl -fsS "$base/health"
curl -fsS "$base/todos"
