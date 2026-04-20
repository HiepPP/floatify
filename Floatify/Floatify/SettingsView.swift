import AppKit
import ServiceManagement
import SwiftUI

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

    @State private var health = SetupHealthSnapshot.capture()
    @State private var actionMessage = ""
    @State private var actionLevel: SetupHealthLevel = .good

    private let timeoutFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.allowsFloats = false
        f.minimum = 1
        f.maximum = 3600
        return f
    }()

    var body: some View {
        @Bindable var settings = settings

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
            } header: {
                Text("Floater Appearance")
            } footer: {
                Text("Slay keeps full effects. Lame removes heavy repeat effects for the lowest CPU.")
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
        .onAppear(perform: refreshHealth)
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
}

#Preview {
    SettingsView()
        .environment(FloatifySettings.shared)
}
