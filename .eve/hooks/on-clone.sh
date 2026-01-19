#!/usr/bin/env bash
set -euo pipefail

echo "[on-clone] Installing skills from manifest..."
if command -v eve-skills >/dev/null 2>&1; then
  eve-skills install
elif command -v openskills >/dev/null 2>&1; then
  openskills install ./skills/eve-horizon-dev
else
  echo "openskills not available; skipping skills install"
fi

if command -v npm >/dev/null 2>&1; then
  echo "[on-clone] Installing dependencies..."
  (cd apps/web && npm install)
  (cd apps/api && npm install)

  echo "[on-clone] Building projects..."
  (cd apps/web && npm run build)
  (cd apps/api && npm run build)
fi

