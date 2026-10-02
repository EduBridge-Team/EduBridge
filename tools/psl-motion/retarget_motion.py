#!/usr/bin/env python3
"""Convert EduBridge PSL landmarks into renderer-neutral humanoid bone rotations.

The result is intentionally a rotation-track JSON. Exporting it into a GLB is
handled by export_glb_animation.py so capture, retargeting, and asset writing
remain independently testable.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
from typing import Any

import numpy as np


POSE = {
    "nose": 0,
    "left_shoulder": 11,
    "right_shoulder": 12,
    "left_elbow": 13,
    "right_elbow": 14,
    "left_wrist": 15,
    "right_wrist": 16,
    "left_hip": 23,
    "right_hip": 24,
}

FINGERS = {
    "thumb": (1, 2, 3, 4),
    "index": (5, 6, 7, 8),
    "middle": (9, 10, 11, 12),
    "ring": (13, 14, 15, 16),
    "pinky": (17, 18, 19, 20),
}


def vec(point: dict[str, Any]) -> np.ndarray:
    # MediaPipe: x right, y down, z toward/away from camera depending stream.
    # EduBridge normalized motion frame: x right, y up, z forward.
    return np.array([
        float(point["x"]),
        -float(point["y"]),
        -float(point["z"]),
    ], dtype=np.float64)


def safe_normalize(value: np.ndarray) -> np.ndarray | None:
    norm = float(np.linalg.norm(value))
    if norm < 1e-8:
        return None
    return value / norm


def quat_normalize(q: np.ndarray) -> np.ndarray:
    norm = float(np.linalg.norm(q))
    if norm < 1e-8:
        return np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)
    return q / norm


def quat_from_to(source: np.ndarray, target: np.ndarray) -> np.ndarray:
    a = safe_normalize(source)
    b = safe_normalize(target)
    if a is None or b is None:
        return np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)

    dot = float(np.clip(np.dot(a, b), -1.0, 1.0))
    if dot > 0.999999:
        return np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)

    if dot < -0.999999:
        axis = np.cross(a, np.array([1.0, 0.0, 0.0], dtype=np.float64))
        if np.linalg.norm(axis) < 1e-6:
            axis = np.cross(a, np.array([0.0, 1.0, 0.0], dtype=np.float64))
        axis = safe_normalize(axis)
        return np.array([axis[0], axis[1], axis[2], 0.0], dtype=np.float64)

    cross = np.cross(a, b)
    q = np.array([cross[0], cross[1], cross[2], 1.0 + dot], dtype=np.float64)
    return quat_normalize(q)


def quat_inverse(q: np.ndarray) -> np.ndarray:
    q = quat_normalize(q)
    return np.array([-q[0], -q[1], -q[2], q[3]], dtype=np.float64)


def quat_mul(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return quat_normalize(np.array([
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    ], dtype=np.float64))


def qlist(q: np.ndarray) -> list[float]:
    q = quat_normalize(q)
    return [round(float(v), 7) for v in q]


def midpoint(a: dict[str, Any], b: dict[str, Any]) -> np.ndarray:
    return (vec(a) + vec(b)) * 0.5


def point(points: list[dict[str, Any]], name: str) -> dict[str, Any] | None:
    index = POSE[name]
    if index >= len(points):
        return None
    return points[index]


def direction(a: dict[str, Any] | None, b: dict[str, Any] | None) -> np.ndarray | None:
    if a is None or b is None:
        return None
    return safe_normalize(vec(b) - vec(a))


def put_rotation(
    global_rotations: dict[str, np.ndarray],
    bone: str,
    rest_axis: np.ndarray,
    current_direction: np.ndarray | None,
) -> None:
    if current_direction is None:
        return
    global_rotations[bone] = quat_from_to(rest_axis, current_direction)


def body_rotations(frame: dict[str, Any]) -> dict[str, np.ndarray]:
    pose = frame.get("pose")
    if not isinstance(pose, list):
        return {}

    ls = point(pose, "left_shoulder")
    rs = point(pose, "right_shoulder")
    le = point(pose, "left_elbow")
    re = point(pose, "right_elbow")
    lw = point(pose, "left_wrist")
    rw = point(pose, "right_wrist")
    lh = point(pose, "left_hip")
    rh = point(pose, "right_hip")
    nose = point(pose, "nose")

    rotations: dict[str, np.ndarray] = {}

    if ls and rs and lh and rh:
        shoulder_center = midpoint(ls, rs)
        hip_center = midpoint(lh, rh)
        torso = safe_normalize(shoulder_center - hip_center)
        put_rotation(rotations, "spine", np.array([0.0, 1.0, 0.0]), torso)

        if nose:
            head_dir = safe_normalize(vec(nose) - shoulder_center)
            put_rotation(rotations, "neck", np.array([0.0, 1.0, 0.0]), head_dir)
            put_rotation(rotations, "head", np.array([0.0, 1.0, 0.0]), head_dir)

    put_rotation(rotations, "left_upper_arm", np.array([1.0, 0.0, 0.0]), direction(ls, le))
    put_rotation(rotations, "left_lower_arm", np.array([1.0, 0.0, 0.0]), direction(le, lw))
    put_rotation(rotations, "right_upper_arm", np.array([-1.0, 0.0, 0.0]), direction(rs, re))
    put_rotation(rotations, "right_lower_arm", np.array([-1.0, 0.0, 0.0]), direction(re, rw))

    return rotations


def hand_rotations(
    hand: list[dict[str, Any]] | None,
    side: str,
) -> dict[str, np.ndarray]:
    if not isinstance(hand, list) or len(hand) < 21:
        return {}

    rotations: dict[str, np.ndarray] = {}
    outward = np.array([1.0, 0.0, 0.0]) if side == "left" else np.array([-1.0, 0.0, 0.0])

    # Approximate palm direction from wrist to middle MCP.
    palm_dir = safe_normalize(vec(hand[9]) - vec(hand[0]))
    put_rotation(rotations, f"{side}_hand", outward, palm_dir)

    for finger, indices in FINGERS.items():
        chain = (0,) + indices
        for segment in range(1, len(chain) - 1):
            a = hand[chain[segment]]
            b = hand[chain[segment + 1]]
            current = safe_normalize(vec(b) - vec(a))
            bone = f"{side}_{finger}_{segment}"
            put_rotation(rotations, bone, outward, current)

    return rotations


PARENTS = {
    "neck": "spine",
    "head": "neck",
    "left_upper_arm": "spine",
    "left_lower_arm": "left_upper_arm",
    "left_hand": "left_lower_arm",
    "right_upper_arm": "spine",
    "right_lower_arm": "right_upper_arm",
    "right_hand": "right_lower_arm",
}

for _side in ("left", "right"):
    for _finger in FINGERS:
        PARENTS[f"{_side}_{_finger}_1"] = f"{_side}_hand"
        PARENTS[f"{_side}_{_finger}_2"] = f"{_side}_{_finger}_1"
        PARENTS[f"{_side}_{_finger}_3"] = f"{_side}_{_finger}_2"


def to_local(global_rotations: dict[str, np.ndarray]) -> dict[str, list[float]]:
    local: dict[str, list[float]] = {}
    for bone, rotation in global_rotations.items():
        parent = PARENTS.get(bone)
        if parent and parent in global_rotations:
            rotation = quat_mul(quat_inverse(global_rotations[parent]), rotation)
        local[bone] = qlist(rotation)
    return local


def ensure_quaternion_continuity(
    tracks: dict[str, list[dict[str, Any]]],
) -> None:
    # q and -q encode the same orientation. Keep neighboring samples on the
    # same hemisphere to prevent interpolation from taking the long route.
    for samples in tracks.values():
        previous: np.ndarray | None = None
        for sample in samples:
            current = np.array(sample["rotation"], dtype=np.float64)
            if previous is not None and float(np.dot(previous, current)) < 0.0:
                current = -current
                sample["rotation"] = qlist(current)
            previous = current


def main() -> int:
    parser = argparse.ArgumentParser(description="Retarget PSL landmark motion into humanoid bone rotations.")
    parser.add_argument("motion", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    args = parser.parse_args()

    payload = json.loads(args.motion.read_text(encoding="utf-8"))
    if payload.get("schema") != "edubridge.psl.motion.v1":
        raise SystemExit("Unsupported motion schema.")

    tracks: dict[str, list[dict[str, Any]]] = {}

    for frame in payload.get("frames", []):
        global_rotations = body_rotations(frame)
        global_rotations.update(hand_rotations(frame.get("left_hand"), "left"))
        global_rotations.update(hand_rotations(frame.get("right_hand"), "right"))

        local = to_local(global_rotations)
        for bone, rotation in local.items():
            tracks.setdefault(bone, []).append({
                "time_ms": frame.get("time_ms", 0),
                "rotation": rotation,
            })

    ensure_quaternion_continuity(tracks)

    result = {
        "schema": "edubridge.psl.retarget.v1",
        "source_motion_schema": payload.get("schema"),
        "label": payload.get("label", ""),
        "source": payload.get("source", {}),
        "coordinate_system": "x-right,y-up,z-forward",
        "rotation_order": "quaternion-xyzw",
        "bone_space": "local-parent-relative-approximation",
        "notes": [
            "This stage maps tracked landmark directions to a standardized humanoid bone layout.",
            "A compatible avatar bind pose / bone-axis calibration is still required for production-quality retargeting.",
            "PSL linguistic verification remains a separate human review step."
        ],
        "tracks": tracks,
    }

    output = args.output or args.motion.with_name(f"{args.motion.stem}.retarget.json")
    output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(tracks)} bone tracks to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
