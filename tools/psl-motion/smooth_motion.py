#!/usr/bin/env python3
"""Smooth EduBridge PSL motion JSON without changing frame timing."""

from __future__ import annotations

import argparse
import json
from copy import deepcopy
from pathlib import Path
from typing import Any


COORDS = ("x", "y", "z")


def average(values: list[float]) -> float:
    return sum(values) / len(values)


def smooth_sequence(
    frames: list[dict[str, Any]],
    key: str,
    radius: int,
) -> None:
    snapshot = deepcopy(frames)

    for index, frame in enumerate(frames):
        current = snapshot[index].get(key)
        if current is None:
            continue

        start = max(0, index - radius)
        end = min(len(frames), index + radius + 1)

        if isinstance(current, list):
            for point_index, point in enumerate(current):
                for coord in COORDS:
                    values = []
                    for sample in snapshot[start:end]:
                        points = sample.get(key)
                        if points is None or point_index >= len(points):
                            continue
                        value = points[point_index].get(coord)
                        if isinstance(value, (int, float)):
                            values.append(float(value))
                    if values:
                        point[coord] = round(average(values), 7)

        elif isinstance(current, dict):
            for landmark_id, point in current.items():
                for coord in COORDS:
                    values = []
                    for sample in snapshot[start:end]:
                        points = sample.get(key)
                        if not isinstance(points, dict):
                            continue
                        source = points.get(landmark_id)
                        if not isinstance(source, dict):
                            continue
                        value = source.get(coord)
                        if isinstance(value, (int, float)):
                            values.append(float(value))
                    if values:
                        point[coord] = round(average(values), 7)


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply a moving-average smoother to PSL motion JSON.")
    parser.add_argument("motion", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    parser.add_argument("--radius", type=int, default=2, help="Frames on each side of the current frame.")
    args = parser.parse_args()

    if args.radius < 0:
        raise SystemExit("--radius must be >= 0")

    payload = json.loads(args.motion.read_text(encoding="utf-8"))
    if payload.get("schema") != "edubridge.psl.motion.v1":
        raise SystemExit("Unsupported motion schema.")

    frames = payload.get("frames")
    if not isinstance(frames, list):
        raise SystemExit("Invalid motion file: frames must be a list.")

    for key in ("pose", "left_hand", "right_hand", "face"):
        smooth_sequence(frames, key, args.radius)

    payload["processing"] = {
        **payload.get("processing", {}),
        "smoothing": {
            "algorithm": "moving-average",
            "radius_frames": args.radius,
        },
    }

    output = args.output or args.motion.with_name(f"{args.motion.stem}.smooth.json")
    output.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote smoothed motion to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
