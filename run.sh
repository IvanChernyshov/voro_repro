#!/usr/bin/env bash
set -euo pipefail

# Build + run the Voro++ reproduction.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VORO_DIR="${VORO_DIR:-$ROOT_DIR/voro++}"
VORO_SRC="$VORO_DIR/src"

# Choose compiler. On Ubuntu, `c++` is typically g++; on macOS it is clang++.
CXX="${CXX:-c++}"

# Compiler flags can be overridden from the environment. Keep the default
# conservative so the repo stays a faithful reproduction of the original issue.
CXXFLAGS_DEFAULT="-O2 -std=c++11"
CXXFLAGS="${CXXFLAGS:-$CXXFLAGS_DEFAULT}"

# Output file (optional argument).
OUT_FILE="${1:-out.txt}"

# Compile reproduction program.
"$CXX" $CXXFLAGS -I"$VORO_SRC" \
  "$ROOT_DIR/main.cpp" \
  "$VORO_SRC/voro++.cc" \
  -o "$ROOT_DIR/repro"

# Run and capture output
"$ROOT_DIR/repro" | tee "$ROOT_DIR/$OUT_FILE"
