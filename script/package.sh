#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
NOTARIZE=0
case "${1:-}" in
    "") ;;
    --notarize) NOTARIZE=1 ;;
    *) echo "Usage: $0 [--notarize]" >&2; exit 2 ;;
esac
if [[ "$NOTARIZE" == 1 ]]; then
    [[ "${SIGNING_IDENTITY:-}" == "Developer ID Application:"* ]] || { echo "Set SIGNING_IDENTITY to your installed Developer ID Application identity." >&2; exit 1; }
    [[ -n "${NOTARY_PROFILE:-}" ]] || { echo "Set NOTARY_PROFILE to an existing notarytool keychain profile. Do not put credentials in this repository." >&2; exit 1; }
    security find-identity -p codesigning -v | grep -F -- "$SIGNING_IDENTITY" >/dev/null || { echo "Signing identity not available." >&2; exit 1; }
    [[ "$(spctl --status)" == "assessments enabled" ]] || { echo "Validate on a Mac with Gatekeeper enabled. This script does not change system security settings." >&2; exit 1; }
fi
notarize_file() {
    local FILE="$1"
    local RESULT
    RESULT="$(mktemp)"
    if ! xcrun notarytool submit "$FILE" --keychain-profile "$NOTARY_PROFILE" --wait --output-format json > "$RESULT"; then
        cat "$RESULT" >&2; rm -f "$RESULT"; return 1
    fi
    if [[ "$(plutil -extract status raw -o - "$RESULT")" != Accepted ]]; then
        cat "$RESULT" >&2; rm -f "$RESULT"; return 1
    fi
    cat "$RESULT"
    rm -f "$RESULT"
}
./script/build_and_run.sh --build-only --release --universal
APP_VERSION="$(tr -d '\r\n' < VERSION)"
NAME="Hidebar-${APP_VERSION}-macOS-universal"
if [[ "$NOTARIZE" == 1 ]]; then
    ditto --norsrc --noextattr -c -k --keepParent dist/Hidebar.app .build/notarization-upload.zip
    notarize_file .build/notarization-upload.zip
    xcrun stapler staple dist/Hidebar.app
    xcrun stapler validate dist/Hidebar.app
    ./script/verify_bundle.sh dist/Hidebar.app 1
    spctl --assess --type execute --verbose=4 dist/Hidebar.app
fi
ditto --norsrc --noextattr -c -k --keepParent dist/Hidebar.app "dist/$NAME.zip"
STAGE=".build/dmg-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
ditto --norsrc --noextattr dist/Hidebar.app "$STAGE/Hidebar.app"
ln -s /Applications "$STAGE/Applications"
cp LICENSE "$STAGE/License.txt"
cp PRIVACY.md "$STAGE/Privacy.md"
cat > "$STAGE/Read Me.txt" <<'TXT'
HIDEBAR — A little less clutter.

1. Drag Hidebar.app to Applications.
2. Eject this disk image and open Hidebar from Applications.
3. Hold Command and drag unwanted menu bar icons to the left of the divider.

Requires macOS 14 or newer. Works without Xcode, Swift, Homebrew, Python,
Rosetta on Apple Silicon, an account, or an internet connection.

Help and source: https://github.com/hamidarslan/Hidebar-macOS
TXT
if [[ "$NOTARIZE" == 1 ]]; then
    printf '\nThe enclosed app is Developer ID signed and notarized by Apple.\n' >> "$STAGE/Read Me.txt"
else
    printf '\nDevelopment preview: not notarized by Apple. macOS may block launch.\nNo system security settings are changed by Hidebar.\n' >> "$STAGE/Read Me.txt"
fi
hdiutil create -volname Hidebar -srcfolder "$STAGE" -ov -format UDZO "dist/$NAME.dmg"
if [[ "$NOTARIZE" == 1 ]]; then
    codesign --force --sign "$SIGNING_IDENTITY" --timestamp "dist/$NAME.dmg"
    notarize_file "dist/$NAME.dmg"
    xcrun stapler staple "dist/$NAME.dmg"
    xcrun stapler validate "dist/$NAME.dmg"
    spctl --assess --type open --context context:primary-signature --verbose=4 "dist/$NAME.dmg"
fi
(cd dist && shasum -a 256 "$NAME.zip" "$NAME.dmg" > "$NAME.sha256")
echo "Created dist/$NAME.dmg, .zip, and .sha256"
