#!/usr/bin/env python3
"""Convert EduBridge PSL landmarks into calibrated humanoid bone motion.

The retargeter intentionally stays avatar-independent. It converts MediaPipe
landmark directions into local humanoid rotations, calibrates them against a
neutral reference window, fills short tracking gaps, and emits *delta*
quaternions. The GLB exporter composes those deltas with the avatar's real
bind-pose rotations so the generated animation does not overwrite the rig's
rest pose.
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


def vec(point: dict[str, Any]) -> np.ndarray:
    # MediaPipe: x right, y down, z camera-space.
    # EduBridge normalized frame: x right, y up, z forward.
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
        if axis is None:
            return np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)
        return np.array([axis[0], axis[1], axis[2], 0.0], dtype=np.float64)

    cross = np.cross(a, b)
    return quat_normalize(np.array([
        cross[0], cross[1], cross[2], 1.0 + dot
    ], dtype=np.float64))


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


def quat_slerp(a: np.ndarray, b: np.ndarray, t: float) -> np.ndarray:
    a = quat_normalize(a)
    b = quat_normalize(b)
    dot = float(np.dot(a, b))
    if dot < 0.0:
        b = -b
        dot = -dot
    dot = float(np.clip(dot, -1.0, 1.0))
    if dot > 0.9995:
        return quat_normalize(a + t * (b - a))
    theta = math.acos(dot)
    sin_theta = math.sin(theta)
    return quat_normalize(
        (math.sin((1.0 - t) * theta) / sin_theta) * a
        + (math.sin(t * theta) / sin_theta) * b
    )


def quat_mean(values: list[np.ndarray]) -> np.ndarray:
    if not values:
        return np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)
    reference = quat_normalize(values[0])
    aligned = []
    for value in values:
        q = quat_normalize(value)
        if float(np.dot(reference, q)) < 0.0:
            q = -q
        aligned.append(q)
    return quat_normalize(np.sum(aligned, axis=0))


def clamp_delta(q: np.ndarray, degrees: float) -> np.ndarray:
    q = quat_normalize(q)
    if q[3] < 0.0:
        q = -q
    angle = 2.0 * math.acos(float(np.clip(q[3], -1.0, 1.0)))
    limit = math.radians(degrees)
    if angle <= limit or angle < 1e-8:
        return q
    axis = safe_normalize(q[:3])
    if axis is None:
        return np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)
    half = limit * 0.5
    return quat_normalize(np.array([
        axis[0] * math.sin(half),
        axis[1] * math.sin(half),
        axis[2] * math.sin(half),
        math.cos(half),
    ], dtype=np.float64))


def rotation_limit_for(bone: str) -> float:
    if bone == "spine":
        return 35.0
    if bone in {"neck", "head"}:
        return 45.0
    if "upper_arm" in bone:
        return 125.0
    if "lower_arm" in bone:
        return 150.0
    if bone.endswith("_hand"):
        return 95.0
    if any(name in bone for name in FINGERS):
        return 105.0
    return 120.0


def qlist(q: np.ndarray) -> list[float]:
    q = quat_normalize(q)
    return [round(float(v), 7) for v in q]


def midpoint(a: dict[str, Any], b: dict[str, Any]) -> np.ndarray:
    return (vec(a) + vec(b)) * 0.5


def point(points: list[dict[str, Any]], name: str) -> dict[str, Any] | None:
    index = POSE[name]
    return points[index] if index < len(points) else None


def direction(a: dict[str, Any] | None, b: dict[str, Any] | None) -> np.ndarray | None:
    if a is None or b is None:
        return None
    return safe_normalize(vec(b) - vec(a))


def put_rotation(
    rotations: dict[str, np.ndarray],
    bone: str,
    rest_axis: np.ndarray,
    current_direction: np.ndarray | None,
) -> None:
    if current_direction is not None:
        rotations[bone] = quat_from_to(rest_axis, current_direction)


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


def hand_rotations(hand: list[dict[str, Any]] | None, side: str) -> dict[str, np.ndarray]:
    if not isinstance(hand, list) or len(hand) < 21:
        return {}

    rotations: dict[str, np.ndarray] = {}
    outward = np.array([1.0, 0.0, 0.0]) if side == "left" else np.array([-1.0, 0.0, 0.0])

    palm_dir = safe_normalize(vec(hand[9]) - vec(hand[0]))
    put_rotation(rotations, f"{side}_hand", outward, palm_dir)

    for finger, indices in FINGERS.items():
        chain = (0,) + indices
        for segment in range(1, len(chain) - 1):
            current = safe_normalize(vec(hand[chain[segment + 1]]) - vec(hand[chain[segment]]))
            put_rotation(rotations, f"{side}_{finger}_{segment}", outward, current)
    return rotations


def to_local(global_rotations: dict[str, np.ndarray]) -> dict[str, np.ndarray]:
    local: dict[str, np.ndarray] = {}
    for bone, rotation in global_rotations.items():
        parent = PARENTS.get(bone)
        if parent and parent in global_rotations:
            rotation = quat_mul(quat_inverse(global_rotations[parent]), rotation)
        local[bone] = rotation
    return local


def ensure_quaternion_continuity(samples: list[dict[str, Any]]) -> None:
    previous: np.ndarray | None = None
    for sample in samples:
        current = np.array(sample["rotation"], dtype=np.float64)
        if previous is not None and float(np.dot(previous, current)) < 0.0:
            current = -current
            sample["rotation"] = qlist(current)
        previous = current


def calibrate_tracks(
    raw_tracks: dict[str, list[dict[str, Any]]],
    reference_samples: int,
) -> dict[str, list[dict[str, Any]]]:
    calibrated: dict[str, list[dict[str, Any]]] = {}
    for bone, samples in raw_tracks.items():
        reference_quats = [
            np.array(sample["rotation"], dtype=np.float64)
            for sample in samples[:max(1, reference_samples)]
        ]
        reference = quat_mean(reference_quats)
        inv_reference = quat_inverse(reference)
        limit = rotation_limit_for(bone)
        output = []
        for sample in samples:
            current = np.array(sample["rotation"], dtype=np.float64)
            delta = quat_mul(inv_reference, current)
            delta = clamp_delta(delta, limit)
            output.append({
                "time_ms": float(sample["time_ms"]),
                "rotation": qlist(delta),
            })
        ensure_quaternion_continuity(output)
        calibrated[bone] = output
    return calibrated


def densify_track(
    samples: list[dict[str, Any]],
    timeline: list[float],
    max_gap_ms: float,
) -> list[dict[str, Any]]:
    if len(samples) < 2:
        return samples
    source_times = [float(sample["time_ms"]) for sample in samples]
    result: list[dict[str, Any]] = []
    cursor = 0

    for time_ms in timeline:
        while cursor + 1 < len(samples) and source_times[cursor + 1] < time_ms:
            cursor += 1
        if cursor + 1 >= len(samples):
            break
        a = samples[cursor]
        b = samples[cursor + 1]
        ta = float(a["time_ms"])
        tb = float(b["time_ms"])
        if time_ms < ta or time_ms > tb:
            continue
        gap = tb - ta
        if gap <= 0.0 or gap > max_gap_ms:
            continue
        t = (time_ms - ta) / gap
        qa = np.array(a["rotation"], dtype=np.float64)
        qb = np.array(b["rotation"], dtype=np.float64)
        result.append({
            "time_ms": time_ms,
            "rotation": qlist(quat_slerp(qa, qb, t)),
        })

    # Keep original samples too, then deduplicate by timestamp.
    merged = {round(float(item["time_ms"]), 3): item for item in samples}
    for item in result:
        merged[round(float(item["time_ms"]), 3)] = item
    dense = [merged[key] for key in sorted(merged)]
    ensure_quaternion_continuity(dense)
    return dense


def main() -> int:
    parser = argparse.ArgumentParser(description="Retarget PSL landmark motion into calibrated humanoid delta rotations.")
    parser.add_argument("motion", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    parser.add_argument(
        "--reference-samples",
        type=int,
        default=6,
        help="Valid samples used as the neutral reference for each bone (default: 6).",
    )
    parser.add_argument(
        "--max-gap-ms",
        type=float,
        default=250.0,
        help="Interpolate tracking gaps no longer than this many milliseconds (default: 250).",
    )
    args = parser.parse_args()

    payload = json.loads(args.motion.read_text(encoding="utf-8"))
    if payload.get("schema") != "edubridge.psl.motion.v1":
        raise SystemExit("Unsupported motion schema.")

    frames = payload.get("frames", [])
    timeline = [float(frame.get("time_ms", 0.0)) for frame in frames]
    raw_tracks: dict[str, list[dict[str, Any]]] = {}

    for frame in frames:
        global_rotations = body_rotations(frame)
        global_rotations.update(hand_rotations(frame.get("left_hand"), "left"))
        global_rotations.update(hand_rotations(frame.get("right_hand"), "right"))
        local = to_local(global_rotations)
        for bone, rotation in local.items():
            raw_tracks.setdefault(bone, []).append({
                "time_ms": float(frame.get("time_ms", 0.0)),
                "rotation": qlist(rotation),
            })

    calibrated = calibrate_tracks(raw_tracks, args.reference_samples)
    tracks = {
        bone: densify_track(samples, timeline, args.max_gap_ms)
        for bone, samples in calibrated.items()
    }

    result = {
        "schema": "edubridge.psl.retarget.v2",
        "source_motion_schema": payload.get("schema"),
        "label": payload.get("label", ""),
        "source": payload.get("source", {}),
        "coordinate_system": "x-right,y-up,z-forward",
        "rotation_order": "quaternion-xyzw",
        "bone_space": "local-delta-from-neutral",
        "calibration": {
            "reference_samples": args.reference_samples,
            "max_gap_ms": args.max_gap_ms,
            "joint_limits": "enabled",
        },
        "notes": [
            "Tracks are local motion deltas relative to a per-bone neutral reference.",
            "Short tracking gaps are interpolated with quaternion slerp.",
            "The GLB exporter must compose these deltas with the avatar bind-pose rotations.",
            "PSL linguistic verification remains a separate human review step."
        ],
        "tracks": tracks,
    }

    output = args.output or args.motion.with_name(f"{args.motion.stem}.retarget.json")
    output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(tracks)} calibrated bone tracks to {output}")
    print(f"Reference samples: {args.reference_samples}; max interpolated gap: {args.max_gap_ms:.0f}ms")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
