#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CXXFLAGS="${CXXFLAGS:--O3 -march=native -std=c++11}"

bash "$ROOT_DIR/run_dev_patched.sh" "${1:-out_dev_aggressive_patched.txt}"
