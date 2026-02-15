#!/usr/bin/env bash
set -euo pipefail

# Build + run the Voro++ reproduction.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VORO_SRC="$ROOT_DIR/voro++/src"

# Choose compiler. On Ubuntu, `c++` is typically g++; on macOS it is clang++.
CXX="${CXX:-c++}"

# Output file (optional argument).
OUT_FILE="${1:-out.txt}"

# Compile reproduction program.
"$CXX" -O2 -std=c++11 -I"$VORO_SRC" \
  "$ROOT_DIR/main.cpp" \
  "$VORO_SRC/voro++.cc" \
  -o "$ROOT_DIR/repro"

# Run and capture output
"$ROOT_DIR/repro" | tee "$ROOT_DIR/$OUT_FILE"
