#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$ROOT_DIR/scripts/prepare_patched_voro_dev.sh" >/dev/null

export VORO_DIR="$ROOT_DIR/.build/voro_dev_patched"

bash "$ROOT_DIR/run_dev.sh" "${1:-out_dev_patched.txt}"
