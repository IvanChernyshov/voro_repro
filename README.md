# Voro++ periodic power-diagram repro + fix (stable + dev)

> [!NOTE]
> Fixed upstream in Voro++ master ([04fecfa](https://github.com/chr1shr/voro/commit/04fecfabd07edb289746b0af27969077ee65e5ce)) & dev ([aed2ef1](https://github.com/chr1shr/voro/commit/aed2ef128737b3b9b300c96a622de637ea33a7be)).

[![Repro](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml/badge.svg)](https://github.com/IvanChernyshov/voro_repro/actions/workflows/repro.yml)

This repository is a minimal reproduction for a **platform-dependent inconsistency** in **Voro++** when computing a **radical Voronoi / power diagram** inside a **fully periodic orthorhombic box**.

With the exact same input points + radii:

- A **baseline build** on Linux often produces a consistent tessellation.
- On **macOS arm64** (e.g. GitHub Actions `macos-15`) the *stable* snapshot can produce an **incorrect cell** (particle **id=9**) with **missing shared faces**, **broken reciprocity**, and a **total volume sum** that no longer equals the periodic box volume (`8^3 = 512`).

Upstream issue: https://github.com/chr1shr/voro/issues/43

---

## Stable vs dev snapshot

This repo contains **two** Voro++ snapshots, because upstream has an actively developed branch with many changes:

- `voro++/` — a **stable snapshot** (same code layout/API as the issue report, using `container_poly`).
- `voro_dev/` — a **development snapshot** (newer code layout/API, using `container_poly_3d`, iterators, and `voronoicell_neighbor_3d`).

The same numerical corner case can still be triggered in the **dev** snapshot under sufficiently “aggressive” floating-point codegen.

---

## Contents

### Harnesses

- `main.cpp` — stable snapshot harness (`container_poly`), prints diagnostics for particles 0 and 9.
- `main_dev.cpp` — dev snapshot harness (`container_poly_3d` + iterators), same diagnostics.

### Voro++ sources

- `voro++/` — **unmodified** stable snapshot (see `voro++/LICENSE`).
- `voro_dev/` — **unmodified** dev snapshot (see `voro_dev/LICENSE`).

### Patches (3D only)

- `patches/0001-inflate-max-radius-nextafter-3d.patch` — stable snapshot fix.
- `patches/0003-inflate-max-radius-nextafter-3d-dev.patch` — dev snapshot fix.

### Scripts

Stable snapshot:
- `run.sh`, `run_patched.sh`
- `run_aggressive.sh`, `run_aggressive_patched.sh`

Dev snapshot:
- `run_dev.sh`, `run_dev_patched.sh`
- `run_dev_aggressive.sh`, `run_dev_aggressive_patched.sh`

CI:
- `.github/workflows/repro.yml` — runs both snapshots on Ubuntu + macOS, and also runs the aggressive Linux variants.

---

## What the harness checks

To keep the repro small and unambiguous, the harness checks only invariants that should hold for a correct periodic tessellation:

1. **Total volume sum** of all Voronoi cells should equal the periodic box volume (`512`) within a small tolerance.
2. **Reciprocity** between particle `0` and particle `9` should be `YES/YES`.

The output also prints face/vertex counts and neighbor IDs for particles 0 and 9 for debugging.

---

## Notes from the library author (important)

The upstream author pointed out two relevant facts:

- Differences in **floating-point evaluation** (intermediate precision / instruction selection / when values are rounded back to memory) can produce **subtle cross-platform differences**, and in rare cases disrupt **cell convexity assumptions**.
- **Negative neighbor IDs are not necessarily a bug**, even in periodic domains: they can indicate faces due to the **periodic image of the particle itself**.

Because of that, this repo does **not** treat “negative neighbors exist” as a correctness signal by itself. Instead, it focuses on the two robust invariants above (volume sum and reciprocity).

---

## How to reproduce

Requirements:
- a C++ compiler (`g++` or `clang++`)
- `bash`
- `patch` (only for running patched variants)

### Stable snapshot

Baseline:

```bash
chmod +x run.sh
./run.sh out_stable_original.txt
```

Patched:

```bash
chmod +x run_patched.sh
./run_patched.sh out_stable_patched.txt
```

### Dev snapshot

Baseline:

```bash
chmod +x run_dev.sh
./run_dev.sh out_dev_original.txt
```

Patched:

```bash
chmod +x run_dev_patched.sh
./run_dev_patched.sh out_dev_patched.txt
```

### “Aggressive” Linux build

On many x86_64 Linux machines, compiling with `-O3 -march=native` reproduces the same failure mode that shows up on macOS arm64:

Stable snapshot:

```bash
chmod +x run_aggressive.sh
./run_aggressive.sh out_aggressive_stable_original.txt
```

Dev snapshot:

```bash
chmod +x run_dev_aggressive.sh
./run_dev_aggressive.sh out_aggressive_dev_original.txt
```

If this *does not* reproduce on your machine, you can try a different compiler and/or FP contraction settings, e.g.:

```bash
CXX=clang++ CXXFLAGS='-O3 -march=native -ffp-contract=fast -std=c++11' ./run.sh out.txt
```

---

## Local results (Linux x86_64, this repo)

On the Linux runner used to build this archive:

- **Baseline** builds (both stable and dev) produced a correct tessellation (`Total volume sum: 512`, reciprocity `YES/YES`).
- The **aggressive** build reproduced the failure for **both** snapshots:
  - `Total volume sum: 597.535 (expected 512)`
  - `pid 9 has neighbor 0: NO`
  - `PID 9` shrinks to `11` faces / `18` vertices and gains several negative neighbors.
- The corresponding **patched** builds restore correctness (`512`, reciprocity `YES/YES`) even under aggressive flags.

---

## The fix (3D)

### Summary

In power-diagram mode, Voro++ uses a tracked maximum particle radius `max_radius` as part of **conservative pruning / cutoff tests** when deciding which blocks and candidate planes can be skipped.

A key constant in those tests is effectively:

- `r_mul = r_i^2 - max_radius^2`

For the particle that has the **maximum radius**, `r_mul` becomes exactly **zero**.

That creates a **knife-edge** situation: small floating-point differences between platforms/optimizations (instruction selection, rounding points, FMA, etc.) can flip borderline `>` decisions. When that happens, Voro++ may **prune away blocks/planes it should have tested**, leading to missing cuts and a broken tessellation.

### Patch idea

Store `max_radius` as the **next representable double above** the observed maximum radius:

```cpp
max_radius = nextafter(r, HUGE_VAL);
```

This inflates `max_radius` by **1 ULP** (one representable double step). For the maximum-radius particle, `r_mul` becomes **slightly negative** instead of exactly zero. The pruning becomes **slightly less aggressive** (safe: it only causes a few extra candidate checks), and it removes the brittle equality case.

### Where it’s applied

For 3D, the fix must be applied everywhere the global maximum radius is updated:

- serial `put(...)` and `put(particle_order&, ...)`
- multithreaded `put_reconcile_overflow()` (per-thread maxima merge)
- `compute_ghost_cell(...)` (temporary insertion)

And for both 3D container flavors:

- orthorhombic: `container_poly_3d`
- triclinic: `container_triclinic_poly`

---

## Notes about 2D

Voro++ has a separate 2D implementation under `voro++/2d/` (and dev has `*_2d` code too) with similar `max_radius` tracking.

This repo (and the patches) focus on the **3D** code path that matches the upstream issue. The same `nextafter` approach is likely applicable to 2D, but it should be validated separately.

---

## GitHub Actions CI

The workflow in `.github/workflows/repro.yml`:

- runs the **stable snapshot** on `ubuntu-latest` and `macos-15` (original + patched)
- runs the **dev snapshot** on `ubuntu-latest` and `macos-15` (original + patched)
- additionally, on Linux it runs the **aggressive** variant for both snapshots (original informational + patched required)

All outputs are uploaded as artifacts (`output-ubuntu-latest`, `output-macos-15`).

---

## License

This repository includes Voro++ source code under its original license(s). See:

- `voro++/LICENSE`
- `voro_dev/LICENSE`
