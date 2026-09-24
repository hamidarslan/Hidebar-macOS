# Security and privacy

Hidebar is local-only. It has no analytics, account system, network service, or external package dependencies. Preferences remain on the Mac. Current functionality does not require Accessibility or Screen Recording permission.

Login-item registration is opt-in and uses Apple's ServiceManagement. Disabling the setting unregisters it. The app's settings are separate from other applications' preferences.

Never commit GitHub tokens, signing certificates/private keys, Apple credentials, or personal diagnostic captures. The included CI workflow has read-only repository permissions and no signing secrets.

Report a suspected vulnerability using [GitHub private vulnerability reporting](https://github.com/hamidarslan/Hidebar-macOS/security/advisories/new). Do not include secrets or sensitive screenshots in a public issue. Private vulnerability reporting is enabled for this public repository.

There is no formal security audit or guaranteed support period. Security fixes should receive a changelog entry and a new version tag.

## Enforced boundaries (1.2.0)

- App Sandbox is enabled, with no additional entitlements: no network client/server, arbitrary user files, app groups, Apple Events, debug access, or sandbox exceptions.
- Hardened Runtime is enabled for every executable architecture; library-validation and executable-memory protections are not weakened by entitlements.
- Both signed CPU slices are checked against an exact entitlement allowlist at packaging time. The privacy manifest and bundled offline policy are checked too.
- A separate runtime probe verifies denied outbound/inbound networking and denied file access outside the app container; it also checks app-local preferences. The probe is never bundled with the app.
- CI actions are pinned to immutable commits, with read-only repository permissions and no persisted checkout credentials or signing secrets.
- There is no updater or plugin-loading interface. Install updates manually from the owner's repository; checksums confirm file consistency, not publisher identity.

The [privacy policy](PRIVACY.md) describes local preferences, transient pointer/display state, login registration, removal, support, and operating-system diagnostics. No assertion of perfect security, legal certification, or App Store approval is made.

Version 1.3.0 adds focused shortcut recording and user-initiated diagnostic clipboard writes. No global keyboard monitoring, arbitrary file access, network grants, or third-party icon inspection was added. Shortcut changes preserve the previous registration on failure, and diagnostics use an explicit allowlist of non-content state. The [icon-tray feasibility decision](docs/ICON_TRAY_FEASIBILITY.md) records the permission boundary.

## Distribution gate

The current preview is ad-hoc signed. A public trusted release requires an installed Developer ID Application identity, Hardened Runtime, accepted notarization, stapled tickets, and Gatekeeper validation on a normally protected Mac. `script/package.sh --notarize` fails if prerequisites are missing; it never disables Gatekeeper or clears quarantine. A successful local launch with Gatekeeper disabled is not a distribution security test.

An independent automated security audit has not been completed. Source inspection and the targeted tests are not a substitute for a completed independent audit. Before a stable release, complete the manual matrix in `docs/TESTING.md`, including sandboxed login-item registration and hotkey behavior.
