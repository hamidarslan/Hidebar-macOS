# Architecture

Hidebar is a single-process, menu-bar-only macOS application. It has no server, network client, telemetry, external package dependencies, or background helper.

## Components

| Component | Responsibility |
| --- | --- |
| `Sources/Hidebar/App.swift` | Application lifecycle, single-instance check, setup window, reopening recovery |
| `Sources/Hidebar/BarController.swift` | Status items, hide/reveal state, timers, Carbon hotkey registration, ServiceManagement login registration |
| `Sources/Hidebar/SettingsView.swift` | Setup instructions, illustrative preview, settings bindings |
| `Sources/Hidebar/PrivacyView.swift` | Offline policy and confirmed preference reset |
| `Sources/Hidebar/ShortcutRecorder.swift` | Focused AppKit key recorder; no global event monitor |
| `Sources/Hidebar/SetupGuideView.swift` | Illustrated setup and explicit hide/reveal trials |
| `Sources/Hidebar/DiagnosticsView.swift` | User-reviewed local diagnostic report and explicit clipboard copy |
| `Sources/HidebarCore/InteractionState.swift` | Pause expiry and shortcut validation |
| `Sources/HidebarCore/SpacerLayout.swift` | Pure display-width-to-spacer-length calculation |
| `Tests/HidebarCoreTests` | Geometry regression checks |
| `Assets/` | Cleaned owner-supplied icon and README illustration |
| `script/` | Build/bundle, icon conversion, tests, dependency validation, and DMG/ZIP packaging |

## Menu bar mechanism

The user arranges icons with macOS Command-drag. Expanding a status-item divider displaces icons to its left; shrinking it reveals available space. Hidebar does not enumerate, launch, terminate, or move other apps programmatically.

Legacy systems use a large bounded divider. macOS 27 uses smaller segments because oversized individual status items can be discarded. A single display uses one segment; multiple displays may use up to seven. Additional spacer slots register between the chevron and divider and become invisible when unused. macOS decides which displaced items enter native overflow.

## State and lifecycle

`hidden` is session state. Settings are stored using UserDefaults in the app's `local.hidebar.app` domain, sandboxed from 1.2.0 onward. Keys include `autoHide`, `delay`, `startHidden`, `symbol`, and `didOnboard`; AppKit also stores its own status-item placement metadata. The bundle ID is stable, but enabling sandboxing changes the storage location; older settings may need to be configured again. No explicit migration reads are granted outside the container.

Opening settings reveals icons and pauses auto-hide while arranging. Closing settings resumes configured timing. Auto-hide waits while the pointer is near the menu bar, a mouse button is held, or Hidebar's menu is open. Start-hidden waits 15 seconds. Real display configuration changes and wake reveal icons; identical display notifications do not undo a hide action. Termination unregisters the shortcut and removes status items.

## Platform boundaries

Temporary pause state is in-memory and independent of the saved auto-hide preference. A one-shot timer and the wake path evaluate the expiry date. Resuming restores configured timing; explicitly hiding ends the pause. Closing setup via All set preserves an active pause. Quitting clears pauses.

Carbon requests exclusive registration for one selected shortcut with the event dispatcher and receives events on the application event target. This pairing delivered physical hotkeys on the macOS 27 development host. A replacement is registered before the previous registration is released, so a failed change keeps the existing shortcut. The recorder is a focused NSButton responder; Escape or focus loss cancels it. It does not install a global keyboard monitor. A matching hotkey event updates an in-memory activation count and the UI confirmation. The OS reports conflicts with existing exclusive registrations; unregistered app-local shortcuts and some system-reserved combinations cannot be exhaustively detected. Stored key codes represent physical keys; labels may need rerecording after a keyboard-layout change.

Diagnostics are created on demand from explicitly allowed app state. They contain no username, path, display identifier, shortcut contents, or other-process list. Copy is a user action; the report is not written to a file or uploaded.

The implementation cannot guarantee placement of system-owned/nonmovable icons, unlimited space on notched screens, or preservation of all arrangements across OS changes. Multi-display behavior is not yet manually validated. Keep the app-reopening recovery route functional when modifying layout behavior.

## Standalone distribution

`script/package.sh` builds an optimized universal executable with arm64 and x86_64 slices. A staged `.app` includes its executable, metadata, ICNS/PNG icon resources, MIT license, and any compatibility libraries discovered by Apple's `swift-stdlib-tool`. Bundle verification rejects non-system dependencies that are not embedded. ZIP and DMG distributions contain that same app. End users need only a compatible macOS version; the compiler, icon-conversion tools, and optional artwork cleanup script are build-time tools.

The app remains ad-hoc signed. No signing identity or notarization credentials are committed, and the packaging process does not alter Gatekeeper settings.

App Sandbox is the only entitlement. Network client/server, user-selected files, Apple Events, app groups, debug permissions, and temporary exceptions are absent. Hardened Runtime is enabled. Packaging validates each signed architecture against that exact entitlement allowlist. The sandbox probe is a separate test executable and never ships in the app. The app has no subprocess launcher or remote-content renderer. `PRIVACY.md` is bundled for offline reading and `PrivacyInfo.xcprivacy` declares only app-local preferences access.

## Future extension points

Before adding custom shortcuts, extra hidden groups, icon panels, or updates, define acceptance criteria and permission requirements in an issue. A panel that reproduces other apps' icons would be a materially different subsystem and must not be presented as an existing capability.
