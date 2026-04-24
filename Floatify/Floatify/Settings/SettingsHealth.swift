import AppKit
import ServiceManagement
import SwiftUI

enum SetupHealthLevel {
    case good
    case warning
    case error

    var label: String {
        switch self {
        case .good: return "Ready"
        case .warning: return "Attention"
        case .error: return "Blocked"
        }
    }

    var tint: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .error: return .red
        }
    }

    var symbolName: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

struct SetupHealthItem {
    let level: SetupHealthLevel
    let summary: String
    let detail: String
}

enum HookConfiguration {
    case claude
    case codex

    var title: String {
        switch self {
        case .claude: return "Claude Code hooks"
        case .codex: return "Codex hooks"
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
            return ["/usr/local/bin/floatify --status complete"]
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

struct SetupHealthSnapshot {
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
            return SetupHealthItem(level: .good, summary: "Installed", detail: cliPath)
        }

        return SetupHealthItem(level: .warning, summary: "Present but not executable", detail: cliPath)
    }

    private static func hookHealth(for configuration: HookConfiguration) -> SetupHealthItem {
        let url = configuration.fileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            return SetupHealthItem(level: .warning, summary: "Missing file", detail: url.path)
        }

        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return SetupHealthItem(level: .error, summary: "Unreadable", detail: url.path)
        }

        if configuration.expectedFragments.allSatisfy(contents.contains) {
            return SetupHealthItem(level: .good, summary: "Configured", detail: url.path)
        }

        if contents.contains("floatify") {
            return SetupHealthItem(level: .warning, summary: "Partial config detected", detail: url.path)
        }

        return SetupHealthItem(level: .warning, summary: "Hooks not detected", detail: url.path)
    }

    private static func appLocationHealth() -> SetupHealthItem {
        let bundlePath = Bundle.main.bundleURL.path
        if bundlePath.hasPrefix("/Applications/") {
            return SetupHealthItem(level: .good, summary: "Installed in /Applications", detail: bundlePath)
        }

        return SetupHealthItem(level: .warning, summary: "Not in /Applications", detail: bundlePath)
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

@Observable
final class SettingsHealthModel {
    var snapshot: SetupHealthSnapshot

    init() {
        self.snapshot = .capture()
    }

    func refresh() {
        snapshot = .capture()
    }
}
