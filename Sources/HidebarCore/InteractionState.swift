import Foundation

public enum PauseState: Equatable, Sendable {
    case none
    case until(Date)
    case untilResumed

    public func isActive(at now: Date) -> Bool {
        switch self {
        case .none: false
        case .until(let end): end > now
        case .untilResumed: true
        }
    }

    public mutating func expire(at now: Date) {
        if case .until(let end) = self, end <= now { self = .none }
    }
}

public struct ShortcutChoice: Equatable, Sendable {
    public let keyCode: UInt32
    public let modifiers: UInt32
    public let label: String
    public static let command: UInt32 = 256
    public static let shift: UInt32 = 512
    public static let option: UInt32 = 2048
    public static let control: UInt32 = 4096
    public static let standard = ShortcutChoice(keyCode: 4, modifiers: control | option, label: "H")

    public init(keyCode: UInt32, modifiers: UInt32, label: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.label = label
    }

    public var isValid: Bool {
        let allowed = Self.command | Self.shift | Self.option | Self.control
        return keyCode < 128 && keyCode != 53 && modifiers & ~allowed == 0
            && modifiers & (Self.command | Self.control) != 0
            && !label.isEmpty && label.count <= 12
            && !label.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    }

    public var display: String {
        [(Self.control, "⌃"), (Self.option, "⌥"), (Self.shift, "⇧"), (Self.command, "⌘")]
            .filter { modifiers & $0.0 != 0 }.map(\.1).joined() + label
    }
}
