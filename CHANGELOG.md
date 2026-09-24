# Changelog

Versions follow semantic versioning. Record unreleased changes here as they land.

## Unreleased

No changes recorded yet.

## 1.3.0 — 2026-09-17

- Corrected global shortcut delivery on macOS 27 by receiving events on the application target and registering through the dispatcher; verified with a physical keyboard.
- Added customizable keyboard shortcuts with focused recording, input validation, transactional replacement, unavailable/conflict feedback, and default/off controls.
- Added in-app confirmation when a real shortcut event arrives.
- Added 5-minute, 1-hour, and indefinite session pauses without overwriting auto-hide settings. Wake checks expiry; explicit hiding ends a pause.
- Added quick menu controls for pause/resume, delay, auto-hide, and troubleshooting.
- Added a five-step setup demonstration with real hide/reveal trials and Reduce Motion support.
- Replaced forced light appearance with system-adaptive colors and added explicit login-service state plus a Login Items shortcut.
- Added local diagnostic preview/copy excluding personal paths, identifiers, key contents, and app lists. Nothing is uploaded.
- Added tests for pause expiry and malformed shortcut settings; preserved sandbox and signing checks.
- Documented the searchable icon tray feasibility boundary. No third-party icon access or new entitlements were added.

## 1.2.0 — 2026-09-17

### Privacy and security

- Enabled App Sandbox with no extra permissions and Hardened Runtime for both CPU architectures.
- Bundled a privacy policy and Apple's privacy manifest with no tracking/data collection and app-only UserDefaults access (CA92.1).
- Added an offline Privacy & local data screen and a confirmed preference-reset action that removes known login registration and reports unavailable login status explicitly.
- Added signed-entitlement allowlist validation and runtime tests for blocked network and outside-container file access.
- Pinned CI actions to immutable commits; added privacy tests to CI.
- Added an opt-in Developer ID/notarization packaging path that stops on missing credentials, disabled Gatekeeper, or rejected submissions. Default previews remain ad-hoc signed.

Sandboxing changes preferences storage to the app container; older preferences may not carry over. This remains a development preview pending Apple credentials, notarization, independent audit, and the remaining platform acceptance checks.

## 1.1.0 — 2026-09-17

### Added

- User-supplied apple icon in the app bundle, settings, and README; original preserved and exterior white removed with real alpha transparency.
- Optimized universal release packaging for Apple Silicon and Intel.
- Drag-to-Applications DMG, standalone ZIP, and SHA-256 checksums.
- Bundle dependency validation and Swift compatibility-library embedding when required.
- Download-first README with setup illustration, controls, privacy, updating/removal, and a separate developer section.

### Changed

- Release packaging uses the release configuration; ordinary local development remains debug.
- Build resources are staged and verified before replacing the distributable app.
- Signing status and remaining platform validation gaps remain explicit. No notarization or Developer ID signature is claimed.

## 1.0.0 — 2026-09-17

Initial development baseline; not a notarized public distribution.

### Added

- Native SwiftUI setup/settings window and generated app icon.
- AppKit menu bar divider and show/hide control, with chevron or dots styling.
- Command-drag setup instructions and a preview of icon arrangement.
- Configurable auto-hide, launch-hidden preference, and launch-at-login control.
- Control–Option–H shortcut registration and availability reporting.
- Reveal/recovery through settings, app reopening, display changes, and wake.
- Bounded spacer geometry for legacy and macOS 27 menu bars.
- Reproducible build, test, and ZIP packaging scripts.
- Four automated geometry tests, CI definition, and contributor documentation.

### Validation and limitations

- Built/launched locally on Apple Silicon running macOS 27; four geometry tests passed.
- Setup layout inspected; accessibility-invoked menu bar toggle changed and restored the item set.
- Physical right-click, global shortcut activation, login cycle, and multiple displays remain manual validation tasks.
- Local ad-hoc signing only. No Developer ID signing, notarization, auto-update service, or universal binary claim.
