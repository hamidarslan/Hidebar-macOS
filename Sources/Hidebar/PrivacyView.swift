import SwiftUI

struct PrivacyView: View {
    @ObservedObject var model: BarController
    @Environment(\.dismiss) private var dismiss

    private var policy: String {
        guard let url = Bundle.main.url(forResource: "PRIVACY", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "The bundled privacy policy could not be loaded. Please obtain a complete copy of Hidebar."
        }
        return text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy & local data").font(.title2.bold())
            Text("No accounts. No analytics. No network access.").foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(policy.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, block in
                        paragraph(block)
                    }
                }.textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading).padding(.trailing, 8)
            }
            if !model.privacyMessage.isEmpty { Text(model.privacyMessage).font(.callout) }
            HStack {
                Button("Reset preferences…") { model.confirmingReset = true }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24).frame(width: 580, height: 560)
        .alert("Reset Hidebar preferences?", isPresented: $model.confirmingReset) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) { model.privacyMessage = model.resetPreferences() }
        } message: {
            Text("This restores Hidebar's options and reveals your icons. It also removes any login registration macOS can identify. If login status is unavailable, you will be asked to check System Settings. Other apps and saved menu bar positions are unchanged.")
        }
    }

    @ViewBuilder private func paragraph(_ block: String) -> some View {
        if block.hasPrefix("# ") {
            Text(String(block.dropFirst(2))).font(.headline)
        } else if block.hasPrefix("## ") {
            Text(String(block.dropFirst(3))).font(.headline).padding(.top, 4)
        } else {
            Text((try? AttributedString(markdown: block,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(block))
                .font(.system(size: 13))
        }
    }
}
