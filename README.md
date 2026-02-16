# Voro++ power-diagram periodic-box repro + fix (platform-dependent)

[![Repro](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml/badge.svg)](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml)

This repository is a minimal reproduction for a **platform-dependent inconsistency** in **Voro++ 0.4.6** when computing a **radical Voronoi / power diagram** inside a **fully periodic orthorhombic box** using `container_poly`.

With the exact same input points + radii:

- **Linux (x86_64)** with default build flags typically produces a consistent tessellation.
- **macOS (arm64)** (e.g. GitHub Actions `macos-15`) can produce an **incorrect cell** (particle **id=9**) with **missing shared faces** and **wall-like neighbors** (negative neighbor IDs), even though the domain is fully periodic.

The program also prints the **sum of all cell volumes**; in a correct periodic tessellation it should equal the box volume (`8^3 = 512`).

Upstream issue: https://github.com/chr1shr/voro/issues/43

---

## Contents

- `main.cpp` — constructs a fully periodic `container_poly`, inserts 25 points + radii (power diagram), computes all cells, and prints diagnostics for particles 0 and 9.
- `voro++/` — **unmodified** Voro++ 0.4.6 source code (see license in `voro++/LICENSE`).
- `patches/0001-inflate-max-radius-nextafter-3d.patch` — patch that fixes the issue in the 3D code by making radical pruning more robust.
- `run.sh` — build+run script (supports `CXX`, `CXXFLAGS`, `VORO_DIR`).
- `run_patched.sh` — builds a patched copy of Voro++ into `.build/voro_patched` and runs the repro against it.
- `run_aggressive.sh` / `run_aggressive_patched.sh` — convenience wrappers that often reproduce the macOS failure mode on Linux by compiling with more aggressive FP codegen.
- `.github/workflows/repro.yml` — CI that runs original + patched on Ubuntu and macOS, and also runs the "aggressive" variant on Ubuntu.

---

## How to reproduce

Requirements:
- a C++ compiler (`g++` or `clang++`)
- `bash`
- `patch` (only for running the patched variant)

### Original (baseline)

```bash
chmod +x run.sh
./run.sh out_original.txt
```

Typical **Linux** output characteristics:
- total volume sum ≈ `512`
- `PID 9` has ~`17` faces and ~`30` vertices
- reciprocity: `YES / YES`

Typical **macOS arm64** output characteristics:
- total volume sum significantly larger than `512` (e.g. ~`597.5`)
- `PID 9` has fewer faces/vertices (e.g. `11` faces and `18` vertices)
- `PID 9` neighbor IDs include negative values (wall-like)
- reciprocity: `YES / NO`

### "Aggressive" Linux build (often reproduces the macOS failure mode)

On many x86_64 Linux machines, compiling with `-O3 -march=native` reproduces the same incorrect behavior:

```bash
chmod +x run_aggressive.sh
./run_aggressive.sh out_aggressive_original.txt
```

(If this does *not* reproduce on your machine, you can also try using `clang++` and forcing FMA contraction:
`CXX=clang++ CXXFLAGS='-O3 -march=native -ffp-contract=fast -std=c++11' ./run.sh out.txt`.)

---

## The fix

### Summary

Voro++ uses `max_radius` (the global maximum particle radius) as part of **conservative pruning / cutoff tests** in the radical (power diagram) computation.

For the particle that has the **maximum radius**, the radical cutoff constant becomes:

- `r_mul = r_i^2 - max_radius^2 = 0`

This makes several pruning inequalities **knife-edge**. Small floating-point differences between platforms/optimizations (e.g. instruction selection and rounding points) can then flip borderline `>` decisions, causing Voro++ to **skip blocks/planes it should have tested**.

That can lead to:
- missing cutting planes,
- non-reciprocal neighbors,
- and `Total volume sum` larger than the box volume.

### Patch idea

Store `max_radius` as the *next representable double* above the observed maximum radius:

```cpp
max_radius = std::nextafter(r, HUGE_VAL);
```

This inflates `max_radius` by **1 ULP** (one representable step), making `r_mul` slightly negative for the maximum-radius particle. The cutoff/pruning becomes **slightly less aggressive**, which is safe (it only makes Voro++ test a few more candidates), and it removes the brittle borderline case.

### Run the patched variant

```bash
chmod +x run_patched.sh
./run_patched.sh out_patched.txt
```

Or the aggressive build with the patch:

```bash
chmod +x run_aggressive_patched.sh
./run_aggressive_patched.sh out_aggressive_patched.txt
```

The patched output should restore:
- `Total volume sum: 512 (expected 512)`
- reciprocity `YES / YES`
- sane neighbor IDs for `PID 9`

---

## Notes about 2D

Voro++ also has a separate 2D implementation under `voro++/2d/` with similar `max_radius` tracking and radical pruning code.

This repo (and the patch) focuses on the **3D** code path that matches the reported upstream issue. The same `nextafter` approach is likely applicable to 2D, but validating that is left as a follow-up.

---

## GitHub Actions CI

The workflow in `.github/workflows/repro.yml`:

- runs the original repro on `ubuntu-latest` and `macos-15`
- runs the patched repro on both
- additionally, on Linux it runs an "aggressive" build to often reproduce the macOS failure mode and then verifies the patch fixes it

All outputs are uploaded as artifacts (`output-ubuntu-latest`, `output-macos-15`).

---

## License

This repository includes the Voro++ source code under its original license. See `voro++/LICENSE`.
