import AppKit
import SwiftUI

@main
struct HidebarApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var controller: BarController!
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A second launch is a recovery route even if the menu bar is crowded.
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: Bundle.main.bundleIdentifier ?? "local.hidebar.app")
        if let other = others.first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            other.activate(options: [.activateAllWindows])
            NSApp.terminate(nil)
            return
        }
        controller = BarController()
        controller.openSettings = { [weak self] in self?.showSettings() }
        if !UserDefaults.standard.bool(forKey: "didOnboard") {
            showSettings()
        } else if controller.startHidden {
            controller.scheduleStartupHide()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    func showSettings() {
        guard controller != nil else { return }
        controller.beginArranging()
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 780),
                                  styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                                  backing: .buffered, defer: false)
            window.title = "Hidebar"
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: SettingsView(model: controller, done: { [weak self] in
                UserDefaults.standard.set(true, forKey: "didOnboard")
                self?.window?.close()
                if self?.controller.pause.isActive(at: .now) == true { self?.controller.reveal() }
                else { self?.controller.hide() }
            }))
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) { controller.endArranging() }
    func applicationWillTerminate(_ notification: Notification) { controller?.shutdown() }
}
