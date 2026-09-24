import Testing
@testable import HidebarCore

@Test func legacyLengthIsBounded() {
    #expect(SpacerLayout.lengths(widths: [1920, 6000], usableRightWidths: [], modern: false) == [10000])
}
@Test func modernSegmentsStayBelowRejectionThreshold() {
    let result = SpacerLayout.lengths(widths: [1440, 2560], usableRightWidths: [], modern: true)
    #expect(result.allSatisfy { $0 < 720 })
    #expect(result.reduce(0, +) >= 2560)
    #expect(result.count <= 7)
}
@Test func notchConstrainsEachSegment() {
    let result = SpacerLayout.lengths(widths: [1512], usableRightWidths: [660], modern: true)
    #expect(result.allSatisfy { $0 == 596 })
    #expect(result.count == 1)
}
@Test func missingAndInvalidDisplaysHaveSafeFallbacks() {
    let result = SpacerLayout.lengths(widths: [.nan, -1, 0], usableRightWidths: [], modern: true)
    #expect(!result.isEmpty)
    #expect(result.allSatisfy { $0.isFinite && $0 > 0 })
}
