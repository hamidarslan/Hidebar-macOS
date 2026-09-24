#!/usr/bin/env bash
set -euo pipefail
APP="${1:-dist/Hidebar.app}"
UNIVERSAL="${2:-0}"
BIN="$APP/Contents/MacOS/Hidebar"
codesign --verify --deep --strict "$APP"
plutil -lint "$APP/Contents/Info.plist"
test -s "$APP/Contents/Resources/Hidebar.icns"
test -s "$APP/Contents/Resources/AppIcon.png"
test -s "$APP/Contents/Resources/LICENSE"
ARCHS=()
if [[ "$UNIVERSAL" == 1 ]]; then
    lipo "$BIN" -verify_arch arm64
    lipo "$BIN" -verify_arch x86_64
    ARCHS=(arm64 x86_64)
else
    ARCHS=("$(uname -m)")
fi
swift "$(dirname "$0")/verify_privacy.swift" "$APP" "${ARCHS[@]}"
for ARCH in "${ARCHS[@]}"; do
    DETAILS="$(codesign -dvv --arch "$ARCH" "$APP" 2>&1)"
    grep -Eq 'flags=0x[[:xdigit:]]+\([^)]*runtime' <<< "$DETAILS" || { echo "Hardened Runtime missing: $ARCH" >&2; exit 1; }
done
for MACHO in "$BIN" "$APP/Contents/Frameworks/"*.dylib; do
    [[ -f "$MACHO" ]] || continue
    while IFS= read -r DEP; do
        case "$DEP" in
            /System/Library/*|/usr/lib/*) ;;
            @rpath/*) test -f "$APP/Contents/Frameworks/${DEP#@rpath/}" || { echo "Unbundled dependency: $DEP" >&2; exit 1; } ;;
            @executable_path/../Frameworks/*) test -f "$APP/Contents/Frameworks/${DEP#@executable_path/../Frameworks/}" ;;
            @loader_path/*) test -f "$(dirname "$MACHO")/${DEP#@loader_path/}" ;;
            *) echo "Non-system dependency: $DEP" >&2; exit 1 ;;
        esac
    done < <(otool -L "$MACHO" | awk '/^\t/ {print $1}' | sort -u)
done
echo "Bundle verified: system or bundled dependencies only."
