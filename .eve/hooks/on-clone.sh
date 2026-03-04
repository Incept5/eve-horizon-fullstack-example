#!/usr/bin/env bash
set -euo pipefail

echo "[on-clone] Installing skills from AgentPacks..."
eve skills install

echo "[on-clone] Complete"
