#!/usr/bin/env python3
"""Generate an EduBridge PSL bone map from a GLB using common humanoid aliases."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from pygltflib import GLTF2


ALIASES = {
    "hips": ["Hips", "mixamorig:Hips", "mixamorigHips"],
    "spine": ["Spine", "Spine1", "mixamorig:Spine", "mixamorigSpine"],
    "neck": ["Neck", "mixamorig:Neck", "mixamorigNeck"],
    "head": ["Head", "mixamorig:Head", "mixamorigHead"],
    "left_upper_arm": ["LeftUpperArm", "LeftArm", "mixamorig:LeftArm", "mixamorigLeftArm"],
    "left_lower_arm": ["LeftLowerArm", "LeftForeArm", "mixamorig:LeftForeArm", "mixamorigLeftForeArm"],
    "left_hand": ["LeftHand", "mixamorig:LeftHand", "mixamorigLeftHand"],
    "right_upper_arm": ["RightUpperArm", "RightArm", "mixamorig:RightArm", "mixamorigRightArm"],
    "right_lower_arm": ["RightLowerArm", "RightForeArm", "mixamorig:RightForeArm", "mixamorigRightForeArm"],
    "right_hand": ["RightHand", "mixamorig:RightHand", "mixamorigRightHand"],
}

FINGER_ALIASES = {
    "thumb": ["Thumb"],
    "index": ["Index", "IndexFinger"],
    "middle": ["Middle", "MiddleFinger"],
    "ring": ["Ring", "RingFinger"],
    "pinky": ["Pinky", "Little", "LittleFinger"],
}


def normalized(value: str) -> str:
    return re.sub(r"[^a-z0-9]", "", value.lower())


def choose(nodes: list[str], aliases: list[str]) -> str | None:
    exact = {name: name for name in nodes}
    for alias in aliases:
        if alias in exact:
            return exact[alias]

    normalized_nodes = {normalized(name): name for name in nodes}
    for alias in aliases:
        match = normalized_nodes.get(normalized(alias))
        if match:
            return match
    return None


def finger_aliases(side: str, finger: str, segment: int) -> list[str]:
    side_cap = "Left" if side == "left" else "Right"
    prefixes = [
        f"{side_cap}Hand",
        f"{side_cap}",
        f"mixamorig:{side_cap}Hand",
        f"mixamorig{side_cap}Hand",
    ]
    names = []
    for prefix in prefixes:
        for finger_name in FINGER_ALIASES[finger]:
            names.extend([
                f"{prefix}{finger_name}{segment}",
                f"{prefix}{finger_name}_{segment}",
            ])
    return names


def main() -> int:
    parser = argparse.ArgumentParser(description="Auto-detect humanoid bone names in a GLB.")
    parser.add_argument("avatar", type=Path)
    parser.add_argument("-o", "--output", type=Path, default=Path("generated_bone_map.json"))
    args = parser.parse_args()

    gltf = GLTF2().load(str(args.avatar))
    nodes = [node.name for node in gltf.nodes if node.name]

    bones: dict[str, str] = {}
    missing: list[str] = []

    for logical, aliases in ALIASES.items():
        match = choose(nodes, aliases)
        if match:
            bones[logical] = match
        else:
            missing.append(logical)

    for side in ("left", "right"):
        for finger in FINGER_ALIASES:
            for segment in (1, 2, 3):
                logical = f"{side}_{finger}_{segment}"
                match = choose(nodes, finger_aliases(side, finger, segment))
                if match:
                    bones[logical] = match
                else:
                    missing.append(logical)

    payload = {
        "schema": "edubridge.psl.avatar-bones.v1",
        "source_avatar": args.avatar.name,
        "auto_detected": True,
        "bones": bones,
        "missing": missing,
    }
    args.output.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Wrote bone map: {args.output}")
    print(f"Detected: {len(bones)}")
    print(f"Missing: {len(missing)}")
    if missing:
        print("Missing logical bones:")
        for bone in missing:
            print(f"- {bone}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
