# EduBridge PSL Motion Capture

Local, credit-free motion capture tooling for the Palestinian Sign Language (PSL) avatar pipeline.

This toolset **does not recognise or validate the meaning of a sign**. It only extracts motion from a video. Every sign must still be reviewed by a qualified Palestinian Sign Language signer/specialist before it can be marked `verified`.

## Pipeline

```text
phone video
  -> MediaPipe Holistic
  -> body + left hand + right hand + compact face landmarks
  -> smoothing
  -> capture-quality validation
  -> retargeting (next phase)
  -> GLB animation
  -> EduBridge
```

## Requirements

Use Python 3.10 or 3.11 for the easiest MediaPipe setup.

```bash
cd tools/psl-motion
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Recording guidance

For the first tests:

- Record at 1080p / 30fps when possible.
- Use a plain, contrasting background.
- Keep the signer from the waist/chest upward in frame.
- Keep both hands fully visible throughout the sign.
- Avoid motion blur and backlighting.
- Leave roughly half a second of neutral pose before and after the sign.
- Keep clips short (typically 2–6 seconds).
- Do not mirror videos after recording unless the review workflow explicitly requires it.

## 1. Extract landmarks

```bash
python extract_landmarks.py triangle.mp4 --label "مثلث / Triangle"
```

Output:

```text
triangle.motion.json
```

The JSON uses schema `edubridge.psl.motion.v1` and contains:

- 33 pose landmarks when detected
- 21 landmarks for each detected hand
- a compact face landmark subset for expression/head orientation
- source FPS, size, duration, and detection coverage

## 2. Smooth motion

```bash
python smooth_motion.py triangle.motion.json --radius 2
```

Output:

```text
triangle.motion.smooth.json
```

The first implementation uses a moving average deliberately: it is predictable, inspectable, and easy to compare before introducing more advanced filters.

## 3. Validate capture quality

```bash
python validate_motion.py triangle.motion.smooth.json
```

The validator checks tracking coverage. It does **not** verify that the performed sign is correct.

A failed validation usually means the hands left the frame, were occluded, or the lighting/background needs improvement.

## Motion JSON policy

Raw videos and generated motion files may contain biometric motion information. Do not commit real participant recordings or generated motion JSON to the public repository.

Keep them in an approved private storage location and only publish reviewed animation assets intended for end users.

## Next phase: retargeting

The next stage converts the normalized landmark vectors into rotations for the EduBridge avatar skeleton:

```text
MediaPipe landmarks
 -> body/hand local coordinate frames
 -> joint rotations
 -> avatar bone map
 -> smoothing/constraints
 -> glTF animation channels
 -> GLB
```

The hand retargeter must map all finger joints explicitly. A normal body-only mocap retargeter is not sufficient for sign language.
