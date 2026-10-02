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
  -> calibrated retargeting
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

## 4. Retarget and calibrate motion

```bash
python retarget_motion.py triangle.motion.smooth.json
```

Output:

```text
triangle.motion.smooth.retarget.json
```

Retarget v2 adds three important corrections:

- per-bone neutral calibration from the first valid samples
- short-gap interpolation using quaternion slerp
- conservative joint rotation limits for torso, arms, wrists, and fingers

The result contains **local motion deltas**, not absolute avatar rotations. This prevents the mocap stage from destroying the avatar's authored rest pose.

For a clip whose neutral pose needs more or fewer reference frames:

```bash
python retarget_motion.py triangle.motion.smooth.json \
  --reference-samples 6 \
  --max-gap-ms 250
```

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

## 7. Export a calibrated GLB animation

```bash
mkdir -p generated

python export_glb_animation.py \
  edubridge-avatar.glb \
  triangle.motion.smooth.retarget.json \
  --bone-map generated_bone_map.json \
  --name PSL_Triangle \
  -o generated/psl_triangle.glb
```

For retarget v2, the exporter reads each target GLB node's actual bind rotation and composes the calibrated motion delta on top of it. The mesh, skin, materials, and rest pose remain intact.

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

The pipeline is now bind-pose aware, but production-quality sign animation still requires visual QA. In particular:

- monocular video can lose depth accuracy when hands move toward/away from the camera
- hand/face occlusion can reduce tracking quality
- palm twist is approximated from available landmarks and may still need rig-specific refinement
- facial non-manual markers are captured as landmarks but are not yet exported as blendshape animation
- a generated motion must still be reviewed by a PSL specialist before `animation_status=verified`

After one avatar is visually calibrated, the same pipeline can process additional PSL clips without per-video credits or Blender.
