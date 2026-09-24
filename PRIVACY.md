# Hidebar privacy policy

Effective 17 September 2026 · Applies to Hidebar 1.3.0

Hidebar is maintained by Arslan Hamid. It arranges menu bar space on your Mac. It has no account, advertisements, analytics, crash-upload service, cloud sync, or automatic updater. The app does not send data to the developer or any other recipient.

## What stays on your Mac

- Preferences: auto-hide on/off, delay, start-hidden choice, control style, shortcut key code/modifiers/display label, whether the shortcut is enabled, and whether setup is complete. macOS also saves the positions of Hidebar's own menu bar items.
- Display dimensions and a display identifier are used in memory to adjust menu bar spacing. They are not logged, stored by Hidebar, or transmitted.
- The current pointer location and whether a mouse button is down are checked when the auto-hide timer fires. They are used in memory to avoid hiding icons while you interact with the menu bar. There is no movement history or general keyboard recording. Only the registered shortcut triggers the toggle action. The shortcut recorder receives a modified key only while that control is focused inside Hidebar. It does not install a global keyboard monitor. The number of shortcut activations is kept in memory for troubleshooting, without a key history or timestamps.
- Launch at login is off by default. If you enable it, macOS manages the registration through ServiceManagement. You can disable it in Hidebar or System Settings.

Hidebar does not read the contents of other apps, inspect their documents, inventory their icons, capture the screen, read the clipboard, or request Accessibility, Screen Recording, Input Monitoring, camera, microphone, contacts, or location permission. It changes the space occupied by its own status items; macOS handles the arrangement of surrounding icons.

Temporary pauses and setup demonstration state remain in memory and are cleared when the app quits. Timed pauses use an expiry date to recover after sleep.

The Troubleshooting panel generates a small local summary containing app/macOS version, CPU architecture, display count, auto-hide/pause state, shortcut registration and activation count, and login-item status. It excludes usernames, file paths, display identifiers, configured shortcut contents, and other apps. It writes this visible report to the system clipboard only when you click Copy report. It never uploads it. Clipboard managers or Universal Clipboard may retain or synchronize copied text under your own system settings.

## Technical boundaries

The app uses App Sandbox with no network client/server, user-file access, app group, Apple Events, or temporary-exception entitlements. Hardened Runtime is enabled. Sandboxing restricts access; it is not a guarantee against every vulnerability. macOS still permits system resources and the app's own container. The bundled privacy manifest declares no tracking or collected data and declares app-only preferences access using Apple's CA92.1 reason.

## Retention, reset, and removal

Preferences remain locally until reset or removed. In Settings → Privacy & local data, “Reset preferences” restores the app's options and removes a login registration if macOS reports one. If macOS refuses removal of a known registration, reset stops and reports the error. If macOS cannot find the service, local preferences can still be reset, but the app asks you to check Login Items in System Settings; it does not claim login registration was removed. This control does not erase macOS logs or menu bar position records.

To uninstall, disable launch at login, quit Hidebar, and move the app to Trash. macOS may retain the app container at `~/Library/Containers/local.hidebar.app`, system-managed preferences, crash reports, and backups. Remove only Hidebar's own container after quitting if you also want its stored preferences removed. Copies from before 1.2.0 may have left `~/Library/Preferences/local.hidebar.app.plist`; these older preferences are not deliberately imported by the app. Backups follow your backup provider's retention settings.

## Downloads and support

GitHub hosts the source, downloads, and issue tracker. Visiting GitHub is separate from running Hidebar and is subject to GitHub's privacy policy. Information you choose to submit in an issue is handled by GitHub and the repository maintainers; never include credentials, sensitive screenshots, or personal files. macOS may independently generate diagnostics under your system settings. Hidebar does not upload those diagnostics.

For privacy questions, contact the repository owner (`hamidarslan`) through an existing private channel or the repository's issue tracker for non-sensitive questions. Do not submit sensitive details in public issues. The developer cannot retrieve or erase preferences on your Mac remotely because they are not received by the developer.

## Changes

Any future networking, telemetry, data sharing, SDK, or new permission requires a fresh privacy review and an updated policy and manifest before release. This policy is bundled in the app and can be read offline.
