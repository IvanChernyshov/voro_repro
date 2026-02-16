#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$ROOT_DIR/scripts/prepare_patched_voro.sh" >/dev/null

# Run using the patched tree. You can override CXX/CXXFLAGS from the environment.
export VORO_DIR="$ROOT_DIR/.build/voro_patched"

bash "$ROOT_DIR/run.sh" "${1:-out_patched.txt}"
