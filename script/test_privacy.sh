#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT_DIR="$PWD"
PROBE="$ROOT_DIR/.build/privacy-probe/PrivacyProbe.app"
mkdir -p "$PROBE/Contents/MacOS"
swiftc Tests/PrivacyProbe.swift -o "$PROBE/Contents/MacOS/PrivacyProbe"
cat > "$PROBE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.hidebar.privacyprobe</string>
<key>CFBundleExecutable</key><string>PrivacyProbe</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
codesign --force --sign - --options runtime --entitlements Config/Hidebar.entitlements "$PROBE"
MARKER="$ROOT_DIR/.build/privacy-probe/denied-marker.txt"
printf 'Non-sensitive sandbox test marker\n' > "$MARKER"
"$PROBE/Contents/MacOS/PrivacyProbe" "$MARKER"
