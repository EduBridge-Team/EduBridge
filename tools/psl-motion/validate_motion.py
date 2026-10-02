#!/usr/bin/env python3
"""Validate capture quality before a PSL motion is sent for human review."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def pct(value: int, total: int) -> float:
    return 0.0 if total <= 0 else (value / total) * 100.0


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate EduBridge PSL motion capture coverage.")
    parser.add_argument("motion", type=Path)
    parser.add_argument("--min-pose", type=float, default=90.0)
    parser.add_argument("--min-hand", type=float, default=75.0)
    args = parser.parse_args()

    payload = json.loads(args.motion.read_text(encoding="utf-8"))
    frames = payload.get("frames", [])
    total = len(frames)

    pose = sum(1 for frame in frames if frame.get("pose"))
    left = sum(1 for frame in frames if frame.get("left_hand"))
    right = sum(1 for frame in frames if frame.get("right_hand"))

    pose_pct = pct(pose, total)
    left_pct = pct(left, total)
    right_pct = pct(right, total)

    print(f"Frames: {total}")
    print(f"Pose coverage: {pose_pct:.1f}%")
    print(f"Left hand coverage: {left_pct:.1f}%")
    print(f"Right hand coverage: {right_pct:.1f}%")

    failures = []
    if pose_pct < args.min_pose:
        failures.append(f"pose coverage below {args.min_pose:.1f}%")
    if max(left_pct, right_pct) < args.min_hand:
        failures.append(f"no hand reaches {args.min_hand:.1f}% coverage")

    if failures:
        print("Capture needs another take:")
        for failure in failures:
            print(f"- {failure}")
        return 2

    print("Capture quality is sufficient for the next processing stage.")
    print("This does NOT mean the sign is linguistically verified.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
