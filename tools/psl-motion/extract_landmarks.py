#!/usr/bin/env python3
"""Extract PSL motion landmarks from a video using MediaPipe Holistic.

Output format is intentionally renderer-neutral. It keeps pose, both hands,
and a compact face subset so the next retargeting stage can map motion onto
any compatible EduBridge avatar rig.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import cv2
import mediapipe as mp


FACE_INDICES = [
    1, 4, 5, 6, 10, 13, 14, 17, 33, 46, 52, 55, 61, 63, 65, 66,
    70, 78, 105, 107, 133, 145, 152, 159, 234, 263, 276, 282, 285,
    291, 293, 295, 296, 300, 308, 334, 336, 362, 374, 386, 454,
]


def landmark_to_dict(landmark: Any) -> dict[str, float]:
    payload = {
        "x": round(float(landmark.x), 7),
        "y": round(float(landmark.y), 7),
        "z": round(float(landmark.z), 7),
    }
    visibility = getattr(landmark, "visibility", None)
    if visibility is not None:
        payload["visibility"] = round(float(visibility), 7)
    return payload


def serialize_landmarks(landmarks: Any) -> list[dict[str, float]] | None:
    if landmarks is None:
        return None
    return [landmark_to_dict(item) for item in landmarks.landmark]


def serialize_face(landmarks: Any) -> dict[str, dict[str, float]] | None:
    if landmarks is None:
        return None
    return {
        str(index): landmark_to_dict(landmarks.landmark[index])
        for index in FACE_INDICES
        if index < len(landmarks.landmark)
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract body/hand/face motion from a PSL video.")
    parser.add_argument("video", type=Path, help="Input MP4/MOV video.")
    parser.add_argument("-o", "--output", type=Path, help="Output JSON path.")
    parser.add_argument("--label", default="", help="Optional Arabic/English label for the clip.")
    parser.add_argument("--model-complexity", type=int, choices=(0, 1, 2), default=1)
    parser.add_argument("--min-detection-confidence", type=float, default=0.55)
    parser.add_argument("--min-tracking-confidence", type=float, default=0.55)
    args = parser.parse_args()

    if not args.video.is_file():
        raise SystemExit(f"Video not found: {args.video}")

    output = args.output or args.video.with_suffix(".motion.json")
    output.parent.mkdir(parents=True, exist_ok=True)

    capture = cv2.VideoCapture(str(args.video))
    if not capture.isOpened():
        raise SystemExit(f"Could not open video: {args.video}")

    fps = capture.get(cv2.CAP_PROP_FPS) or 30.0
    width = int(capture.get(cv2.CAP_PROP_FRAME_WIDTH) or 0)
    height = int(capture.get(cv2.CAP_PROP_FRAME_HEIGHT) or 0)
    expected_frames = int(capture.get(cv2.CAP_PROP_FRAME_COUNT) or 0)

    frames: list[dict[str, Any]] = []
    mp_holistic = mp.solutions.holistic

    with mp_holistic.Holistic(
        static_image_mode=False,
        model_complexity=args.model_complexity,
        smooth_landmarks=True,
        refine_face_landmarks=True,
        min_detection_confidence=args.min_detection_confidence,
        min_tracking_confidence=args.min_tracking_confidence,
    ) as holistic:
        frame_index = 0
        while True:
            ok, frame = capture.read()
            if not ok:
                break

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            rgb.flags.writeable = False
            result = holistic.process(rgb)

            frames.append({
                "frame": frame_index,
                "time_ms": round((frame_index / fps) * 1000.0, 3),
                "pose": serialize_landmarks(result.pose_landmarks),
                "left_hand": serialize_landmarks(result.left_hand_landmarks),
                "right_hand": serialize_landmarks(result.right_hand_landmarks),
                "face": serialize_face(result.face_landmarks),
            })
            frame_index += 1

    capture.release()

    detected_left = sum(1 for frame in frames if frame["left_hand"])
    detected_right = sum(1 for frame in frames if frame["right_hand"])
    detected_pose = sum(1 for frame in frames if frame["pose"])

    payload = {
        "schema": "edubridge.psl.motion.v1",
        "label": args.label,
        "source": {
            "filename": args.video.name,
            "width": width,
            "height": height,
            "fps": round(float(fps), 5),
            "expected_frames": expected_frames,
            "processed_frames": len(frames),
            "duration_ms": round((len(frames) / fps) * 1000.0, 3) if fps else 0,
        },
        "tracking": {
            "engine": "mediapipe-holistic",
            "model_complexity": args.model_complexity,
            "face_landmarks": "compact-subset",
            "pose_frames_detected": detected_pose,
            "left_hand_frames_detected": detected_left,
            "right_hand_frames_detected": detected_right,
        },
        "frames": frames,
    }

    output.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    print(f"Wrote {len(frames)} frames to {output}")
    print(
        "Detection coverage: "
        f"pose={detected_pose}/{len(frames)}, "
        f"left_hand={detected_left}/{len(frames)}, "
        f"right_hand={detected_right}/{len(frames)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
