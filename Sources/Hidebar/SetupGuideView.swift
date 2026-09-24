import SwiftUI

struct SetupGuideView: View {
    @ObservedObject var model: BarController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let titles = ["Hold Command", "Move an icon left", "Try hiding", "Bring everything back", "You're ready"]
    private let details = [
        "Hold ⌘ while dragging an icon in your real menu bar. The example below is an illustration.",
        "Drop unwanted icons to the left of the │ divider. Keep Hidebar's arrow on its right.",
        "Use Try hiding below to test your arrangement. macOS decides which system icons can move.",
        "Use Show again to reveal your icons. You can always reopen Hidebar from Applications for recovery.",
        "Click the arrow to toggle icons. Right-click it for pause, delay, and recovery controls."
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SETUP · \(model.guideStep + 1) OF 5").font(.caption.bold())
                Spacer()
                Button("Dismiss") { model.showingGuide = false }
            }
            Text(titles[model.guideStep]).font(.title3.bold())
            Text(details[model.guideStep]).font(.callout).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 30) {
                Image(systemName: "cloud").opacity(model.guideStep >= 1 ? 1 : 0)
                Text("│").font(.title2)
                Image(systemName: "chevron.left")
                Image(systemName: "cloud").opacity(model.guideStep >= 1 ? 0 : 1)
                    .offset(x: model.guideStep >= 1 ? -145 : 0)
                Spacer()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Illustration: move an unwanted icon left of the divider; keep Hidebar's arrow right of it.")
            HStack {
                if model.guideStep > 0 { Button("Back") { advance(-1) } }
                Spacer()
                Button(actionTitle) {
                    switch model.guideStep {
                    case 2: model.hide(); advance(1)
                    case 3: model.reveal(); advance(1)
                    case 4: model.showingGuide = false; UserDefaults.standard.set(true, forKey: "didOnboard")
                    default: advance(1)
                    }
                }.buttonStyle(.borderedProminent)
            }
        }.padding(18).background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
    private var actionTitle: String {
        switch model.guideStep { case 2: "Try hiding"; case 3: "Show again"; case 4: "Finish setup"; default: "Next" }
    }
    private func advance(_ step: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
            model.guideStep = min(4, max(0, model.guideStep + step))
        }
    }
}
