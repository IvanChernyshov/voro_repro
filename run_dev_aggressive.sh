#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper for the *dev* tree.
# Enables more aggressive FP codegen, which can expose platform sensitivity.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CXXFLAGS="${CXXFLAGS:--O3 -march=native -std=c++11}"

bash "$ROOT_DIR/run_dev.sh" "${1:-out_dev_aggressive.txt}"
