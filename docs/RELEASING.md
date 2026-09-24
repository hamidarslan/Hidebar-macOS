# Versioning and releases

`main` is the ongoing development branch. `VERSION` is the app's semantic version. Tags named `vMAJOR.MINOR.PATCH` identify immutable baselines, beginning here with `v1.3.0`.

- **PATCH:** compatible bug fixes.
- **MINOR:** compatible features.
- **MAJOR:** incompatible changes to supported behavior or migration requirements.

The initial 1.0.0 label identifies the first development baseline; it does not certify complete platform validation or public-distribution readiness.

## Cut a version

1. Review the target commit and complete relevant checks in [TESTING.md](TESTING.md).
2. Update `VERSION`; move `Unreleased` entries to a dated changelog section. For distribution, also increment `CFBundleVersion` in the bundle-generation script.
3. Commit and merge the version changes into `main`.
4. Create an annotated tag on that commit and push it without rewriting prior tags:

   ```sh
   git tag -a "v$(cat VERSION)" -m "Hidebar $(cat VERSION)"
   git push origin "v$(cat VERSION)"
   ```

5. Run `./script/package.sh`. It builds the release configuration for arm64 and x86_64, verifies the bundle, and writes a universal DMG, ZIP, and SHA-256 checksum file in `dist/`.
6. If publishing a GitHub Release, attach those files and state the OS/architecture tested, validation gaps, and signing status.

From version 1.1.0, release packages use SwiftPM's optimized release configuration and contain both Apple Silicon and Intel slices. Ordinary `build_and_run.sh` development builds remain debug and use the host architecture unless `--release --universal` is supplied. The distributed app contains its resources and any required embedded Swift compatibility libraries; end users install no compiler or package manager.

Default packages are ad-hoc signed, not Developer ID signed or notarized. From 1.2.0, App Sandbox and Hardened Runtime are enabled and validated. The development Mac has no valid code-signing identity. Store credentials in Keychain, never in Git. Do not disable Gatekeeper as part of packaging.

### Notarized distribution

On a release Mac with Gatekeeper enabled, install your Developer ID Application certificate and private key in Keychain, and configure a `notarytool` Keychain profile using Apple's credential-storage instructions. Then set `SIGNING_IDENTITY` to the exact installed Developer ID Application identity and `NOTARY_PROFILE` to the existing Keychain profile name, and run:

```sh
./script/package.sh --notarize
```

The script requires both variables, checks that the identity is available, and refuses to run the distribution path with Gatekeeper disabled. It signs nested libraries and the app, submits the app for notarization, requires Accepted status, staples and validates the app, builds the final ZIP and DMG, signs/notarizes/staples the DMG, assesses both with Gatekeeper, and creates checksums only after completion. Failed/rejected submissions stop packaging. The script does not upload anything to GitHub. Validate a quarantined browser download on a second protected Mac before promoting a stable release.

The credentialed path is implemented but has not been run without a Developer ID identity. Never describe a default CI artifact or development preview as notarized. CI does not have signing credentials. An Apple privacy manifest is a declaration, not legal certification or App Store approval.

Use `./script/verify_bundle.sh dist/Hidebar.app 1` to verify signatures, resources, both architectures, and the absence of unbundled runtime library dependencies. Validate the DMG with `hdiutil verify`, mount it read-only, check the app and Applications link, then test the extracted app from a path outside the checkout.

## Return to a baseline

Inspect an older version without altering main history:

```sh
git switch --detach v1.3.0
./script/build_and_run.sh
```

Use `git switch main` to return. Save or commit your working changes before switching versions. Prefer a reviewed `git revert` for shared-history rollbacks.

Maintainers can publish using an authenticated GitHub CLI or Git client. Keep credentials outside the repository.
