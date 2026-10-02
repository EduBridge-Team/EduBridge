#!/usr/bin/env python3
"""Generate an EduBridge PSL bone map from a GLB using common humanoid aliases."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from pygltflib import GLTF2


ALIASES = {
    "hips": ["Hips", "mixamorig:Hips", "mixamorigHips", "J_Bip_C_Hips"],
    "spine": ["Spine", "Spine1", "mixamorig:Spine", "mixamorigSpine", "J_Bip_C_Spine", "J_Bip_C_Chest", "J_Bip_C_UpperChest"],
    "neck": ["Neck", "mixamorig:Neck", "mixamorigNeck", "J_Bip_C_Neck"],
    "head": ["Head", "mixamorig:Head", "mixamorigHead", "J_Bip_C_Head"],
    "left_upper_arm": ["LeftUpperArm", "LeftArm", "mixamorig:LeftArm", "mixamorigLeftArm", "J_Bip_L_UpperArm"],
    "left_lower_arm": ["LeftLowerArm", "LeftForeArm", "mixamorig:LeftForeArm", "mixamorigLeftForeArm", "J_Bip_L_LowerArm"],
    "left_hand": ["LeftHand", "mixamorig:LeftHand", "mixamorigLeftHand", "J_Bip_L_Hand"],
    "right_upper_arm": ["RightUpperArm", "RightArm", "mixamorig:RightArm", "mixamorigRightArm", "J_Bip_R_UpperArm"],
    "right_lower_arm": ["RightLowerArm", "RightForeArm", "mixamorig:RightForeArm", "mixamorigRightForeArm", "J_Bip_R_LowerArm"],
    "right_hand": ["RightHand", "mixamorig:RightHand", "mixamorigRightHand", "J_Bip_R_Hand"],
}

FINGER_ALIASES = {
    "thumb": ["Thumb"],
    "index": ["Index", "IndexFinger"],
    "middle": ["Middle", "MiddleFinger"],
    "ring": ["Ring", "RingFinger"],
    "pinky": ["Pinky", "Little", "LittleFinger"],
}

VRM_FINGER_PREFIX = {
    "left": "J_Bip_L_",
    "right": "J_Bip_R_",
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

    # VRM/UniVRM rigs commonly use names such as J_Bip_L_Index1
    # and J_Bip_R_Little3.
    vrm_prefix = VRM_FINGER_PREFIX[side]
    vrm_finger = "Little" if finger == "pinky" else finger.capitalize()
    names.extend([
        f"{vrm_prefix}{vrm_finger}{segment}",
        f"{vrm_prefix}{vrm_finger}_{segment}",
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
