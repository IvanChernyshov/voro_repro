#!/usr/bin/env python3
"""Parse and sanity-check the repro output.

This intentionally checks only a few invariants that should hold for a
correct periodic tessellation:
  - total volume sum equals the box volume (within tolerance)
  - reciprocity between pid 0 and pid 9 is YES/YES

The script can be used in CI to assert the patched build is correct, while
keeping the unpatched 'aggressive' build as a non-failing, informational step.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


VOL_RE = re.compile(r"^Total volume sum:\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\s*\(expected\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?)\)\s*$")
REC0_RE = re.compile(r"^\s*pid\s*0\s*has\s*neighbor\s*9:\s*(YES|NO)\s*$")
REC9_RE = re.compile(r"^\s*pid\s*9\s*has\s*neighbor\s*0:\s*(YES|NO)\s*$")


@dataclass
class Parsed:
    vol_sum: float | None = None
    vol_expected: float | None = None
    pid0_has_9: str | None = None
    pid9_has_0: str | None = None


def parse_output(text: str) -> Parsed:
    p = Parsed()
    for line in text.splitlines():
        m = VOL_RE.match(line.strip())
        if m:
            p.vol_sum = float(m.group(1))
            p.vol_expected = float(m.group(2))
            continue

        m = REC0_RE.match(line)
        if m:
            p.pid0_has_9 = m.group(1)
            continue

        m = REC9_RE.match(line)
        if m:
            p.pid9_has_0 = m.group(1)
            continue

    return p


def classify(p: Parsed, tol: float) -> tuple[bool, list[str]]:
    """Return (is_ok, reasons_if_not_ok)."""
    reasons: list[str] = []

    if p.vol_sum is None or p.vol_expected is None:
        reasons.append("missing 'Total volume sum' line")
    else:
        if abs(p.vol_sum - p.vol_expected) > tol:
            reasons.append(
                f"volume mismatch: got {p.vol_sum}, expected {p.vol_expected} (tol={tol})"
            )

    if p.pid0_has_9 is None:
        reasons.append("missing reciprocity line for pid 0 -> 9")
    if p.pid9_has_0 is None:
        reasons.append("missing reciprocity line for pid 9 -> 0")

    if p.pid0_has_9 is not None and p.pid0_has_9 != "YES":
        reasons.append("pid 0 does not report neighbor 9")
    if p.pid9_has_0 is not None and p.pid9_has_0 != "YES":
        reasons.append("pid 9 does not report neighbor 0")

    return (len(reasons) == 0), reasons


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("output", type=Path, help="Path to output text file")
    ap.add_argument(
        "--expect",
        choices=["pass", "broken"],
        default="pass",
        help="What we expect from this output.",
    )
    ap.add_argument(
        "--tol",
        type=float,
        default=1e-6,
        help="Absolute tolerance for the volume sum check.",
    )
    ap.add_argument(
        "--soft",
        action="store_true",
        help="Never fail (exit 0), just print a summary.",
    )

    args = ap.parse_args()

    text = args.output.read_text(encoding="utf-8", errors="replace")
    p = parse_output(text)
    ok, reasons = classify(p, args.tol)

    status = "PASS" if ok else "BROKEN"
    vol_str = (
        f"vol={p.vol_sum} expected={p.vol_expected}" if p.vol_sum is not None else "vol=?"
    )
    rec_str = f"rec0={p.pid0_has_9} rec9={p.pid9_has_0}"

    print(f"[{status}] {args.output}: {vol_str} {rec_str}")
    if reasons:
        for r in reasons:
            print(f"  - {r}")

    # Decide exit code.
    if args.soft:
        return 0

    if args.expect == "pass":
        return 0 if ok else 1
    else:  # expect broken
        return 0 if not ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
