#!/usr/bin/env python3
"""Build a local ad-hoc-signed preview; private pointers never enter a release."""
from pathlib import Path
import hashlib
import plistlib
import shutil
import subprocess

root = Path(__file__).resolve().parent.parent
binary_dir = Path(subprocess.check_output(["swift", "build", "--disable-keychain", "--show-bin-path"], cwd=root, text=True).strip())
app = root / "dist/preview/ShellX.app"
if app.exists():
    shutil.rmtree(app)
contents = app / "Contents"
for name in ("MacOS", "Resources"):
    (contents / name).mkdir(parents=True, exist_ok=True)
shutil.copy2(binary_dir / "ShellX", contents / "MacOS/ShellX")
for bundle in binary_dir.glob("ShellX_*.bundle"):
    shutil.copytree(bundle, contents / "Resources" / bundle.name)
trial = root / ".local/cursor-preview"
if (trial / "cursors.json").is_file():
    destination = contents / "Resources/CursorPreview"
    destination.mkdir()
    for name in ("cursors.json", "arrow.png", "pointer.png", "NOTICE.txt"):
        shutil.copy2(trial / name, destination / name)
icon = root / "Resources/AppIcon.icns"
icon_name = "AppIcon-" + hashlib.sha256(icon.read_bytes()).hexdigest()[:16] + ".icns"
shutil.copy2(icon, contents / "Resources" / icon_name)
shutil.copy2(root / "Resources/Assets.car", contents / "Resources/Assets.car")
info = {
    "CFBundleName": "ShellX", "CFBundleDisplayName": "ShellX",
    "CFBundleIdentifier": "cc.anjing.shellx.preview",
    "CFBundleExecutable": "ShellX", "CFBundlePackageType": "APPL",
    "CFBundleShortVersionString": "0.0.1", "CFBundleVersion": "1",
    "CFBundleIconFile": icon_name, "CFBundleIconName": "ShellX",
    "LSMinimumSystemVersion": "14.0", "NSHighResolutionCapable": True,
}
with (contents / "Info.plist").open("wb") as output:
    plistlib.dump(info, output)
subprocess.run(["codesign", "--force", "--sign", "-", "--timestamp=none", str(app)], check=True)
subprocess.run(["codesign", "--verify", "--strict", str(app)], check=True)
register = Path("/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister")
if register.exists():
    subprocess.run([str(register), "-f", str(app)], check=True)
print(app)
