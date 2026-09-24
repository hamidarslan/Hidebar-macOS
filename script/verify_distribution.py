#!/usr/bin/env python3
"""Reject local build paths in distributable bundle files without logging values."""
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
if not root.is_dir():
    raise SystemExit("Expected an app bundle directory")
pattern = re.compile(rb"/(?:Users|home)/[^/\x00\s]+/|/(?:private/)?var/folders/")
failures = []
for path in root.rglob("*"):
    if path.is_file() and not path.is_symlink() and pattern.search(path.read_bytes()):
        failures.append(str(path.relative_to(root)))
if failures:
    raise SystemExit("Local build paths found in: " + ", ".join(failures))
print("Distribution privacy check passed: no local build paths found.")
