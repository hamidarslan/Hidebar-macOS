# Third-party references and dependencies

There are no external Swift package dependencies. Hidebar uses Apple's AppKit, SwiftUI, ServiceManagement, Carbon, and system SF Symbols. Apple's `swift-stdlib-tool` bundles runtime compatibility libraries if needed by the compiled executable.

The apple artwork was supplied by the project owner as `icons.png`. `Assets/AppIcon.png` preserves that artwork with its outside white region removed and its boundary unmatted. `script/make_icon.swift` converts the cleaned image into macOS icon sizes; `script/clean_icon.py` is an optional Pillow-based maintenance tool, not an app dependency. The generated image-editor alternative was not used. `Assets/MenuBar.svg` is an original illustrative diagram.

Implementation references consulted:

- [Apple NSStatusItem.length documentation](https://developer.apple.com/documentation/appkit/nsstatusitem/length)
- [Hidden Bar architecture](https://github.com/dwarvesf/hidden/blob/develop/docs/ARCHITECTURE.md)
- [MenubarHide macOS 27 behavior notes](https://github.com/junior-rj/menubar-hide#macos-27) and status-controller source, used to understand spacer registration and OS behavior.

Hidebar's source was authored for this project. The public projects above are references, not vendored dependencies. This app is independent and is not affiliated with those projects or Apple. If third-party code/assets are added later, preserve their licenses and attribution here.

GitHub Actions used by CI (`actions/checkout` and `actions/upload-artifact`) execute in GitHub's runner environment; they are not bundled into the app. Each retains its upstream license.
