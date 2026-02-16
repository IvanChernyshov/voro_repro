#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper that often reproduces the macOS arm64 failure mode on Linux
# by enabling more aggressive FP codegen.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Keep the user's overrides if provided.
export CXXFLAGS="${CXXFLAGS:--O3 -march=native -std=c++11}"

bash "$ROOT_DIR/run.sh" "${1:-out_aggressive.txt}"
