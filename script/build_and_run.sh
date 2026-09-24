#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
MODE=run
CONFIGURATION=debug
UNIVERSAL=0
for ARG in "$@"; do
    case "$ARG" in
        run|--verify|--build-only|--debug|--logs) MODE="$ARG" ;;
        --release) CONFIGURATION=release ;;
        --universal) UNIVERSAL=1 ;;
        *) echo "Usage: $0 [run|--verify|--build-only|--debug|--logs] [--release] [--universal]" >&2; exit 2 ;;
    esac
done
APP_VERSION="$(tr -d '\r\n' < VERSION)"
SIGNING_IDENTITY="${SIGNING_IDENTITY:--}"
SIGN_ARGS=(--force --sign "$SIGNING_IDENTITY" --options runtime)
if [[ "$SIGNING_IDENTITY" != - ]]; then SIGN_ARGS+=(--timestamp); fi
[[ "$APP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid VERSION" >&2; exit 2; }
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/ModuleCache"
BUILD_ARGS=(--scratch-path "$ROOT_DIR/.build" --configuration "$CONFIGURATION")
if [[ "$UNIVERSAL" == 1 ]]; then BUILD_ARGS+=(--arch arm64 --arch x86_64); fi
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"
STAGE="$ROOT_DIR/.build/bundle/Hidebar.app"
APP="$ROOT_DIR/dist/Hidebar.app"
rm -rf "$STAGE"
mkdir -p "$STAGE/Contents/MacOS" "$STAGE/Contents/Resources" "$STAGE/Contents/Frameworks"
cp "$BIN_DIR/Hidebar" "$STAGE/Contents/MacOS/Hidebar"
swift script/make_icon.swift Assets/AppIcon.png "$ROOT_DIR/.build/Hidebar.iconset"
iconutil -c icns "$ROOT_DIR/.build/Hidebar.iconset" -o "$STAGE/Contents/Resources/Hidebar.icns"
cp Assets/AppIcon.png LICENSE "$STAGE/Contents/Resources/"
cp PRIVACY.md Config/PrivacyInfo.xcprivacy "$STAGE/Contents/Resources/"
cat > "$STAGE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Hidebar</string>
<key>CFBundleIdentifier</key><string>local.hidebar.app</string>
<key>CFBundleName</key><string>Hidebar</string>
<key>CFBundleDisplayName</key><string>Hidebar</string>
<key>CFBundleIconFile</key><string>Hidebar</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.0</string>
<key>CFBundleVersion</key><string>4</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Arslan Hamid. MIT License.</string>
</dict></plist>
PLIST
plutil -replace CFBundleShortVersionString -string "$APP_VERSION" "$STAGE/Contents/Info.plist"
xcrun swift-stdlib-tool --copy --scan-executable "$STAGE/Contents/MacOS/Hidebar" \
    --platform macosx --destination "$STAGE/Contents/Frameworks" --sign "$SIGNING_IDENTITY"
for LIB in "$STAGE/Contents/Frameworks/"*.dylib; do
    [[ -f "$LIB" ]] || continue
    codesign "${SIGN_ARGS[@]}" "$LIB"
done
codesign "${SIGN_ARGS[@]}" --entitlements Config/Hidebar.entitlements "$STAGE"
./script/verify_bundle.sh "$STAGE" "$UNIVERSAL"
if [[ "$MODE" != "--build-only" ]] && pgrep -x Hidebar >/dev/null; then pkill -x Hidebar; sleep 1; fi
mkdir -p "$ROOT_DIR/dist"
rm -rf "$APP"
ditto "$STAGE" "$APP"
case "$MODE" in
    --build-only) echo "Built $APP ($CONFIGURATION)" ;;
    --debug) lldb -- "$APP/Contents/MacOS/Hidebar" ;;
    --logs) open "$APP"; /usr/bin/log stream --level info --predicate 'process == "Hidebar"' ;;
    --verify) open "$APP"; sleep 2; pgrep -x Hidebar ;;
    run) open "$APP" ;;
esac
