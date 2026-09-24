#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
SOURCE="${1:-dist/Hidebar.app}"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
APP="$STAGE/Hidebar.app"
ditto "$SOURCE" "$APP"
./script/verify_bundle.sh "$APP" 1
expect_rejected() {
    if ./script/verify_bundle.sh "$APP" 1 > "$STAGE/result.txt" 2>&1; then
        echo "FAIL: weakened bundle accepted: $1" >&2; exit 1
    fi
    grep -F "$2" "$STAGE/result.txt" >/dev/null || { cat "$STAGE/result.txt"; exit 1; }
    echo "PASS: rejected $1"
}
cp Config/Hidebar.entitlements "$STAGE/expanded.plist"
/usr/libexec/PlistBuddy -c 'Add :com.apple.security.network.client bool true' "$STAGE/expanded.plist"
codesign --force --sign - --options runtime --entitlements "$STAGE/expanded.plist" "$APP"
expect_rejected "network entitlement" "must have only the sandbox entitlement"
codesign --force --sign - --options runtime --entitlements Config/Hidebar.entitlements "$APP"
plutil -replace NSPrivacyTracking -bool YES "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options runtime --entitlements Config/Hidebar.entitlements "$APP"
expect_rejected "tracking manifest" "tracking must be disabled"
cp Config/PrivacyInfo.xcprivacy "$APP/Contents/Resources/PrivacyInfo.xcprivacy"
codesign --force --sign - --options 0 --entitlements Config/Hidebar.entitlements "$APP"
expect_rejected "missing Hardened Runtime" "Hardened Runtime missing"
