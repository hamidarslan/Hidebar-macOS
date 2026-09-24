# Ideas and backlog

Future features should start as GitHub issues with a problem statement, desired interaction, and acceptance checks. This list is a planning aid, not a promise that features already exist.

## Current priorities

### Added in 1.3.0

- Custom shortcut recording, registration failure feedback, disable/default controls, and an activation confirmation.
- Timed and indefinite session pauses that preserve auto-hide preferences, including expiry handling after wake.
- Quick menu delay, pause, resume, and troubleshooting controls.
- Five-step illustrated setup, including real hide/reveal trials; transition animation respects Reduce Motion.
- System light/dark appearance and native accessible controls.
- Local diagnostics with explicit review and clipboard copy; no uploads.

### Still requires real-device validation

- Complete physical pointer, shortcut, login-cycle, and multi-display validation.
- Test older supported macOS releases and Intel hardware.
- Investigate menu-bar placement behavior across macOS updates.
- Prepare Developer ID signing and notarization; universal DMG/ZIP packaging is available from 1.1.0.

## Future ideas

The searchable third-party icon tray was investigated and is not included: see [the feasibility decision](ICON_TRAY_FEASIBILITY.md). It needs a separate permission/API design and is incompatible with the current implementation's knowledge of owned items alone.

Use the feature-request template for new ideas. Keep proposed work separate from the completed baseline in `CHANGELOG.md`. Agree on scope before adding new permission requirements or changing the icon-management model.
