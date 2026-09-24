import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var model: BarController
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Troubleshooting").font(.title2.bold())
            Text("Review this report before copying. Nothing is uploaded automatically.").foregroundStyle(.secondary)
            ScrollView {
                Text(model.diagnosticsReport).font(.system(.body, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("If icons are missing, close this panel and use Show icons. For login issues, install Hidebar in Applications and check System Settings → General → Login Items.")
                .font(.callout).foregroundStyle(.secondary)
            if !model.diagnosticCopyMessage.isEmpty { Text(model.diagnosticCopyMessage).font(.callout) }
            HStack {
                Button("Refresh") { model.refreshDiagnostics() }
                Button("Copy report") { model.copyDiagnostics() }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }.padding(24).frame(width: 580, height: 500)
    }
}
