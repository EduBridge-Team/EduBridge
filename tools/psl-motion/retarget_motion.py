#!/usr/bin/env python3
"""Retarget EduBridge PSL landmarks into humanoid bone delta rotations.

Version 2 focuses on sign-language motion quality:
- arm joints use parent/child joint angles instead of raw absolute directions
- wrist rotation uses a full palm coordinate frame (forward + palm normal)
- finger joints use relative segment bends rather than global finger direction
- short tracking gaps are interpolated with quaternion slerp
- output stays avatar-independent and is composed with the GLB bind pose later

The output is still a technical motion estimate and must not be treated as a
verified PSL sign without human review.
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

IDENTITY = np.array([0.0, 0.0, 0.0, 1.0], dtype=np.float64)


def vec(point: dict[str, Any]) -> np.ndarray:
    # MediaPipe -> EduBridge normalized frame.
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
    return IDENTITY.copy() if norm < 1e-8 else q / norm


def quat_mul(a: np.ndarray, b: np.ndarray) -> np.ndarray:
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return quat_normalize(np.array([
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    ], dtype=np.float64))


def quat_inverse(q: np.ndarray) -> np.ndarray:
    q = quat_normalize(q)
    return np.array([-q[0], -q[1], -q[2], q[3]], dtype=np.float64)


def quat_from_to(source: np.ndarray, target: np.ndarray) -> np.ndarray:
    a = safe_normalize(source)
    b = safe_normalize(target)
    if a is None or b is None:
        return IDENTITY.copy()

    dot = float(np.clip(np.dot(a, b), -1.0, 1.0))
    if dot > 0.999999:
        return IDENTITY.copy()

    if dot < -0.999999:
        axis = np.cross(a, np.array([1.0, 0.0, 0.0]))
        if np.linalg.norm(axis) < 1e-6:
            axis = np.cross(a, np.array([0.0, 1.0, 0.0]))
        axis = safe_normalize(axis)
        if axis is None:
            return IDENTITY.copy()
        return np.array([axis[0], axis[1], axis[2], 0.0], dtype=np.float64)

    cross = np.cross(a, b)
    return quat_normalize(np.array([
        cross[0], cross[1], cross[2], 1.0 + dot
    ], dtype=np.float64))


def quat_from_matrix(matrix: np.ndarray) -> np.ndarray:
    """Quaternion xyzw from a right-handed 3x3 rotation matrix."""
    m = matrix
    trace = float(np.trace(m))
    if trace > 0.0:
        s = math.sqrt(trace + 1.0) * 2.0
        return quat_normalize(np.array([
            (m[2, 1] - m[1, 2]) / s,
            (m[0, 2] - m[2, 0]) / s,
            (m[1, 0] - m[0, 1]) / s,
            0.25 * s,
        ], dtype=np.float64))

    diagonal = [m[0, 0], m[1, 1], m[2, 2]]
    i = int(np.argmax(diagonal))
    if i == 0:
        s = math.sqrt(max(1e-12, 1.0 + m[0, 0] - m[1, 1] - m[2, 2])) * 2.0
        q = [(0.25 * s), (m[0, 1] + m[1, 0]) / s, (m[0, 2] + m[2, 0]) / s, (m[2, 1] - m[1, 2]) / s]
    elif i == 1:
        s = math.sqrt(max(1e-12, 1.0 + m[1, 1] - m[0, 0] - m[2, 2])) * 2.0
        q = [(m[0, 1] + m[1, 0]) / s, (0.25 * s), (m[1, 2] + m[2, 1]) / s, (m[0, 2] - m[2, 0]) / s]
    else:
        s = math.sqrt(max(1e-12, 1.0 + m[2, 2] - m[0, 0] - m[1, 1])) * 2.0
        q = [(m[0, 2] + m[2, 0]) / s, (m[1, 2] + m[2, 1]) / s, (0.25 * s), (m[1, 0] - m[0, 1]) / s]
    return quat_normalize(np.array(q, dtype=np.float64))


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
        math.sin((1.0 - t) * theta) / sin_theta * a
        + math.sin(t * theta) / sin_theta * b
    )


def clamp_quaternion(q: np.ndarray, max_degrees: float) -> np.ndarray:
    q = quat_normalize(q)
    if q[3] < 0.0:
        q = -q
    angle = 2.0 * math.acos(float(np.clip(q[3], -1.0, 1.0)))
    limit = math.radians(max_degrees)
    if angle <= limit or angle < 1e-8:
        return q
    axis = safe_normalize(q[:3])
    if axis is None:
        return IDENTITY.copy()
    half = limit * 0.5
    return quat_normalize(np.array([
        axis[0] * math.sin(half),
        axis[1] * math.sin(half),
        axis[2] * math.sin(half),
        math.cos(half),
    ]))


def qlist(q: np.ndarray) -> list[float]:
    return [round(float(v), 7) for v in quat_normalize(q)]


def point(points: list[dict[str, Any]], name: str) -> dict[str, Any] | None:
    index = POSE[name]
    return points[index] if index < len(points) else None


def segment(a: dict[str, Any] | None, b: dict[str, Any] | None) -> np.ndarray | None:
    if a is None or b is None:
        return None
    return safe_normalize(vec(b) - vec(a))


def midpoint(a: dict[str, Any], b: dict[str, Any]) -> np.ndarray:
    return (vec(a) + vec(b)) * 0.5


def frame_quaternion(x_axis: np.ndarray, y_hint: np.ndarray) -> np.ndarray:
    """Build a stable orientation where local +X follows x_axis."""
    x = safe_normalize(x_axis)
    y = safe_normalize(y_hint)
    if x is None or y is None:
        return IDENTITY.copy()
    z = safe_normalize(np.cross(x, y))
    if z is None:
        fallback = np.array([0.0, 0.0, 1.0])
        z = safe_normalize(np.cross(x, fallback))
        if z is None:
            return IDENTITY.copy()
    y = safe_normalize(np.cross(z, x))
    if y is None:
        return IDENTITY.copy()
    return quat_from_matrix(np.column_stack((x, y, z)))


def body_rotations(frame: dict[str, Any]) -> dict[str, np.ndarray]:
    pose = frame.get("pose")
    if not isinstance(pose, list):
        return {}

    ls, rs = point(pose, "left_shoulder"), point(pose, "right_shoulder")
    le, re = point(pose, "left_elbow"), point(pose, "right_elbow")
    lw, rw = point(pose, "left_wrist"), point(pose, "right_wrist")
    lh, rh = point(pose, "left_hip"), point(pose, "right_hip")
    nose = point(pose, "nose")

    out: dict[str, np.ndarray] = {}

    if ls and rs and lh and rh:
        shoulder_axis = safe_normalize(vec(rs) - vec(ls))
        torso_axis = safe_normalize(midpoint(ls, rs) - midpoint(lh, rh))
        if shoulder_axis is not None and torso_axis is not None:
            out["spine"] = clamp_quaternion(
                quat_mul(
                    quat_inverse(frame_quaternion(np.array([1.0, 0.0, 0.0]), np.array([0.0, 1.0, 0.0]))),
                    frame_quaternion(shoulder_axis, torso_axis),
                ),
                40.0,
            )

        if nose is not None:
            head_dir = safe_normalize(vec(nose) - midpoint(ls, rs))
            if head_dir is not None:
                head_delta = clamp_quaternion(quat_from_to(np.array([0.0, 1.0, 0.0]), head_dir), 50.0)
                out["neck"] = head_delta
                out["head"] = clamp_quaternion(head_delta, 35.0)

    for side, shoulder, elbow, wrist, bind_axis in (
        ("left", ls, le, lw, np.array([1.0, 0.0, 0.0])),
        ("right", rs, re, rw, np.array([-1.0, 0.0, 0.0])),
    ):
        upper = segment(shoulder, elbow)
        lower = segment(elbow, wrist)
        if upper is not None:
            out[f"{side}_upper_arm"] = clamp_quaternion(quat_from_to(bind_axis, upper), 145.0)
        if upper is not None and lower is not None:
            # Elbow is a relative bend from the upper arm direction.
            out[f"{side}_lower_arm"] = clamp_quaternion(quat_from_to(upper, lower), 155.0)

    return out


def palm_rotation(hand: list[dict[str, Any]], side: str) -> np.ndarray:
    wrist = vec(hand[0])
    index_mcp = vec(hand[5])
    middle_mcp = vec(hand[9])
    pinky_mcp = vec(hand[17])

    forward = safe_normalize(middle_mcp - wrist)
    across = safe_normalize(index_mcp - pinky_mcp)
    if forward is None or across is None:
        return IDENTITY.copy()

    normal = safe_normalize(np.cross(across, forward))
    if normal is None:
        return IDENTITY.copy()

    # Keep left/right palm normals consistent so mirrored hands do not flip.
    if side == "left":
        normal = -normal

    observed = frame_quaternion(forward, normal)
    canonical_forward = np.array([1.0, 0.0, 0.0]) if side == "left" else np.array([-1.0, 0.0, 0.0])
    canonical_normal = np.array([0.0, 0.0, 1.0])
    canonical = frame_quaternion(canonical_forward, canonical_normal)
    return clamp_quaternion(quat_mul(quat_inverse(canonical), observed), 120.0)


def hand_rotations(hand: list[dict[str, Any]] | None, side: str) -> dict[str, np.ndarray]:
    if not isinstance(hand, list) or len(hand) < 21:
        return {}

    out: dict[str, np.ndarray] = {f"{side}_hand": palm_rotation(hand, side)}
    palm_forward = safe_normalize(vec(hand[9]) - vec(hand[0]))

    for finger, indices in FINGERS.items():
        points = [vec(hand[index]) for index in indices]
        directions: list[np.ndarray | None] = []
        for i in range(len(points) - 1):
            directions.append(safe_normalize(points[i + 1] - points[i]))

        # First phalanx rotates relative to the palm direction.
        if palm_forward is not None and directions[0] is not None:
            out[f"{side}_{finger}_1"] = clamp_quaternion(
                quat_from_to(palm_forward, directions[0]),
                105.0 if finger == "thumb" else 95.0,
            )

        # Remaining phalanges rotate relative to the previous finger segment.
        for segment_index in (1, 2):
            previous = directions[segment_index - 1]
            current = directions[segment_index]
            if previous is None or current is None:
                continue
            out[f"{side}_{finger}_{segment_index + 1}"] = clamp_quaternion(
                quat_from_to(previous, current),
                95.0,
            )

    return out


def ensure_continuity(samples: list[dict[str, Any]]) -> None:
    previous: np.ndarray | None = None
    for sample in samples:
        q = np.array(sample["rotation"], dtype=np.float64)
        if previous is not None and float(np.dot(previous, q)) < 0.0:
            q = -q
            sample["rotation"] = qlist(q)
        previous = q


def densify_track(samples: list[dict[str, Any]], timeline: list[float], max_gap_ms: float) -> list[dict[str, Any]]:
    if len(samples) < 2:
        return samples

    source = sorted(samples, key=lambda item: float(item["time_ms"]))
    source_times = [float(item["time_ms"]) for item in source]
    merged = {round(float(item["time_ms"]), 3): item for item in source}
    cursor = 0

    for time_ms in timeline:
        while cursor + 1 < len(source) and source_times[cursor + 1] < time_ms:
            cursor += 1
        if cursor + 1 >= len(source):
            break
        a, b = source[cursor], source[cursor + 1]
        ta, tb = float(a["time_ms"]), float(b["time_ms"])
        if time_ms <= ta or time_ms >= tb:
            continue
        gap = tb - ta
        if gap <= 0.0 or gap > max_gap_ms:
            continue
        t = (time_ms - ta) / gap
        qa = np.array(a["rotation"], dtype=np.float64)
        qb = np.array(b["rotation"], dtype=np.float64)
        merged[round(time_ms, 3)] = {
            "time_ms": time_ms,
            "rotation": qlist(quat_slerp(qa, qb, t)),
            "interpolated": True,
        }

    result = [merged[key] for key in sorted(merged)]
    ensure_continuity(result)
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description="Retarget PSL landmarks with joint-angle and palm-plane solving.")
    parser.add_argument("motion", type=Path)
    parser.add_argument("-o", "--output", type=Path)
    parser.add_argument("--max-gap-ms", type=float, default=250.0)
    # Kept for backwards-compatible scripts; no longer used in v2.
    parser.add_argument("--reference-samples", type=int, default=0, help=argparse.SUPPRESS)
    args = parser.parse_args()

    payload = json.loads(args.motion.read_text(encoding="utf-8"))
    if payload.get("schema") != "edubridge.psl.motion.v1":
        raise SystemExit("Unsupported motion schema.")

    frames = payload.get("frames", [])
    timeline = [float(frame.get("time_ms", 0.0)) for frame in frames]
    tracks: dict[str, list[dict[str, Any]]] = {}

    for frame in frames:
        rotations = body_rotations(frame)
        rotations.update(hand_rotations(frame.get("left_hand"), "left"))
        rotations.update(hand_rotations(frame.get("right_hand"), "right"))
        time_ms = float(frame.get("time_ms", 0.0))
        for bone, rotation in rotations.items():
            tracks.setdefault(bone, []).append({
                "time_ms": time_ms,
                "rotation": qlist(rotation),
            })

    dense_tracks = {
        bone: densify_track(samples, timeline, args.max_gap_ms)
        for bone, samples in tracks.items()
    }

    result = {
        "schema": "edubridge.psl.retarget.v2",
        "source_motion_schema": payload.get("schema"),
        "label": payload.get("label", ""),
        "source": payload.get("source", {}),
        "coordinate_system": "x-right,y-up,z-forward",
        "rotation_order": "quaternion-xyzw",
        "bone_space": "bind-pose-delta",
        "solver": "joint-angles+palm-plane",
        "max_interpolated_gap_ms": args.max_gap_ms,
        "notes": [
            "Upper arms use avatar-style bind axes while elbows use relative joint bends.",
            "Wrist orientation uses the palm plane to preserve pronation/supination better than a single direction vector.",
            "Finger joints are solved as relative segment bends.",
            "The GLB exporter composes each delta with the avatar's bind rotation.",
            "Human PSL review is still required before any sign can be marked verified."
        ],
        "tracks": dense_tracks,
    }

    output = args.output or args.motion.with_name(f"{args.motion.stem}.retarget.json")
    output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Wrote {len(dense_tracks)} joint-angle bone tracks to {output}")
    print(f"Solver: joint-angles+palm-plane; max interpolated gap: {args.max_gap_ms:g}ms")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
