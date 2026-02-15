#!/usr/bin/env bash
set -euo pipefail

# Convenience wrapper for Linux/WSL.
# Produces out_ubuntu.txt by default.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export CXX="${CXX:-g++}"

"$ROOT_DIR/run.sh" "${1:-out_ubuntu.txt}"
