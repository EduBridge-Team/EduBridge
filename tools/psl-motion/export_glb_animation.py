#!/usr/bin/env python3
"""Inject EduBridge PSL quaternion tracks into a compatible GLB avatar.

The target GLB must use node names that match avatar_bone_map.json (or a
custom mapping supplied with --bone-map). This script does not alter meshes,
skins, materials, or the bind pose; it appends a glTF animation clip.
"""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path
from typing import Any

from pygltflib import (
    ACCESSOR_TYPE_SCALAR,
    ACCESSOR_TYPE_VEC4,
    FLOAT,
    Accessor,
    Animation,
    AnimationChannel,
    AnimationChannelTarget,
    AnimationSampler,
    BufferView,
    GLTF2,
)


def align4(blob: bytearray) -> None:
    while len(blob) % 4:
        blob.append(0)


def append_floats(
    gltf: GLTF2,
    blob: bytearray,
    values: list[float],
    accessor_type: str,
    count: int,
    min_values: list[float] | None = None,
    max_values: list[float] | None = None,
) -> int:
    align4(blob)
    offset = len(blob)
    blob.extend(struct.pack("<" + "f" * len(values), *values))
    length = len(values) * 4

    buffer_view_index = len(gltf.bufferViews)
    gltf.bufferViews.append(BufferView(
        buffer=0,
        byteOffset=offset,
        byteLength=length,
    ))

    accessor_index = len(gltf.accessors)
    gltf.accessors.append(Accessor(
        bufferView=buffer_view_index,
        byteOffset=0,
        componentType=FLOAT,
        count=count,
        type=accessor_type,
        min=min_values or [],
        max=max_values or [],
    ))
    return accessor_index


def main() -> int:
    parser = argparse.ArgumentParser(description="Append PSL retarget tracks to a GLB avatar.")
    parser.add_argument("avatar", type=Path, help="Input avatar GLB.")
    parser.add_argument("retarget", type=Path, help="Retarget JSON from retarget_motion.py.")
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--bone-map", type=Path, default=Path(__file__).with_name("avatar_bone_map.json"))
    parser.add_argument("--name", default="PSL_Sign")
    parser.add_argument("--strict", action="store_true", help="Fail if any mapped bone is missing in the GLB.")
    args = parser.parse_args()

    motion = json.loads(args.retarget.read_text(encoding="utf-8"))
    if motion.get("schema") != "edubridge.psl.retarget.v1":
        raise SystemExit("Unsupported retarget schema.")

    mapping_payload = json.loads(args.bone_map.read_text(encoding="utf-8"))
    bone_map: dict[str, str] = mapping_payload.get("bones", {})

    gltf = GLTF2().load(str(args.avatar))
    if not gltf.buffers:
        raise SystemExit("Avatar has no glTF buffer.")

    node_by_name = {
        node.name: index
        for index, node in enumerate(gltf.nodes)
        if node.name
    }

    blob = bytearray(gltf.binary_blob() or b"")
    channels: list[AnimationChannel] = []
    samplers: list[AnimationSampler] = []
    missing: list[str] = []

    for logical_bone, samples in motion.get("tracks", {}).items():
        node_name = bone_map.get(logical_bone)
        if not node_name:
            continue
        node_index = node_by_name.get(node_name)
        if node_index is None:
            missing.append(f"{logical_bone} -> {node_name}")
            continue
        if not samples:
            continue

        times = [float(sample["time_ms"]) / 1000.0 for sample in samples]
        rotations = [
            float(component)
            for sample in samples
            for component in sample["rotation"]
        ]

        input_accessor = append_floats(
            gltf,
            blob,
            times,
            ACCESSOR_TYPE_SCALAR,
            len(times),
            [min(times)],
            [max(times)],
        )
        output_accessor = append_floats(
            gltf,
            blob,
            rotations,
            ACCESSOR_TYPE_VEC4,
            len(samples),
        )

        sampler_index = len(samplers)
        samplers.append(AnimationSampler(
            input=input_accessor,
            output=output_accessor,
            interpolation="LINEAR",
        ))
        channels.append(AnimationChannel(
            sampler=sampler_index,
            target=AnimationChannelTarget(
                node=node_index,
                path="rotation",
            ),
        ))

    if args.strict and missing:
        raise SystemExit("Missing GLB bones:\n- " + "\n- ".join(missing))

    if not channels:
        known = ", ".join(sorted(node_by_name.keys())[:25])
        raise SystemExit(
            "No animation channels could be created. "
            f"Check the bone map. First GLB node names: {known}"
        )

    gltf.animations.append(Animation(
        name=args.name,
        channels=channels,
        samplers=samplers,
    ))

    gltf.buffers[0].byteLength = len(blob)
    gltf.set_binary_blob(bytes(blob))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    gltf.save_binary(str(args.output))

    print(f"Wrote {args.output}")
    print(f"Animation channels: {len(channels)}")
    if missing:
        print(f"Skipped missing mapped bones: {len(missing)}")
        for item in missing:
            print(f"- {item}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
