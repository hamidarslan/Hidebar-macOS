import Foundation
import Testing
@testable import HidebarCore

@Test func pauseExpiresAtBoundaryAndAfterSleep() {
    let start = Date(timeIntervalSince1970: 100)
    var pause = PauseState.until(start.addingTimeInterval(300))
    #expect(pause.isActive(at: start))
    #expect(!pause.isActive(at: start.addingTimeInterval(300)))
    pause.expire(at: start.addingTimeInterval(3600))
    #expect(pause == .none)
}
@Test func indefinitePauseSurvivesTimeAndCanResume() {
    var pause = PauseState.untilResumed
    pause.expire(at: .distantFuture)
    #expect(pause.isActive(at: .distantFuture))
    pause = .none
    #expect(!pause.isActive(at: .now))
}
@Test func shortcutRejectsTypingAndMalformedPreferences() {
    #expect(ShortcutChoice.standard.isValid)
    #expect(ShortcutChoice.standard.display == "⌃⌥H")
    for modifiers in [UInt32(0), ShortcutChoice.shift, ShortcutChoice.option, UInt32.max] {
        #expect(!ShortcutChoice(keyCode: 4, modifiers: modifiers, label: "H").isValid)
    }
    #expect(!ShortcutChoice(keyCode: 500, modifiers: ShortcutChoice.control, label: "H").isValid)
    #expect(!ShortcutChoice(keyCode: 53, modifiers: ShortcutChoice.control, label: "Escape").isValid)
    #expect(!ShortcutChoice(keyCode: 4, modifiers: ShortcutChoice.control, label: "\n").isValid)
}
