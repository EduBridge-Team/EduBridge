# EduBridge PSL Motion Capture

Local, credit-free motion capture tooling for the Palestinian Sign Language (PSL) avatar pipeline.

This toolset **does not recognise or validate the meaning of a sign**. It only extracts and retargets motion from a video. Every sign must still be reviewed by a qualified Palestinian Sign Language signer/specialist before it can be marked `verified`.

## Pipeline

```text
phone video
  -> MediaPipe Holistic
  -> body + left hand + right hand + compact face landmarks
  -> smoothing
  -> capture-quality validation
  -> joint-angle + palm-plane retargeting
  -> bind-pose composition
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

## 3. Validate capture quality

```bash
python validate_motion.py triangle.motion.smooth.json
```

The validator checks tracking coverage. It does **not** verify that the performed sign is correct.

A failed validation usually means the hands left the frame, were occluded, or the lighting/background needs improvement.

## Motion JSON policy

Raw videos and generated motion files may contain biometric motion information. Do not commit real participant recordings or generated motion JSON to the public repository.

Keep them in an approved private storage location and only publish reviewed animation assets intended for end users.

## 4. Retarget motion

```bash
python retarget_motion.py triangle.motion.smooth.json \
  --max-gap-ms 250
```

Output:

```text
triangle.motion.smooth.retarget.json
```

The v2 solver now uses motion geometry directly instead of treating the first few captured frames as the avatar's neutral pose:

- upper arms are aimed from the avatar-style left/right bind axes
- elbows use the relative angle between upper-arm and forearm segments
- wrist orientation comes from a full palm coordinate frame, including palm normal / twist
- finger bones use relative bends between neighboring phalanges
- short tracking gaps are filled with quaternion slerp
- conservative limits are applied to unstable rotations

The result uses schema `edubridge.psl.retarget.v2` and contains bind-pose delta rotations. The GLB exporter composes those deltas on top of the avatar's authored bind rotations.

`--reference-samples` is still accepted for backwards-compatible scripts, but v2 no longer relies on it.

## 5. Inspect an avatar GLB

```bash
python inspect_glb.py edubridge-avatar.glb
```

## 6. Generate the avatar bone map

For common humanoid rigs, including Ready Player Me, Mixamo, and the `J_Bip_*` VRM naming used by the current test avatar:

```bash
python auto_bone_map.py edubridge-avatar.glb -o generated_bone_map.json
```

Review any unmatched bones printed by the tool. A sign-language avatar should expose finger bones for thumb, index, middle, ring, and little/pinky fingers on both hands.

## 7. Export a GLB animation

```bash
mkdir -p generated

python export_glb_animation.py \
  edubridge-avatar.glb \
  triangle.motion.smooth.retarget.json \
  --bone-map generated_bone_map.json \
  --name PSL_Triangle \
  -o generated/psl_triangle.glb
```

For retarget v2, the exporter reads each target GLB node's real bind rotation and composes the motion delta on top of it. The mesh, skin, materials, and rest pose remain intact.

Expected export output includes:

```text
Animation channels: <count>
Bind-pose composition: enabled
```

For a strict compatibility check:

```bash
python export_glb_animation.py \
  edubridge-avatar.glb \
  triangle.motion.smooth.retarget.json \
  --bone-map generated_bone_map.json \
  --strict \
  -o generated/psl_triangle.glb
```

## Current limitations

The pipeline is bind-pose aware and uses relative joint geometry, but production-quality sign animation still requires visual QA. In particular:

- monocular video can lose depth accuracy when hands move toward/away from the camera
- hand/face occlusion can reduce tracking quality
- wrist and finger twist may still require rig-specific tuning
- facial non-manual markers are captured as landmarks but are not yet exported as blendshape animation
- a generated motion must still be reviewed by a PSL specialist before `animation_status=verified`

After one avatar is visually calibrated, the same pipeline can process additional PSL clips without per-video credits or Blender.
