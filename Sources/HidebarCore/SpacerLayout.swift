import Foundation

public enum SpacerLayout {
    /// macOS 27 rejects individual status items approaching half a screen wide.
    public static func lengths(widths: [Double], usableRightWidths: [Double], modern: Bool) -> [Double] {
        let widths = widths.filter { $0.isFinite && $0 > 0 }
        let widest = widths.max() ?? 1440
        guard modern else { return [min(10_000, max(500, widest * 2))] }
        let narrowest = widths.min() ?? 1440
        let right = usableRightWidths.filter { $0.isFinite && $0 > 0 }.min() ?? narrowest / 2
        let segment = max(40, floor(min(narrowest / 2, right) - 64))
        // A single display needs only its right-side status area displaced.
        // Extra segments can cause MenuBarAgent to overflow the controller itself.
        let count = widths.count <= 1 ? 1 : min(7, max(1, Int(ceil(widest / segment))))
        return Array(repeating: segment, count: count)
    }
}
