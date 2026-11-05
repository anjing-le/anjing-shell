#!/usr/bin/env python3
"""Compile native Icon Composer artwork and a multi-resolution ICNS fallback."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent
subprocess.run(["swift", str(root / "scripts/prepare-icon.swift"), str(root)], check=True)
source = root / "Resources/AppIcon.png"
document = root / "Resources/ShellX.icon"
developer = Path(os.environ.get("SHELL_X_ICON_DEVELOPER_DIR", "/Applications/Xcode.app/Contents/Developer"))
composer = developer.parent / "Applications/Icon Composer.app/Contents/Executables/ictool"
compiler = developer / "usr/bin/actool"
if not composer.exists() or not compiler.exists():
    raise SystemExit("Icon compilation requires Xcode 27+; set SHELL_X_ICON_DEVELOPER_DIR to its Contents/Developer path.")
subprocess.run([str(composer), str(document), "--export-image", "--output-file", str(source),
                "--platform", "macOS", "--rendition", "Default", "--width", "1024", "--height", "1024",
                "--scale", "1", "--design-generation", "27"], check=True)
with tempfile.TemporaryDirectory(prefix="shellx-icon-") as directory:
    subprocess.run([str(compiler), str(document), "--compile", directory, "--platform", "macosx",
                    "--minimum-deployment-target", "14.0", "--target-device", "mac", "--app-icon", "ShellX",
                    "--output-partial-info-plist", str(Path(directory) / "icon-info.plist")], check=True, stdout=subprocess.DEVNULL)
    shutil.copy2(Path(directory) / "Assets.car", root / "Resources/Assets.car")
    iconset = Path(directory) / "AppIcon.iconset"
    iconset.mkdir()
    for points in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            pixels = points * scale
            suffix = "@2x" if scale == 2 else ""
            subprocess.run(["sips", "-z", str(pixels), str(pixels), str(source), "--out",
                            str(iconset / f"icon_{points}x{points}{suffix}.png")],
                           check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(root / "Resources/AppIcon.icns")], check=True)
print("Compiled native Resources/Assets.car and ICNS fallback from Resources/ShellX.icon")
