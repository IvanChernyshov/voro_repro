# Voro++ macOS arm64 power-diagram periodic-box reproduction

[![Repro](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml/badge.svg)](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml)

This repository is a minimal reproduction for a **platform-dependent inconsistency** in **Voro++ 0.4.6** when computing a **radical Voronoi / power diagram** inside a **fully periodic orthorhombic box** using `container_poly`.

With the exact same input points + radii:

- **Linux (x86_64)** produces a consistent tessellation.
- **macOS (arm64)** produces an incorrect cell (particle **id=9**) with **fewer faces/vertices**, **missing shared faces**, and **wall-like neighbors** (negative neighbor IDs) despite the domain being fully periodic.

The program also prints the **sum of all cell volumes**; in a correct periodic tessellation it should equal the box volume (`8^3 = 512`).

> This repo is linked to/from an upstream issue report for Voro++: [link](https://github.com/chr1shr/voro/issues/43).

---

## Contents

- `main.cpp` — C++ program that constructs a fully periodic `container_poly`, inserts 25 points + radii (power diagram), computes all cells, and prints diagnostics for particles 0 and 9.
- `voro++/` — **unmodified** Voro++ 0.4.6 source code (see license in `voro++/LICENSE`).
- `run.sh` — portable build+run script.
- `.github/workflows/repro.yml` — GitHub Actions workflow that builds+runs on Ubuntu and macOS and uploads output as artifacts.

---

## Run locally

Requirements:
- a C++ compiler (`g++` or `clang++`)
- `bash`

### Generic

```bash
chmod +x run.sh
./run.sh out_local.txt
```

### Convenience wrappers

```bash
chmod +x run_ubuntu.sh run_macos.sh
./run_ubuntu.sh
./run_macos.sh
```

The output is written to the selected `out_*.txt` file and also printed to the terminal.

---

## What to look for in the output

The program prints:

- `Total volume sum: ... (expected 512)`
- diagnostics for `PID 0` and `PID 9` (faces, vertices, neighbors)
- a simple reciprocity check:
  - `pid 0 has neighbor 9: ...`
  - `pid 9 has neighbor 0: ...`

Typical **Linux** output characteristics:
- total volume sum ≈ `512`
- `PID 9` has ~`17` faces and ~`30` vertices
- reciprocity: `YES / YES`

Typical **macOS arm64** output characteristics (observed on GitHub Actions `macos-15`):
- total volume sum significantly larger than `512` (e.g. ~`597.5`)
- `PID 9` has fewer faces/vertices (e.g. `11` faces and `18` vertices)
- `PID 9` neighbor IDs include negative values (wall-like)
- reciprocity: `YES / NO`

---

## GitHub Actions CI

The workflow in `.github/workflows/repro.yml` builds and runs this program on:

- `ubuntu-latest`
- `macos-15` (Apple Silicon / arm64)

The output is:
- printed in the workflow logs
- uploaded as artifacts (`output-ubuntu-latest`, `output-macos-15`)

Badge:

```md
[![Repro](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml/badge.svg)](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml)
```

---

## License

This repository includes the Voro++ source code under its original license. See:

- `voro++/LICENSE`
