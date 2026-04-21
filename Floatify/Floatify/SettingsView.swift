import AppKit
import ServiceManagement
import SwiftUI
import UniformTypeIdentifiers

private enum SetupHealthLevel {
    case good
    case warning
    case error

    var label: String {
        switch self {
        case .good:
            return "Ready"
        case .warning:
            return "Attention"
        case .error:
            return "Blocked"
        }
    }

    var tint: Color {
        switch self {
        case .good:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

private struct SetupHealthItem {
    let level: SetupHealthLevel
    let summary: String
    let detail: String
}

private enum HookConfiguration {
    case claude
    case codex

    var title: String {
        switch self {
        case .claude:
            return "Claude Code hooks"
        case .codex:
            return "Codex hooks"
        }
    }

    var fileURL: URL {
        switch self {
        case .claude:
            return URL(fileURLWithPath: ("~/.claude/settings.json" as NSString).expandingTildeInPath)
        case .codex:
            return URL(fileURLWithPath: ("~/.codex/hooks.json" as NSString).expandingTildeInPath)
        }
    }

    var expectedFragments: [String] {
        switch self {
        case .claude:
            return [
                "/usr/local/bin/floatify --status complete"
            ]
        case .codex:
            return [
                "/usr/local/bin/floatify --status running",
                "/usr/local/bin/floatify --status complete"
            ]
        }
    }

    var defaultContents: String {
        switch self {
        case .claude:
            return """
            {
              "hooks": {
                "Stop": [
                  {
                    "hooks": [
                      {
                        "type": "command",
                        "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
                      }
                    ]
                  }
                ],
                "SessionEnd": [
                  {
                    "hooks": [
                      {
                        "type": "command",
                        "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
                      }
                    ]
                  }
                ]
              }
            }
            """
        case .codex:
            return """
            {
              "hooks": {
                "UserPromptSubmit": [
                  {
                    "hooks": [
                      {
                        "type": "command",
                        "command": "sh -c '/usr/local/bin/floatify --status running >/dev/null 2>&1'"
                      }
                    ]
                  }
                ],
                "Stop": [
                  {
                    "hooks": [
                      {
                        "type": "command",
                        "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
                      }
                    ]
                  }
                ],
                "SessionEnd": [
                  {
                    "hooks": [
                      {
                        "type": "command",
                        "command": "sh -c '/usr/local/bin/floatify --status complete >/dev/null 2>&1'"
                      }
                    ]
                  }
                ]
              }
            }
            """
        }
    }
}

private struct SetupHealthSnapshot {
    let cli: SetupHealthItem
    let claudeHooks: SetupHealthItem
    let codexHooks: SetupHealthItem
    let appLocation: SetupHealthItem
    let launchAtLogin: SetupHealthItem
    let launchAtLoginStatus: SMAppService.Status

    static func capture() -> SetupHealthSnapshot {
        let service = SMAppService.mainApp
        let launchStatus = service.status

        return SetupHealthSnapshot(
            cli: cliHealth(),
            claudeHooks: hookHealth(for: .claude),
            codexHooks: hookHealth(for: .codex),
            appLocation: appLocationHealth(),
            launchAtLogin: launchAtLoginHealth(for: launchStatus),
            launchAtLoginStatus: launchStatus
        )
    }

    private static func cliHealth() -> SetupHealthItem {
        let cliPath = "/usr/local/bin/floatify"
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: cliPath) else {
            return SetupHealthItem(
                level: .warning,
                summary: "Missing",
                detail: "Install or repair /usr/local/bin/floatify."
            )
        }

        if fileManager.isExecutableFile(atPath: cliPath) {
            return SetupHealthItem(
                level: .good,
                summary: "Installed",
                detail: cliPath
            )
        }

        return SetupHealthItem(
            level: .warning,
            summary: "Present but not executable",
            detail: cliPath
        )
    }

    private static func hookHealth(for configuration: HookConfiguration) -> SetupHealthItem {
        let url = configuration.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return SetupHealthItem(
                level: .warning,
                summary: "Missing file",
                detail: url.path
            )
        }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return SetupHealthItem(
                level: .error,
                summary: "Unreadable",
                detail: url.path
            )
        }

        if configuration.expectedFragments.allSatisfy(contents.contains) {
            return SetupHealthItem(
                level: .good,
                summary: "Configured",
                detail: url.path
            )
        }

        if contents.contains("floatify") {
            return SetupHealthItem(
                level: .warning,
                summary: "Partial config detected",
                detail: url.path
            )
        }

        return SetupHealthItem(
            level: .warning,
            summary: "Hooks not detected",
            detail: url.path
        )
    }

    private static func appLocationHealth() -> SetupHealthItem {
        let bundlePath = Bundle.main.bundleURL.path
        if bundlePath.hasPrefix("/Applications/") {
            return SetupHealthItem(
                level: .good,
                summary: "Installed in /Applications",
                detail: bundlePath
            )
        }

        return SetupHealthItem(
            level: .warning,
            summary: "Not in /Applications",
            detail: bundlePath
        )
    }

    private static func launchAtLoginHealth(for status: SMAppService.Status) -> SetupHealthItem {
        switch status {
        case .enabled:
            return SetupHealthItem(
                level: .good,
                summary: "Enabled",
                detail: "Floatify launches automatically when you log in."
            )
        case .notRegistered:
            return SetupHealthItem(
                level: .warning,
                summary: "Disabled",
                detail: "Enable this after moving the app into /Applications."
            )
        case .requiresApproval:
            return SetupHealthItem(
                level: .warning,
                summary: "Needs approval",
                detail: "Approve Floatify in System Settings -> General -> Login Items."
            )
        case .notFound:
            return SetupHealthItem(
                level: .error,
                summary: "Unavailable",
                detail: "macOS could not register this app for login items yet."
            )
        @unknown default:
            return SetupHealthItem(
                level: .error,
                summary: "Unknown state",
                detail: "Refresh health after reopening Floatify."
            )
        }
    }
}

private struct SetupHealthBadge: View {
    let level: SetupHealthLevel
    let summary: String

    var body: some View {
        Text(summary)
            .font(.caption.weight(.semibold))
            .foregroundStyle(level.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(level.tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct SetupHealthRow<Actions: View>: View {
    let title: String
    let item: SetupHealthItem
    let actions: Actions

    init(title: String, item: SetupHealthItem, @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.item = item
        self.actions = actions()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(title)
                    .font(.headline)
                Spacer()
                SetupHealthBadge(level: item.level, summary: item.summary)
            }

            Text(item.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            actions
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @Environment(FloatifySettings.self) private var settings
    @Environment(FloaterVisualCatalog.self) private var visualCatalog

    @State private var health = SetupHealthSnapshot.capture()
    @State private var actionMessage = ""
    @State private var actionLevel: SetupHealthLevel = .good
    @State private var visualCatalogMessage = ""
    @State private var visualCatalogLevel: SetupHealthLevel = .good
    @State private var importAvatarName = ""
    @State private var isImportingAvatar = false
    @State private var managedPackID = FloaterVisualConstants.personalPackID
    @State private var managedAvatarID = ""
    @State private var managedAvatarName = ""
    @State private var managedAvatarOrientation: FloaterAvatarOrientation = .upright
    @State private var isManagingAvatar = false
    @State private var pendingDeleteAvatarID: String?
    @State private var pendingDeleteAvatarName = ""

    private let timeoutFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.allowsFloats = false
        f.minimum = 1
        f.maximum = 3600
        return f
    }()

    var body: some View {
        @Bindable var settings = settings
        let selectedPack = visualCatalog.resolvedPack(id: settings.selectedVisualPackID)
        let customPacks = visualCatalog.packs.filter { !$0.isBuiltIn }
        let resolvedManagedPack = resolvedManagedPack(
            customPacks: customPacks,
            selectedPackID: settings.selectedVisualPackID
        )
        let manageableAvatars = manageableAvatars(in: resolvedManagedPack)
        let selectedManagedAvatar = selectedManagedAvatar(in: resolvedManagedPack)
        let hasCustomPacks = !customPacks.isEmpty
        let canImportAvatar = !trimmedImportAvatarName.isEmpty
        let canSaveManagedAvatar = selectedManagedAvatar != nil
            && !trimmedManagedAvatarName.isEmpty
            && (
                trimmedManagedAvatarName != (selectedManagedAvatar?.displayName ?? "")
                || managedAvatarOrientation != (selectedManagedAvatar?.orientation ?? .upright)
            )

        Form {
            Section {
                Picker("Theme", selection: $settings.floaterTheme) {
                    ForEach(FloaterTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.inline)

                Picker("Display Style", selection: $settings.floaterSize) {
                    ForEach(FloaterSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.inline)

                Picker("Render Mode", selection: $settings.floaterRenderMode) {
                    ForEach(FloaterRenderMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.inline)

                LabeledContent("Header CPU") {
                    Picker("Header CPU", selection: $settings.floaterHeaderCPUDisplay) {
                        ForEach(FloaterHeaderCPUDisplay.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 220, alignment: .trailing)
                }
            } header: {
                Text("Floater Appearance")
            } footer: {
                Text("Slay keeps full effects. Super Slay pushes extra effects for high-end machines. Lame removes heavy repeat effects for the lowest CPU. Header CPU updates the floater bar with this app's current CPU usage.")
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Floater Visuals")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LabeledContent("Avatar Pack") {
                            Picker(
                                "Avatar Pack",
                                selection: Binding(
                                    get: { settings.selectedVisualPackID },
                                    set: { settings.selectVisualPack($0, catalog: visualCatalog) }
                                )
                            ) {
                                ForEach(visualCatalog.packs, id: \.id) { pack in
                                    Text(pack.displayName).tag(pack.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 220, alignment: .trailing)
                        }

                        LabeledContent("Avatar") {
                            Picker("Avatar", selection: $settings.selectedAvatarID) {
                                ForEach(selectedPack.avatars, id: \.id) { avatar in
                                    Text(avatar.displayName).tag(avatar.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 220, alignment: .trailing)
                        }

                        LabeledContent("Effect Style") {
                            Picker("Effect Style", selection: $settings.selectedEffectPresetID) {
                                ForEach(selectedPack.effectPresets, id: \.id) { preset in
                                    Text(preset.displayName).tag(preset.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 220, alignment: .trailing)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Import Avatar")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LabeledContent("Avatar name") {
                            TextField("Required", text: $importAvatarName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 220)
                        }

                        LabeledContent("Source") {
                            Menu {
                                Button("Import Image...") {
                                    openAvatarImportPanel(for: selectedPack)
                                }

                                Button("Paste Image") {
                                    importAvatarFromPasteboard(into: selectedPack)
                                }
                            } label: {
                                Text(isImportingAvatar ? "Importing..." : "Choose Source")
                                    .frame(width: 220, alignment: .leading)
                            }
                            .disabled(isImportingAvatar || !canImportAvatar)
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Manage Uploaded Avatar")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !hasCustomPacks {
                            Text("No custom pack yet. Import an avatar to create Personal pack.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let resolvedManagedPack {
                            LabeledContent("Manage Pack") {
                                Picker(
                                    "Manage Pack",
                                    selection: Binding(
                                        get: { resolvedManagedPack.id },
                                        set: { newValue in
                                            managedPackID = newValue
                                            syncManagedAvatarSelection(
                                                customPacks: customPacks,
                                                selectedPackID: settings.selectedVisualPackID
                                            )
                                        }
                                    )
                                ) {
                                    ForEach(customPacks) { pack in
                                        Text(pack.displayName).tag(pack.id)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 220, alignment: .trailing)
                            }

                            if manageableAvatars.isEmpty {
                                Text("This pack has no uploaded avatars yet.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if let selectedManagedAvatar {
                                LabeledContent("Uploaded Avatar") {
                                    Picker(
                                        "Uploaded Avatar",
                                        selection: Binding(
                                            get: { selectedManagedAvatar.id },
                                            set: { newValue in
                                                managedAvatarID = newValue
                                                managedAvatarName = manageableAvatars.first(where: { $0.id == newValue })?.displayName ?? ""
                                                managedAvatarOrientation = manageableAvatars.first(where: { $0.id == newValue })?.orientation ?? .upright
                                            }
                                        )
                                    ) {
                                        ForEach(manageableAvatars) { avatar in
                                            Text(avatar.displayName).tag(avatar.id)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(width: 220, alignment: .trailing)
                                }

                                LabeledContent("Display name") {
                                    TextField("Display name", text: $managedAvatarName)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 220)
                                }

                                LabeledContent("Direction") {
                                    Picker("Direction", selection: $managedAvatarOrientation) {
                                        ForEach(FloaterAvatarOrientation.allCases, id: \.self) { orientation in
                                            Text(orientation.displayName).tag(orientation)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                    .frame(width: 220, alignment: .trailing)
                                }

                                LabeledContent("Actions") {
                                    Menu {
                                        Button("Save Avatar") {
                                            saveManagedAvatar(
                                                avatarID: selectedManagedAvatar.id,
                                                pack: resolvedManagedPack
                                            )
                                        }
                                        .disabled(isManagingAvatar || !canSaveManagedAvatar)

                                        Divider()

                                        Button("Delete Avatar", role: .destructive) {
                                            pendingDeleteAvatarID = selectedManagedAvatar.id
                                            pendingDeleteAvatarName = selectedManagedAvatar.displayName
                                        }
                                        .disabled(isManagingAvatar)
                                    } label: {
                                        Text(isManagingAvatar ? "Working..." : "Choose Action")
                                            .frame(width: 220, alignment: .leading)
                                    }
                                    .disabled(isManagingAvatar)
                                }
                            } else {
                                Text("Pick an uploaded avatar to rename or delete it.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pack Folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LabeledContent("Actions") {
                            Menu {
                                Button("Reveal Packs Folder") {
                                    visualCatalog.revealPacksDirectory()
                                    setVisualCatalogMessage("Opened \(visualCatalog.packsDirectoryPath).", level: .good)
                                }

                                Button("Reload Packs") {
                                    visualCatalog.reload()
                                    settings.normalizeVisualSelection(catalog: visualCatalog)
                                    setVisualCatalogMessage(visualCatalog.lastReloadMessage ?? "Reloaded visual packs.", level: .good)
                                }
                            } label: {
                                Text("Choose Action")
                                    .frame(width: 220, alignment: .leading)
                            }
                        }

                        if let sourceURL = selectedPack.sourceURL {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected pack path")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(sourceURL.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }

                    if !visualCatalogMessage.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(visualCatalogLevel.tint)
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)

                            Text(visualCatalogMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Visual Packs")
            } footer: {
                Text("Drop custom packs into ~/.floatify/packs. Import Image and Paste Image auto-run the sprite extractor. Built-in pack imports land in Personal.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Idle timeout")
                    Spacer()
                    TextField("", value: $settings.idleTimeout, formatter: timeoutFormatter)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    Text("seconds")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Status Transitions")
            } footer: {
                Text("Delay before running transitions to idle, and idle to complete.")
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 16) {
                    SetupHealthRow(title: "CLI command", item: health.cli) {
                        HStack {
                            Button(health.cli.level == .good ? "Reinstall" : "Install") {
                                installCLI()
                            }

                            Button("Reveal") {
                                revealCLI()
                            }
                        }
                    }

                    Divider()

                    SetupHealthRow(title: HookConfiguration.claude.title, item: health.claudeHooks) {
                        HStack {
                            Button("Open File") {
                                openHookFile(.claude)
                            }

                            Button("Copy Example") {
                                copyHookExample(.claude)
                            }
                        }
                    }

                    Divider()

                    SetupHealthRow(title: HookConfiguration.codex.title, item: health.codexHooks) {
                        HStack {
                            Button("Open File") {
                                openHookFile(.codex)
                            }

                            Button("Copy Example") {
                                copyHookExample(.codex)
                            }
                        }
                    }

                    Divider()

                    SetupHealthRow(title: "App location", item: health.appLocation) {
                        HStack {
                            Button("Reveal App") {
                                NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                            }
                        }
                    }

                    Divider()

                    SetupHealthRow(title: "Launch at login", item: health.launchAtLogin) {
                        HStack {
                            Button(health.launchAtLoginStatus == .enabled ? "Disable" : "Enable") {
                                setLaunchAtLogin(enabled: health.launchAtLoginStatus != .enabled)
                            }
                            .disabled(health.launchAtLoginStatus == .notFound)

                            Button("Refresh") {
                                refreshHealth()
                                setActionMessage("Refreshed setup health.", level: .good)
                            }
                        }
                    }

                    if !actionMessage.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(actionLevel.tint)
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)

                            Text(actionMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Setup & Health")
            } footer: {
                Text("Use these checks to finish first-time setup and repair common installation drift.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .onAppear {
            settings.normalizeVisualSelection(catalog: visualCatalog)
            syncManagedAvatarSelection(
                customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                selectedPackID: settings.selectedVisualPackID
            )
            refreshHealth()
        }
        .onChange(of: settings.selectedVisualPackID) { _, _ in
            syncManagedAvatarSelection(
                customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                selectedPackID: settings.selectedVisualPackID
            )
        }
        .onChange(of: visualCatalog.packs) { _, packs in
            syncManagedAvatarSelection(
                customPacks: packs.filter { !$0.isBuiltIn },
                selectedPackID: settings.selectedVisualPackID
            )
        }
        .alert("Delete uploaded avatar?", isPresented: deleteAvatarAlertBinding) {
            Button("Delete", role: .destructive) {
                confirmDeleteManagedAvatar()
            }
            Button("Cancel", role: .cancel) {
                clearPendingDeleteAvatar()
            }
        } message: {
            Text("Delete '\(pendingDeleteAvatarName)' from this pack?")
        }
    }

    private func refreshHealth() {
        health = SetupHealthSnapshot.capture()
    }

    private func installCLI() {
        guard let sourceURL = Bundle.main.url(forResource: "floatify", withExtension: nil) else {
            setActionMessage("Bundled floatify CLI not found inside the app bundle.", level: .error)
            return
        }

        let destinationURL = URL(fileURLWithPath: "/usr/local/bin/floatify")
        let parentDirectory = destinationURL.deletingLastPathComponent()
        let fileManager = FileManager.default

        do {
            try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true, attributes: nil)

            if fileManager.fileExists(atPath: destinationURL.path) ||
                (try? fileManager.destinationOfSymbolicLink(atPath: destinationURL.path)) != nil {
                try? fileManager.removeItem(at: destinationURL)
            }

            try fileManager.createSymbolicLink(at: destinationURL, withDestinationURL: sourceURL)
            UserDefaults.standard.set(true, forKey: FloatifySettings.cliSymlinkInstalledKey)
            setActionMessage("Installed /usr/local/bin/floatify.", level: .good)
        } catch {
            setActionMessage("Failed to install CLI symlink: \(error.localizedDescription)", level: .error)
        }

        refreshHealth()
    }

    private func revealCLI() {
        let cliURL = URL(fileURLWithPath: "/usr/local/bin/floatify")
        if FileManager.default.fileExists(atPath: cliURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([cliURL])
            return
        }

        NSWorkspace.shared.open(cliURL.deletingLastPathComponent())
    }

    private func openHookFile(_ configuration: HookConfiguration) {
        let fileManager = FileManager.default
        let fileURL = configuration.fileURL

        do {
            try fileManager.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

            if !fileManager.fileExists(atPath: fileURL.path) {
                try configuration.defaultContents.write(to: fileURL, atomically: true, encoding: .utf8)
            }

            NSWorkspace.shared.open(fileURL)
            setActionMessage("Opened \(configuration.title.lowercased()).", level: .good)
        } catch {
            setActionMessage("Failed to open \(configuration.title.lowercased()): \(error.localizedDescription)", level: .error)
        }

        refreshHealth()
    }

    private func copyHookExample(_ configuration: HookConfiguration) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(configuration.defaultContents, forType: .string)
        setActionMessage("Copied \(configuration.title.lowercased()) example JSON.", level: .good)
    }

    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            refreshHealth()

            if enabled, health.launchAtLoginStatus == .requiresApproval {
                setActionMessage("Launch at login was requested. Approve Floatify in System Settings -> General -> Login Items.", level: .warning)
            } else {
                setActionMessage(enabled ? "Launch at login enabled." : "Launch at login disabled.", level: .good)
            }
        } catch {
            refreshHealth()
            setActionMessage("Failed to update launch at login: \(error.localizedDescription)", level: .error)
        }
    }

    private func setActionMessage(_ message: String, level: SetupHealthLevel) {
        actionMessage = message
        actionLevel = level
    }

    private func setVisualCatalogMessage(_ message: String, level: SetupHealthLevel) {
        visualCatalogMessage = message
        visualCatalogLevel = level
    }

    private func openAvatarImportPanel(for pack: FloaterVisualPack) {
        guard validateAvatarNameInput() else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            importAvatar(from: url, cleanupURL: nil, requestedPack: pack)
        }
    }

    private func importAvatarFromPasteboard(into pack: FloaterVisualPack) {
        guard validateAvatarNameInput() else { return }

        do {
            let temporaryURL = try writePasteboardImageToTemporaryFile()
            importAvatar(from: temporaryURL, cleanupURL: temporaryURL, requestedPack: pack)
        } catch {
            setVisualCatalogMessage("Paste image failed: \(error.localizedDescription)", level: .error)
        }
    }

    private func importAvatar(from sourceURL: URL, cleanupURL: URL?, requestedPack: FloaterVisualPack) {
        guard validateAvatarNameInput() else { return }

        isImportingAvatar = true
        setVisualCatalogMessage("Importing avatar sprite...", level: .good)

        let requestedPackID = requestedPack.id
        let requestedPackName = requestedPack.displayName
        let requestedPackDirectoryURL = requestedPack.sourceURL
        let requestedPackIsBuiltIn = requestedPack.isBuiltIn
        let packsDirectoryURL = visualCatalog.packsDirectoryURL
        let displayName = trimmedImportAvatarName

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                if let cleanupURL {
                    try? FileManager.default.removeItem(at: cleanupURL)
                }
            }

            do {
                let result = try FloaterVisualCatalog.importAvatarAsset(
                    from: sourceURL,
                    preferredPackID: requestedPackID,
                    preferredPackName: requestedPackName,
                    preferredPackDirectoryURL: requestedPackDirectoryURL,
                    preferredPackIsBuiltIn: requestedPackIsBuiltIn,
                    packsDirectoryURL: packsDirectoryURL,
                    displayName: displayName
                )

                DispatchQueue.main.async {
                    visualCatalog.reload()
                    settings.selectVisualPack(result.packID, catalog: visualCatalog)
                    settings.selectedAvatarID = result.avatarID
                    importAvatarName = ""
                    isImportingAvatar = false
                    managedPackID = result.packID
                    managedAvatarID = result.avatarID
                    syncManagedAvatarSelection(
                        customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                        selectedPackID: settings.selectedVisualPackID
                    )

                    let destinationNote = result.packID == requestedPackID
                        ? result.packName
                        : "\(result.packName) (fallback from \(requestedPackName))"
                    setVisualCatalogMessage(
                        "Imported \(result.avatarName) to \(destinationNote). \(result.frameCount) frame(s) ready.",
                        level: .good
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    isImportingAvatar = false
                    setVisualCatalogMessage("Avatar import failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func writePasteboardImageToTemporaryFile() throws -> URL {
        let pasteboard = NSPasteboard.general
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("floatify-avatar-\(UUID().uuidString).png")
            try png.write(to: url, options: .atomic)
            return url
        }

        throw AvatarImportUIError.pasteboardImageMissing
    }

    private var trimmedImportAvatarName: String {
        importAvatarName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validateAvatarNameInput() -> Bool {
        guard !trimmedImportAvatarName.isEmpty else {
            setVisualCatalogMessage("Avatar name is required before import.", level: .warning)
            return false
        }
        return true
    }

    private var trimmedManagedAvatarName: String {
        managedAvatarName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var deleteAvatarAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteAvatarID != nil },
            set: { isPresented in
                if !isPresented {
                    clearPendingDeleteAvatar()
                }
            }
        )
    }

    private func resolvedManagedPack(
        customPacks: [FloaterVisualPack],
        selectedPackID: String
    ) -> FloaterVisualPack? {
        if let explicit = customPacks.first(where: { $0.id == managedPackID }) {
            return explicit
        }

        if let selected = customPacks.first(where: { $0.id == selectedPackID }) {
            return selected
        }

        if let personal = customPacks.first(where: { $0.id == FloaterVisualConstants.personalPackID }) {
            return personal
        }

        return customPacks.first
    }

    private func manageableAvatars(in pack: FloaterVisualPack?) -> [FloaterAvatarDefinition] {
        guard let pack else { return [] }
        return pack.avatars.filter { !$0.isAutomatic }
    }

    private func selectedManagedAvatar(in pack: FloaterVisualPack?) -> FloaterAvatarDefinition? {
        let avatars = manageableAvatars(in: pack)
        return avatars.first(where: { $0.id == managedAvatarID }) ?? avatars.first
    }

    private func syncManagedAvatarSelection(
        customPacks: [FloaterVisualPack],
        selectedPackID: String
    ) {
        guard let pack = resolvedManagedPack(customPacks: customPacks, selectedPackID: selectedPackID) else {
            managedPackID = FloaterVisualConstants.personalPackID
            managedAvatarID = ""
            managedAvatarName = ""
            managedAvatarOrientation = .upright
            return
        }

        managedPackID = pack.id

        let avatars = manageableAvatars(in: pack)
        let avatar = avatars.first(where: { $0.id == managedAvatarID }) ?? avatars.first
        managedAvatarID = avatar?.id ?? ""
        managedAvatarName = avatar?.displayName ?? ""
        managedAvatarOrientation = avatar?.orientation ?? .upright
    }

    private func saveManagedAvatar(avatarID: String, pack: FloaterVisualPack) {
        guard let packDirectoryURL = pack.sourceURL else {
            setVisualCatalogMessage("This pack cannot be edited.", level: .warning)
            return
        }

        let nextName = trimmedManagedAvatarName
        let nextOrientation = managedAvatarOrientation
        guard !nextName.isEmpty else {
            setVisualCatalogMessage("Avatar display name is required.", level: .warning)
            return
        }

        isManagingAvatar = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try FloaterVisualCatalog.updateAvatarAsset(
                    avatarID: avatarID,
                    in: packDirectoryURL,
                    displayName: nextName,
                    orientation: nextOrientation
                )

                DispatchQueue.main.async {
                    visualCatalog.reload()
                    managedPackID = result.packID
                    if let avatarID = result.avatarID {
                        managedAvatarID = avatarID
                    }
                    settings.normalizeVisualSelection(catalog: visualCatalog)
                    syncManagedAvatarSelection(
                        customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                        selectedPackID: settings.selectedVisualPackID
                    )
                    isManagingAvatar = false
                    setVisualCatalogMessage("Saved avatar \(result.avatarName ?? nextName).", level: .good)
                }
            } catch {
                DispatchQueue.main.async {
                    isManagingAvatar = false
                    setVisualCatalogMessage("Save avatar failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func confirmDeleteManagedAvatar() {
        guard
            let avatarID = pendingDeleteAvatarID,
            let packDirectoryURL = visualCatalog.resolvedPack(id: managedPackID).sourceURL
        else {
            clearPendingDeleteAvatar()
            return
        }

        let shouldFallbackToBuiltIn =
            settings.selectedVisualPackID == managedPackID
            && settings.selectedAvatarID == avatarID

        clearPendingDeleteAvatar()
        isManagingAvatar = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try FloaterVisualCatalog.deleteAvatarAsset(
                    avatarID: avatarID,
                    in: packDirectoryURL
                )

                DispatchQueue.main.async {
                    visualCatalog.reload()
                    managedPackID = result.packID
                    managedAvatarID = result.avatarID ?? ""
                    if shouldFallbackToBuiltIn {
                        settings.selectVisualPack(FloaterVisualConstants.builtInPackID, catalog: visualCatalog)
                    } else {
                        settings.normalizeVisualSelection(catalog: visualCatalog)
                    }
                    syncManagedAvatarSelection(
                        customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                        selectedPackID: settings.selectedVisualPackID
                    )
                    isManagingAvatar = false
                    setVisualCatalogMessage("Deleted avatar \(result.avatarName ?? avatarID).", level: .good)
                }
            } catch {
                DispatchQueue.main.async {
                    isManagingAvatar = false
                    setVisualCatalogMessage("Delete failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func clearPendingDeleteAvatar() {
        pendingDeleteAvatarID = nil
        pendingDeleteAvatarName = ""
    }
}

private enum AvatarImportUIError: LocalizedError {
    case pasteboardImageMissing

    var errorDescription: String? {
        switch self {
        case .pasteboardImageMissing:
            return "Pasteboard does not contain an image."
        }
    }
}

#Preview {
    SettingsView()
        .environment(FloatifySettings.shared)
        .environment(FloaterVisualCatalog.shared)
}
