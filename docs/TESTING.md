# Testing and validation

## Automated checks

```sh
./script/test.sh
./script/test_privacy.sh
./script/package.sh
./script/test_bundle_security.sh
./script/verify_bundle.sh dist/Hidebar.app 1
python3 script/verify_distribution.py dist/Hidebar.app
hdiutil verify dist/Hidebar-1.3.2-macOS-universal.dmg
```

Seven core tests cover geometry bounds, invalid display dimensions, notch widths, timed and indefinite pauses, and shortcut validation. They do not establish correct OS-level icon placement or physical input delivery.

CI runs the core tests, sandbox probes, universal packaging, signature and entitlement checks, and rejection tests for weakened bundles. Inspect the exact commit's Checks tab for results. Release packaging removes debug information before signing and rejects bundles containing local home or temporary build paths. Error output names the affected bundle file without printing the matched path.

## Release validation

- Verify signatures, both CPU architectures, required resources, the privacy manifest, exact sandbox entitlements, and bundled/system-only dependencies.
- Confirm ZIP and DMG checksums, inspect a read-only mounted DMG, and recheck the extracted app outside the source checkout.
- Scan source, executable contents, archive metadata, and CI artifacts for accidental private data before publication.
- Release packages are ad-hoc signed previews. Successful local checks do not establish Apple notarization or protected-download acceptance.

## Manual acceptance matrix

- Arrange real menu bar icons with Command-drag and confirm the arrow stays reachable.
- Hide and reveal using physical clicks and the configured shortcut while another app is focused.
- Exercise right-click controls, pause/resume, every auto-hide delay, and pointer deferral.
- Reopen the app and verify preferences, recovery, and restoration of menu bar space on quit.
- Test setup steps, scrolling, light/dark appearance, Increase Contrast, and Reduce Motion.
- Test display attach/detach, scaling, notch layouts, multiple displays, and sleep/wake.
- Install in Applications, enable launch at login, and complete a logout/login cycle.
- Read the offline privacy policy, cancel a reset, then confirm reset using a separate test identity.
- Confirm diagnostics exclude personal content and clipboard writes occur only on request.
- Test minimum-supported macOS and Intel hardware as well as Apple Silicon.
- Validate a quarantined download on a normally protected Mac before claiming distribution trust.

## Existing behavior evidence

The v1.3.0 baseline passed seven core tests, universal packaging checks, sandbox probes, and targeted setup, shortcut-recording, pause/resume, and diagnostic UI checks. Physical Control–Option–H toggling was confirmed with Finder focused on Apple Silicon/macOS 27. These results do not substitute for testing every item above on each release.

Still unverified: a full login cycle, multiple displays, minimum-supported macOS/Intel hardware, complete physical right-click acceptance, accessibility appearance settings, and protected-download/notarization acceptance. No completed independent security audit is claimed.
