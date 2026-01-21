#!/usr/bin/env bash
set -euo pipefail

env_name="${1:-${EVE_ENV_NAME:-test}}"
if [[ -n "${EVE_ENV_NAMESPACE:-}" ]]; then
  base="http://test-api.${EVE_ENV_NAMESPACE}.svc.cluster.local:3000"
else
  base="http://api.${env_name}.fullstack.eve.local"
fi

curl -fsS "$base/health"
curl -fsS "$base/todos"
