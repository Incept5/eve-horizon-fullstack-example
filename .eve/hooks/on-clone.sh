#!/usr/bin/env bash
set -euo pipefail

echo "[on-clone] Installing skills from manifest..."
eve-worker skills install

echo "[on-clone] Complete"

