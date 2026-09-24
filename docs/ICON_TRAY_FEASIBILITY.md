# Searchable icon tray: feasibility decision

Reviewed for 1.3.0 on 2026-09-17. **Not shipped.**

The current implementation owns only Hidebar's divider, spacer, and toggle items. It does not know which third-party icons are left of the divider, their names, images, or actions. The macOS 27 SDK's public `NSStatusBar` header exposes creation/removal of owned status items, thickness, and orientation; it does not expose an inventory of other apps' items. A list of running apps would not be a truthful list of hidden icons.

A tray capable of searching and activating other apps' menu items would require a separate investigation of cross-process accessibility access and potentially image capture. Those approaches are outside the current sandbox's sole entitlement and its no-Accessibility/no-Screen-Recording policy. Private APIs, fabricated app-to-icon mappings, and silently added permissions are excluded.

Decision: keep the existing permission boundary and ship the other usability improvements. No imitation tray or extra permission request is included. A future prototype must be isolated from the shipping app and explicitly scoped with the owner before adding access.

## Acceptance criteria for a future prototype

1. Establish a documented public API path and the exact required permissions; verify sandbox and distribution compatibility.
2. Identify actual status items, including multiple items per process, without scanning unrelated window contents.
3. Correctly identify the hidden group, names, images, and activation targets across notches, displays, and OS versions.
4. Demonstrate useful keyboard search and activation with a clear denied/revoked-permission fallback.
5. Keep all processing local, capture no unrelated screen content, persist no icon history, and update the policy and security tests.
6. Do not weaken the existing app or add permissions until the prototype is reviewed and approved.

Reference: [Apple NSStatusBar](https://developer.apple.com/documentation/appkit/nsstatusbar). SDK inspection is evidence about this public interface, not proof that every possible future design is impossible.
