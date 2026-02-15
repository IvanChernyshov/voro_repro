#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper for macOS.
# Produces out_macos.txt by default.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# On macOS, `c++` generally points to Apple clang++.
export CXX="${CXX:-c++}"

"$ROOT_DIR/run.sh" "${1:-out_macos.txt}"
