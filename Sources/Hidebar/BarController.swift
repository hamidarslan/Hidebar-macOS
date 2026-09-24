import AppKit
import Carbon
import ServiceManagement
import HidebarCore

@MainActor
final class BarController: NSObject, ObservableObject {
    @Published private(set) var hidden = false
    @Published var autoHide: Bool { didSet { save(); scheduleAutoHide() } }
    @Published var delay: Double { didSet { save(); scheduleAutoHide() } }
    @Published var startHidden: Bool { didSet { save() } }
    @Published var symbol: String { didSet { save(); updateButton() } }
    @Published private(set) var loginEnabled = false
    @Published private(set) var loginMessage = ""
    @Published private(set) var shortcutAvailable = false
    @Published var showingPrivacy = false
    @Published var confirmingReset = false
    @Published var privacyMessage = ""
    @Published private(set) var pause: PauseState = .none
    @Published private(set) var shortcut: ShortcutChoice = .standard
    @Published private(set) var shortcutEnabled = true
    @Published var recordingShortcut = false
    @Published var shortcutMessage = ""
    @Published var showingDiagnostics = false
    @Published var diagnosticsReport = ""
    @Published var diagnosticCopyMessage = ""
    @Published var showingGuide = false
    @Published var guideStep = 0
    @Published private(set) var loginStatus = "Unknown"
    private var shortcutEvents = 0
    private var pauseTimer: Timer?
    var openSettings: (() -> Void)?
    private var toggleItem: NSStatusItem!
    private var spacers: [NSStatusItem] = []
    private var timer: Timer?
    private var startupTimer: Timer?
    private var hotKey: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var arranging = false
    private var menuOpen = false
    private var displaySignature = ""
    private let defaults = UserDefaults.standard

    override init() {
        let d = UserDefaults.standard
        d.register(defaults: ["autoHide": true, "delay": 10.0, "startHidden": false, "symbol": "chevron"])
        autoHide = d.bool(forKey: "autoHide")
        delay = [5.0, 10, 15, 30, 60].contains(d.double(forKey: "delay")) ? d.double(forKey: "delay") : 10
        startHidden = d.bool(forKey: "startHidden")
        symbol = d.string(forKey: "symbol") ?? "chevron"
        super.init()
        if let key = d.object(forKey: "shortcutKey") as? NSNumber,
           let modifiers = d.object(forKey: "shortcutModifiers") as? NSNumber,
           let keyCode = UInt32(exactly: key.int64Value), let modifierMask = UInt32(exactly: modifiers.int64Value) {
            let candidate = ShortcutChoice(keyCode: keyCode, modifiers: modifierMask,
                                           label: d.string(forKey: "shortcutLabel") ?? "")
            if candidate.isValid { shortcut = candidate }
        }
        shortcutEnabled = d.object(forKey: "shortcutEnabled") == nil || d.bool(forKey: "shortcutEnabled")
        showingGuide = !d.bool(forKey: "didOnboard")
        toggleItem = NSStatusBar.system.statusItem(withLength: 28)
        toggleItem.autosaveName = "Hidebar.Toggle.v2"
        toggleItem.button?.target = self
        toggleItem.button?.action = #selector(clicked)
        toggleItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        // Fresh items enter at the left: arrow, concealed spacer slots, then divider.
        if modern {
            for i in 1...6 {
                let item = NSStatusBar.system.statusItem(withLength: 0)
                item.autosaveName = "Hidebar.Spacer.v2.\(i)"
                item.button?.setAccessibilityElement(false)
                item.isVisible = false
                spacers.append(item)
            }
        }
        let divider = NSStatusBar.system.statusItem(withLength: 16)
        divider.autosaveName = "Hidebar.Divider.v2"
        divider.button?.title = "│"
        divider.button?.font = .systemFont(ofSize: 15, weight: .light)
        divider.button?.target = self
        divider.button?.action = #selector(dividerClicked)
        divider.button?.toolTip = "Hold ⌘ and drag unwanted icons to the left of this divider"
        divider.button?.setAccessibilityLabel("Hidebar divider")
        spacers.insert(divider, at: 0)
        updateButton()
        displaySignature = currentDisplaySignature()
        refreshLogin()
        registerShortcut()
        NotificationCenter.default.addObserver(self, selector: #selector(becameActive), name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil)
    }

    private var modern: Bool { ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 27 }
    private func save() {
        defaults.set(autoHide, forKey: "autoHide")
        defaults.set(delay, forKey: "delay")
        defaults.set(startHidden, forKey: "startHidden")
        defaults.set(symbol, forKey: "symbol")
    }
    func toggle() { hidden ? reveal() : hide() }
    func reveal() {
        startupTimer?.invalidate()
        hidden = false
        applyLayout()
        scheduleAutoHide()
    }
    func hide() {
        pauseTimer?.invalidate()
        pause = .none
        startupTimer?.invalidate()
        timer?.invalidate()
        hidden = true
        applyLayout()
    }
    func beginArranging() { arranging = true; reveal(); refreshLogin() }
    func endArranging() { arranging = false; cancelShortcutRecording(); scheduleAutoHide() }
    var pauseDescription: String {
        switch pause {
        case .none: return "Auto-hide follows your settings"
        case .until(let date): return "Visible until \(date.formatted(date: .omitted, time: .shortened))"
        case .untilResumed: return "Visible until resumed or Hidebar quits"
        }
    }
    func pauseHiding(seconds: TimeInterval?) {
        pauseTimer?.invalidate()
        if let seconds {
            guard seconds.isFinite, seconds > 0 else { return }
            pause = .until(Date().addingTimeInterval(seconds))
            pauseTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                Task { @MainActor in self?.refreshPause() }
            }
        } else { pause = .untilResumed }
        reveal()
    }
    func resumeHiding() {
        pauseTimer?.invalidate()
        pause = .none
        scheduleAutoHide()
    }
    private func refreshPause() {
        pause.expire(at: .now)
        scheduleAutoHide()
    }
    func scheduleStartupHide() {
        startupTimer?.invalidate()
        startupTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.arranging, !self.pause.isActive(at: .now) else { return }
                self.hide()
            }
        }
    }
    private func applyLayout() {
        let lengths = SpacerLayout.lengths(widths: NSScreen.screens.map { Double($0.frame.width) },
                                          usableRightWidths: NSScreen.screens.compactMap { $0.auxiliaryTopRightArea.map { Double($0.width) } }, modern: modern)
        for (i, item) in spacers.enumerated() {
            if i > 0 { item.isVisible = hidden && i < lengths.count }
            item.length = hidden ? (i < lengths.count ? lengths[i] : 0) : (i == 0 ? 16 : 0)
        }
        spacers.first?.button?.title = hidden ? "" : "│"
        updateButton()
    }
    private func updateButton() {
        let name = symbol == "dots" ? (hidden ? "ellipsis" : "ellipsis.circle") : (hidden ? "chevron.left" : "chevron.right")
        let image = NSImage(systemSymbolName: name, accessibilityDescription: hidden ? "Show menu bar icons" : "Hide menu bar icons")
        image?.isTemplate = true
        toggleItem?.button?.image = image
        toggleItem?.button?.toolTip = "Hidebar · \(hidden ? "Show" : "Hide") icons · Right-click for settings"
    }
    private func scheduleAutoHide() {
        timer?.invalidate()
        guard autoHide, !hidden, !arranging, !pause.isActive(at: .now) else { return }
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Do not close the bar while the pointer is using it or a mouse button is down.
                let point = NSEvent.mouseLocation
                let nearBar = NSScreen.screens.contains { $0.frame.contains(point) && point.y > $0.frame.maxY - 80 }
                if self.menuOpen || nearBar || NSEvent.pressedMouseButtons != 0 { self.scheduleAutoHide() }
                else { self.hide() }
            }
        }
    }
    private func currentDisplaySignature() -> String {
        NSScreen.screens.map {
            "\($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] ?? ""):\($0.frame):\($0.auxiliaryTopRightArea?.width ?? 0)"
        }.joined(separator: "|")
    }
    @objc private func screenChanged() {
        // Menu bar relayout can emit this too; only a real display change should reveal.
        let next = currentDisplaySignature()
        guard next != displaySignature else { return }
        displaySignature = next
        reveal()
    }
    @objc private func woke() { refreshPause(); reveal() }
    @objc private func becameActive() { refreshLogin(); refreshPause() }
    @objc private func dividerClicked() { openSettings?() }
    @objc private func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp || NSApp.currentEvent?.modifierFlags.contains(.control) == true {
            showMenu()
        } else if NSApp.currentEvent?.modifierFlags.contains(.option) == true { openSettings?() }
        else { toggle() }
    }
    private func showMenu() {
        let menu = NSMenu()
        for (title, action) in [(hidden ? "Show icons" : "Hide now (end pause)", #selector(menuToggle)), ("Arrange icons & Settings…", #selector(settingsAction)), ("Keep visible until resumed", #selector(recover))] {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        for (title, duration) in [("Keep visible for 5 minutes", 300), ("Keep visible for 1 hour", 3600)] {
            let item = NSMenuItem(title: title, action: #selector(timedPause(_:)), keyEquivalent: "")
            item.target = self; item.tag = duration; menu.addItem(item)
        }
        if pause != .none {
            let item = NSMenuItem(title: "Resume auto-hide", action: #selector(resumeAction), keyEquivalent: "")
            item.target = self; menu.addItem(item)
        }
        let delays = NSMenu()
        for seconds in [5, 10, 15, 30, 60] {
            let item = NSMenuItem(title: "\(seconds) seconds", action: #selector(chooseDelay(_:)), keyEquivalent: "")
            item.target = self; item.tag = seconds; item.state = delay == Double(seconds) ? .on : .off
            delays.addItem(item)
        }
        let delayItem = NSMenuItem(title: "Auto-hide delay", action: nil, keyEquivalent: "")
        delayItem.submenu = delays; menu.addItem(delayItem)
        let automatic = NSMenuItem(title: "Auto-hide enabled", action: #selector(toggleAutomatic), keyEquivalent: "")
        automatic.target = self; automatic.state = autoHide ? .on : .off; menu.addItem(automatic)
        let diagnostics = NSMenuItem(title: "Troubleshooting…", action: #selector(diagnosticsAction), keyEquivalent: "")
        diagnostics.target = self; menu.addItem(diagnostics)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Hidebar", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        menuOpen = true
        toggleItem.menu = menu
        toggleItem.button?.performClick(nil)
        toggleItem.menu = nil
        menuOpen = false
    }
    @objc private func menuToggle() { toggle() }
    @objc private func settingsAction() { openSettings?() }
    @objc private func recover() { pauseHiding(seconds: nil) }
    @objc private func timedPause(_ item: NSMenuItem) { pauseHiding(seconds: Double(item.tag)) }
    @objc private func resumeAction() { resumeHiding() }
    @objc private func chooseDelay(_ item: NSMenuItem) { delay = Double(item.tag) }
    @objc private func toggleAutomatic() { autoHide.toggle() }
    @objc private func diagnosticsAction() { openSettings?(); refreshDiagnostics(); showingDiagnostics = true }
    @objc private func quitApp() { NSApp.terminate(nil) }

    func setLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            refreshLogin()
        } catch {
            refreshLogin()
            loginMessage = "Could not change login setting: \(error.localizedDescription)"
        }
    }
    func refreshLogin() {
        loginEnabled = SMAppService.mainApp.status == .enabled
        switch SMAppService.mainApp.status {
        case .enabled: loginStatus = "Enabled"; loginMessage = ""
        case .notRegistered: loginStatus = "Off"; loginMessage = ""
        case .requiresApproval: loginStatus = "Awaiting approval"; loginMessage = "Allow Hidebar in System Settings → General → Login Items."
        case .notFound: loginStatus = "Unavailable"; loginMessage = "macOS could not find the login service. Install Hidebar in Applications; check Login Items in System Settings."
        @unknown default: loginStatus = "Unknown"; loginMessage = "Check Login Items in System Settings."
        }
    }
    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }
    func resetPreferences() -> String {
        let loginStatusUnknown = SMAppService.mainApp.status == .notFound
        do {
            if SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval {
                try SMAppService.mainApp.unregister()
            }
            refreshLogin()
            guard SMAppService.mainApp.status == .notRegistered || loginStatusUnknown else {
                return "Turn off Hidebar in System Settings → General → Login Items, then try again."
            }
        } catch {
            refreshLogin()
            return "Preferences were not reset: \(error.localizedDescription)"
        }
        autoHide = true
        delay = 10
        startHidden = false
        symbol = "chevron"
        resumeHiding()
        disableShortcut()
        shortcut = .standard
        defaults.set(Int(shortcut.keyCode), forKey: "shortcutKey")
        defaults.set(Int(shortcut.modifiers), forKey: "shortcutModifiers")
        defaults.set(shortcut.label, forKey: "shortcutLabel")
        setShortcut(.standard)
        for key in ["autoHide", "delay", "startHidden", "symbol", "didOnboard"] {
            defaults.removeObject(forKey: key)
        }
        reveal()
        let result = loginStatusUnknown
            ? "Preferences reset. macOS could not confirm login-item status; check System Settings → General → Login Items."
            : "Preferences reset. Launch at login is off."
        return result + (shortcutAvailable ? "" : " The default shortcut is unavailable and remains off.")
    }
    private func registerShortcut() {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        // Receive on the application target; registration uses the dispatcher below.
        let status = InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let userData, let event else { return OSStatus(eventNotHandledErr) }
            var keyID = EventHotKeyID()
            guard GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                                    MemoryLayout<EventHotKeyID>.size, nil, &keyID) == noErr,
                  keyID.signature == 0x48494445 else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                let controller = Unmanaged<BarController>.fromOpaque(userData).takeUnretainedValue()
                guard !controller.recordingShortcut else {
                    controller.recordingShortcut = false
                    controller.shortcutMessage = "This shortcut is already active."
                    return
                }
                controller.shortcutEvents += 1
                controller.shortcutMessage = "Shortcut received successfully."
                controller.toggle()
            }
            return noErr
        }, 1, &event, pointer, &hotKeyHandler)
        guard status == noErr else { shortcutMessage = "Shortcut handler unavailable (\(status))."; return }
        guard shortcutEnabled else { shortcutMessage = "Shortcut is turned off."; return }
        setShortcut(shortcut)
    }
    func setShortcut(_ candidate: ShortcutChoice) {
        guard candidate.isValid else { shortcutMessage = "Use a key with Control or Command. Escape cancels."; return }
        guard hotKeyHandler != nil else { shortcutMessage = "Shortcut handler unavailable. Reopen Hidebar to retry."; return }
        if candidate.keyCode == shortcut.keyCode && candidate.modifiers == shortcut.modifiers, hotKey != nil {
            recordingShortcut = false; shortcutMessage = "This shortcut is already active."; return
        }
        let keyID = EventHotKeyID(signature: 0x48494445, id: 1)
        var replacement: EventHotKeyRef?
        let result = RegisterEventHotKey(candidate.keyCode, candidate.modifiers, keyID, GetEventDispatcherTarget(), OptionBits(kEventHotKeyExclusive), &replacement)
        guard result == noErr, let replacement else {
            shortcutMessage = "Shortcut unavailable or in use (\(result)). Your previous shortcut is unchanged."
            recordingShortcut = false
            return
        }
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = replacement
        shortcut = candidate
        shortcutEnabled = true
        shortcutAvailable = true
        recordingShortcut = false
        defaults.set(Int(candidate.keyCode), forKey: "shortcutKey")
        defaults.set(Int(candidate.modifiers), forKey: "shortcutModifiers")
        defaults.set(candidate.label, forKey: "shortcutLabel")
        defaults.set(true, forKey: "shortcutEnabled")
        shortcutMessage = "Registered. Press \(candidate.display) to test show/hide."
    }
    func cancelShortcutRecording() {
        guard recordingShortcut else { return }
        recordingShortcut = false
        shortcutMessage = "Recording cancelled. Your shortcut is unchanged."
    }
    func disableShortcut() {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        hotKey = nil; shortcutAvailable = false; shortcutEnabled = false; recordingShortcut = false
        defaults.set(false, forKey: "shortcutEnabled")
        shortcutMessage = "Shortcut is turned off."
    }
    func refreshDiagnostics() {
        refreshLogin()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let os = ProcessInfo.processInfo.operatingSystemVersion
        #if arch(arm64)
        let architecture = "Apple Silicon"
        #else
        let architecture = "Intel"
        #endif
        diagnosticsReport = """
        Hidebar \(version) — local diagnostic summary
        macOS: \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)
        Architecture: \(architecture)
        Connected display count: \(NSScreen.screens.count)
        Icons: \(hidden ? "hidden" : "revealed")
        Auto-hide: \(autoHide ? "on" : "off"), \(Int(delay)) seconds
        Pause: \(pause == .none ? "inactive" : "active")
        Shortcut: \(shortcutEnabled ? (shortcutAvailable ? "registered" : "unavailable") : "off")
        Shortcut activations this session: \(shortcutEvents)
        Launch at login: \(loginStatus)
        Distribution: private preview; not notarized
        No account names, file paths, display identifiers, key contents, or app lists included.
        """
        diagnosticCopyMessage = ""
    }
    func copyDiagnostics() {
        NSPasteboard.general.clearContents()
        diagnosticCopyMessage = NSPasteboard.general.setString(diagnosticsReport, forType: .string)
            ? "Copied to your clipboard. Nothing was uploaded." : "Could not copy. Select and copy the report manually."
    }
    func shutdown() {
        pauseTimer?.invalidate()
        timer?.invalidate()
        startupTimer?.invalidate()
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let hotKeyHandler { RemoveEventHandler(hotKeyHandler) }
        spacers.forEach { NSStatusBar.system.removeStatusItem($0) }
        if let toggleItem { NSStatusBar.system.removeStatusItem(toggleItem) }
    }
}
