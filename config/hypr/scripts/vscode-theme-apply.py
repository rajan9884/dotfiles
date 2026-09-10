#!/usr/bin/env python3
"""Merge the matugen-generated VS Code color fragment into the user settings.json.

Preserves every other key already present in settings.json (only the
workbench.colorCustomizations / editor.tokenColorCustomizations /
terminal.integrated.ansiColors keys are updated, matching the fragment).
"""
import json
import os
import sys

HOME = os.path.expanduser("~")
FRAG = os.path.join(HOME, ".config", "Code", "User", "matugen-colors.json")
SETTINGS = os.path.join(HOME, ".config", "Code", "User", "settings.json")


def main() -> int:
    if not os.path.isfile(FRAG):
        return 0
    try:
        with open(FRAG) as fh:
            fragment = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return 1

    if not os.path.isfile(SETTINGS):
        os.makedirs(os.path.dirname(SETTINGS), exist_ok=True)
        current = {}
    else:
        try:
            with open(SETTINGS) as fh:
                current = json.load(fh)
        except json.JSONDecodeError:
            current = {}

    current.update(fragment)
    with open(SETTINGS, "w") as fh:
        json.dump(current, fh, indent=4)
        fh.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())