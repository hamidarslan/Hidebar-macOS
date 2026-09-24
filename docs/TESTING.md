# Testing and validation

## Automated

```sh
./script/test.sh
./script/test_privacy.sh
./script/package.sh
./script/test_bundle_security.sh
./script/verify_bundle.sh dist/Hidebar.app 1
hdiutil verify dist/Hidebar-1.3.0-macOS-universal.dmg
```

The test script supplies the Swift Testing macro plugin explicitly when found in the selected Command Line Tools installation. This works around the Swift 6.4 toolchain observed during development.

Seven tests cover the four geometry cases (legacy bounds, modern multi-display bounds, notch width, invalid dimensions), timed pause expiry including a simulated sleep gap, indefinite pause/resume, and invalid shortcut preferences. These tests verify state and calculations, not OS-level icon placement or physical input delivery.

The GitHub Actions workflow builds and tests on a hosted Mac and uploads locally signed universal DMG/ZIP packages as temporary workflow artifacts. Bundle checks inspect both CPU slices and reject non-system library dependencies that are not embedded. The workflow's existence does not establish a passing run; inspect each commit's Checks tab.

## Manual acceptance checks

- First launch: all setup content and footer controls fit or scroll without clipping.
- Hold Command and move a real app icon left of the divider; keep the arrow right of it.
- Use a physical click to hide, then reveal. Confirm the chosen icon's behavior and that the arrow remains reachable.
- Right-click the arrow; exercise settings and Show all recovery.
- Press Control–Option–H while another app is active; verify toggling and handle shortcut conflicts.
- Enable each auto-hide delay, move the pointer away, and confirm timing. Keep the pointer near the bar and confirm deferral.
- Close and reopen Hidebar; verify saved settings and recovery.
- Quit while collapsed and confirm available menu bar space returns.
- Test display attach/detach, different scaling, notched displays, sleep/wake, and multiple displays.
- Move the app to Applications, enable launch at login, and complete a real logout/login cycle.
- Test both minimum-supported and current macOS versions before claiming compatibility across them.
- Extract the release ZIP outside the source checkout, validate and launch that copy with a minimal PATH.
- Verify the DMG's app and Applications link, transparent icon corners, and downloaded-file checksums.
- Open Privacy & local data without internet access; verify the full bundled policy is readable.
- Cancel Reset preferences and confirm nothing changes; confirm reset and verify options return to defaults, icons reveal, and launch at login is off.
- Test sandboxed hotkey registration and a real login cycle on both supported CPU architectures.
- Validate a downloaded, quarantined copy on a second Mac with Gatekeeper enabled. The development host's assessment reported `override=security disabled`; launch there does not establish distribution trust. No build script changes this setting.

## Baseline evidence — 2026-09-17

Local host: Apple Silicon, macOS 27, Swift 6.4 Command Line Tools.

Passed: build and process launch; four automated tests; app signature/Info.plist checks; visual setup inspection; accessibility-invoked menu bar hide/reveal with a changed/restored item set.

Unverified: physical pointer interaction (automation reported off-screen right-click targets), global shortcut activation (registration succeeded), login cycle, older macOS releases, Intel, and multiple displays. Do not promote these to passed without new evidence.

## Version 1.1.0 packaging evidence — 2026-09-17

- Optimized arm64/x86_64 universal binary; both Mach-O slices declare macOS 14.0 minimum.
- Signature, Info.plist, PNG/ICNS resources, and linked-library checks passed. No non-system unbundled runtime dependencies were found.
- DMG checksum verification passed. Read-only mounting confirmed the complete app and the Applications symlink.
- The ZIP was extracted to a temporary folder outside the checkout, revalidated, and launched with a system-only PATH. The running executable path was the extracted copy.
- Four geometry tests passed again.
- Icon alpha and every generated icon size were checked. The central 740 × 740 pixel RGB region matches the supplied artwork byte-for-byte; light/dark-background inspection confirmed the exterior white was removed.

These are packaging and launch checks on the development Mac, not a fresh-machine or notarization test. Existing manual platform/interaction gaps above remain open.

## Version 1.2.0 privacy evidence — 2026-09-17

- Optimized universal build passed. Both signed slices have exactly the App Sandbox entitlement and Hardened Runtime, with no network/file/debug/exception grants.
- The bundled no-tracking manifest, app-only UserDefaults reason, and offline policy passed validation.
- A separate sandboxed test app using the same entitlement file was denied reading/writing an outside-container test marker, connecting to loopback, and binding a listening socket. App-local preference roundtrip passed.
- Deliberately weakened bundle copies were rejected for added network-client entitlement, enabled tracking, and disabled Hardened Runtime. These copies were temporary and were not released.
- The real sandboxed app launched. The offline policy and reset confirmation/cancellation were inspected through the UI.
- An isolated UI test copy with its own bundle identifier was used for confirmed reset, preserving the user's actual preferences. Modified auto-hide, start-hidden, and control style returned to their defaults. When ServiceManagement could not find this development copy's login service, the app correctly reported that status rather than claiming registration was removed. Settings-button hide/reveal state transitions passed.
- A simulated Control–Option–H did not change the UI in this automation environment, despite successful hotkey registration. Physical shortcut testing remains unresolved; do not label it passed.
- Default notarization invocation without a signing identity stopped before building or submitting anything. The full credentialed notarization path remains untested: no valid signing identities are installed.

The runtime probe exercises the OS sandbox policy, not every possible app behavior. Known-login deregistration, a real logout/login cycle, protected/quarantined downloads, Intel hardware, and older macOS versions remain acceptance gates. No completed independent security audit is claimed.


## Version 1.3.0 usability evidence — 2026-09-17

- Optimized universal build and seven core tests passed locally. The privacy probe and checks rejecting weakened bundles remain part of release validation.
- In an isolated app identity, all five setup steps were exercised, including explicit hide/reveal trials. The system dark appearance was visually inspected.
- Recorded Control–Option–J; restored the default; rejected plain-letter input; cancelled recording with Escape.
- A separate process exclusively reserved Control–Option–K. Recording that combination returned -9878 and preserved Hidebar's existing Control–Option–H registration. A non-exclusive registration did not produce a rejection on this host; conflict detection is not exhaustive for every system/app-local shortcut. The temporary reservation process exited.
- Five-minute pause, resume, and indefinite pause UI states passed, with auto-hide remaining enabled at its original delay. Closing/reopening settings preserved the indefinite pause. Timed expiry after a sleep-like time gap is covered by the pure state test; a physical sleep cycle is still pending.
- The diagnostics panel showed only the intended summary fields and no configured shortcut contents, usernames, paths, identifiers, or app lists. Clipboard copy is explicit; no network/upload path was added.
- Global hotkey automation did not produce a callback. The user also confirmed that physical Control–Option–H did nothing in the initial v1.3.0 candidate. This failure was resolved by the routing change below.
- A revised candidate receives Carbon events on the application target while registering the hotkey on the dispatcher target. It builds and passes bundle security validation. The user confirmed that physical Control–Option–H hides/reveals icons with Finder focused on this development Mac. The temporary non-exclusive-registration experiment was reverted. No new permissions or entitlements were added.

Still pending: full login cycle, multiple displays, minimum macOS/Intel hardware, light/Increase Contrast/Reduce Motion system-setting checks, and the protected-download/notarization gates already documented. The new right-click menu compiles but full physical-pointer acceptance remains pending. The searchable icon tray is not implemented; see ICON_TRAY_FEASIBILITY.md.
