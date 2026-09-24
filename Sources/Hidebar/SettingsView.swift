import SwiftUI

private let pine = Color.accentColor

struct SettingsView: View {
    @ObservedObject var model: BarController
    let done: () -> Void

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 10) {
                if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png"),
                   let icon = NSImage(contentsOf: url) {
                    Image(nsImage: icon).resizable().interpolation(.high)
                        .frame(width: 38, height: 38).accessibilityLabel("Hidebar apple icon")
                }
                Text("hidebar").font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(model.hidden ? pine : Color.orange).frame(width: 6, height: 6)
                    Text(model.hidden ? "Tucked away" : "Icons revealed").font(.system(size: 11, weight: .medium))
                }.padding(.horizontal, 11).padding(.vertical, 7).background(Color(nsColor: .controlBackgroundColor), in: Capsule())
            }
            VStack(alignment: .leading, spacing: 7) {
                Text("A little less clutter.").font(.system(size: 36, weight: .semibold, design: .rounded)).tracking(-1.2)
                Text("Keep what matters. Tuck everything else away.")
                    .font(.system(size: 15)).foregroundStyle(.secondary)
            }
            if model.showingGuide { SetupGuideView(model: model) }
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("YOUR MENU BAR, SIMPLIFIED", systemImage: "sparkle")
                        .font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundStyle(pine)
                    Spacer()
                    Text("⌘ + drag to arrange").font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                }
                HStack(spacing: 17) {
                    HStack(spacing: 16) {
                        Image(systemName: "cloud")
                        Image(systemName: "headphones")
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }.foregroundStyle(model.hidden ? pine.opacity(0.18) : pine)
                    Text("│").foregroundStyle(pine.opacity(0.5))
                    Image(systemName: model.hidden ? "chevron.left" : "chevron.right")
                        .fontWeight(.bold).foregroundStyle(pine)
                    Spacer()
                    Image(systemName: "wifi")
                    Image(systemName: "battery.100percent")
                    Text("9:41").font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 16)).padding(17)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
                HStack {
                    Text("← Tuck away").foregroundStyle(pine)
                    Spacer()
                    Text("Keep visible →").foregroundStyle(.secondary)
                }.font(.system(size: 11, weight: .medium))
                Divider().opacity(0.5)
                HStack(alignment: .top, spacing: 12) {
                    Text("⌘").font(.system(size: 20, weight: .medium))
                        .frame(width: 38, height: 36).background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hold Command. Drag. Done.").font(.system(size: 13, weight: .semibold))
                        Text("In your actual menu bar, drag unwanted icons left of the │ divider. Keep the Hidebar arrow to its right.")
                            .font(.system(size: 12)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }.padding(20).background(pine.opacity(0.065), in: RoundedRectangle(cornerRadius: 18))

            VStack(spacing: 0) {
                row("Automatically tuck away", detail: "Hide revealed icons after a quiet moment.") {
                    Picker("Auto-hide delay", selection: $model.delay) {
                        ForEach([5.0, 10, 15, 30, 60], id: \.self) { Text("\(Int($0)) sec").tag($0) }
                    }.labelsHidden().frame(width: 90).disabled(!model.autoHide)
                    Toggle("Automatically tuck away", isOn: $model.autoHide).labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                Divider()
                row("Start tucked away", detail: "Wait 15 seconds after opening, then hide.") {
                    Toggle("Start tucked away", isOn: $model.startHidden).labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                Divider()
                row("Launch at login", detail: model.loginStatus) {
                    Toggle("Launch at login", isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
                        .labelsHidden().toggleStyle(.switch).controlSize(.small)
                }
                Divider()
                row("Menu bar style", detail: "Choose the control that feels right.") {
                    Picker("Menu bar style", selection: $model.symbol) {
                        Text("Chevron").tag("chevron")
                        Text("Dots").tag("dots")
                    }.labelsHidden().pickerStyle(.segmented).frame(width: 150)
                }
            }
            if !model.loginMessage.isEmpty {
                Text(model.loginMessage).font(.caption).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
                Button("Open Login Items") { model.openLoginSettings() }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Keyboard shortcut").font(.headline)
                HStack {
                    ShortcutRecorder(model: model).frame(width: 250, height: 28)
                    Button("Default") { model.setShortcut(.standard) }
                    Button(model.shortcutEnabled ? "Turn off" : "Turn on") {
                        if model.shortcutEnabled { model.disableShortcut() } else { model.setShortcut(model.shortcut) }
                    }
                }
                Text(model.shortcutMessage).font(.callout).foregroundStyle(.secondary)
                Text("Record with Control or Command. Then press your shortcut here or from another app to test it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Keep icons visible").font(.headline)
                HStack {
                    Button("5 minutes") { model.pauseHiding(seconds: 300) }
                    Button("1 hour") { model.pauseHiding(seconds: 3600) }
                    Button("Until resumed") { model.pauseHiding(seconds: nil) }
                    if model.pause != .none { Button("Resume") { model.resumeHiding() } }
                }
                Text(model.pauseDescription).font(.callout).foregroundStyle(.secondary)
            }
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Less noise. More focus.").font(.system(size: 12, weight: .medium))
                    Text("Right-click the arrow for settings.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                Spacer()
                Button(model.hidden ? "Show icons" : (model.pause != .none ? "Hide & end pause" : "Try hiding")) { model.toggle() }
                    .buttonStyle(.bordered).controlSize(.large)
                Button("All set", action: done).buttonStyle(.borderedProminent).controlSize(.large)
            }
            HStack {
                Button("Setup guide") { model.guideStep = 0; model.showingGuide.toggle(); model.reveal() }
                Button("Privacy & local data") { model.showingPrivacy = true }
                Button("Troubleshooting") { model.refreshDiagnostics(); model.showingDiagnostics = true }
            }.buttonStyle(.link).font(.system(size: 12))
        }
        .padding(.horizontal, 32).padding(.top, 40).padding(.bottom, 26)
        .frame(width: 680)
        }
        .frame(width: 680, height: 780)
        .foregroundStyle(.primary)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $model.showingPrivacy) { PrivacyView(model: model) }
        .sheet(isPresented: $model.showingDiagnostics) { DiagnosticsView(model: model) }
    }

    private func row<Content: View>(_ title: String, detail: String, @ViewBuilder controls: () -> Content) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 13, weight: .medium))
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            controls()
        }.padding(.vertical, 11)
    }
}
