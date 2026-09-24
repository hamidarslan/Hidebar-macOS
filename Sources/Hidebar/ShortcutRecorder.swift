import AppKit
import SwiftUI
import Carbon
import HidebarCore

struct ShortcutRecorder: NSViewRepresentable {
    @ObservedObject var model: BarController

    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.model = model
        button.bezelStyle = .rounded
        button.setAccessibilityLabel("Record keyboard shortcut")
        button.setAccessibilityHelp("Activate, then press a key with Control or Command. Escape cancels.")
        return button
    }
    func updateNSView(_ button: RecorderButton, context: Context) {
        button.title = model.recordingShortcut ? "Press shortcut… Esc cancels" : "Record: \(model.shortcut.display)"
    }

    @MainActor final class RecorderButton: NSButton {
        weak var model: BarController?
        override var acceptsFirstResponder: Bool { true }
        override func mouseDown(with event: NSEvent) { start() }
        override func accessibilityPerformPress() -> Bool { start(); return true }
        private func start() {
            guard window?.makeFirstResponder(self) == true else { return }
            model?.recordingShortcut = true
        }
        override func resignFirstResponder() -> Bool {
            model?.cancelShortcutRecording()
            return super.resignFirstResponder()
        }
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard model?.recordingShortcut == true, window?.firstResponder === self else { return false }
            capture(event)
            return true
        }
        override func keyDown(with event: NSEvent) {
            if model?.recordingShortcut == true { capture(event) }
            else if event.keyCode == 49 || event.keyCode == 36 { start() }
            else { super.keyDown(with: event) }
        }
        private func capture(_ event: NSEvent) {
            guard !event.isARepeat else { return }
            if event.keyCode == 53 { model?.cancelShortcutRecording(); return }
            let flags = event.modifierFlags
            var modifiers: UInt32 = 0
            if flags.contains(.command) { modifiers |= ShortcutChoice.command }
            if flags.contains(.control) { modifiers |= ShortcutChoice.control }
            if flags.contains(.option) { modifiers |= ShortcutChoice.option }
            if flags.contains(.shift) { modifiers |= ShortcutChoice.shift }
            let special: [UInt16: String] = [36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 117: "Forward Del", 123: "←", 124: "→", 125: "↓", 126: "↑",
                122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"]
            let label = special[event.keyCode] ?? event.charactersIgnoringModifiers?.uppercased() ?? ""
            model?.setShortcut(ShortcutChoice(keyCode: UInt32(event.keyCode), modifiers: modifiers, label: label))
        }
    }
}
