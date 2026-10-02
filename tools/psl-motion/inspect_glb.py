#!/usr/bin/env python3
"""List nodes and animation clips in a GLB so a bone map can be prepared without Blender."""

from __future__ import annotations

import argparse
from pathlib import Path

from pygltflib import GLTF2


def main() -> int:
    parser = argparse.ArgumentParser(description="Inspect a GLB avatar.")
    parser.add_argument("avatar", type=Path)
    args = parser.parse_args()

    gltf = GLTF2().load(str(args.avatar))

    print("Nodes:")
    for index, node in enumerate(gltf.nodes):
        if node.name:
            print(f"{index:4d}  {node.name}")

    print("\nAnimations:")
    if not gltf.animations:
        print("(none)")
    else:
        for index, animation in enumerate(gltf.animations):
            print(f"{index:4d}  {animation.name or '(unnamed)'}  channels={len(animation.channels)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
