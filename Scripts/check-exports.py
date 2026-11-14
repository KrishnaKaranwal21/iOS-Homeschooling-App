#!/usr/bin/env python3
"""Catch stale source inside the distributable ZIP snapshots."""
from pathlib import Path
import hashlib
import zipfile

root = Path(__file__).resolve().parent.parent
errors = []
checked = 0
for archive in sorted((root / "Exports").glob("*.zip")):
    with zipfile.ZipFile(archive) as bundle:
        names = bundle.namelist()
        for name in names:
            for marker in ("Homeschool/", "Homeschool.xcodeproj/", "Scripts/", "Tests/", "DesignNotes/"):
                if "/" + marker in name:
                    relative = marker + name.split("/" + marker, 1)[1]
                    path = root / relative
                    if not name.endswith("/"):
                        checked += 1
                        if not path.is_file() or bundle.read(name) != path.read_bytes():
                            errors.append(f"{archive.name}: stale or missing {relative}")
                    break
        for name in names:
            if name.endswith("/SHA256SUMS.txt"):
                prefix = name.removesuffix("SHA256SUMS.txt")
                for line in bundle.read(name).decode().splitlines():
                    digest, relative = line.split("  ", 1)
                    if hashlib.sha256(bundle.read(prefix + relative)).hexdigest() != digest:
                        errors.append(f"{archive.name}: invalid checksum for {relative}")
        if archive.name in ("HomeSchool-App.zip", "Progress-Section.zip"):
            progress = [name for name in names if name.endswith("/ProgressDashboardView.swift")]
            if len(progress) != 1 or b'Picker("Progress range"' not in bundle.read(progress[0]):
                errors.append(f"{archive.name}: missing current Progress range picker")

if errors:
    raise SystemExit("\n".join(errors))
print(f"All {checked} archived source files match the checkout; checksums verified.")
