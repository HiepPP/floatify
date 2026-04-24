import AppKit
import SwiftUI

struct HooksCLITab: View {
    @Environment(SettingsHealthModel.self) private var health

    @State private var message = ""
    @State private var messageLevel: SetupHealthLevel = .good

    var body: some View {
        let snapshot = health.snapshot

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TabHeader(
                    title: "Hooks & CLI",
                    subtitle: "Install the CLI and wire up Claude Code and Codex hooks.",
                    symbol: "terminal.fill"
                )

                Form {
                    Section {
                        HealthRow(
                            title: "CLI command",
                            symbol: "apple.terminal",
                            item: snapshot.cli
                        ) {
                            Button {
                                installCLI()
                            } label: {
                                Label(snapshot.cli.level == .good ? "Reinstall" : "Install", systemImage: "arrow.down.circle")
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                revealCLI()
                            } label: {
                                Label("Reveal", systemImage: "folder")
                            }
                            .buttonStyle(.bordered)
                        }
                    } header: {
                        SectionHeader("Command Line Tool")
                    } footer: {
                        Text("Installs a symlink at /usr/local/bin/floatify pointing to the app bundle.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        HealthRow(
                            title: HookConfiguration.claude.title,
                            symbol: "bubble.left.and.text.bubble.right",
                            item: snapshot.claudeHooks
                        ) {
                            Button {
                                openHookFile(.claude)
                            } label: {
                                Label("Open File", systemImage: "doc.text")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                copyHookExample(.claude)
                            } label: {
                                Label("Copy Example", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }

                        Divider()

                        HealthRow(
                            title: HookConfiguration.codex.title,
                            symbol: "chevron.left.forwardslash.chevron.right",
                            item: snapshot.codexHooks
                        ) {
                            Button {
                                openHookFile(.codex)
                            } label: {
                                Label("Open File", systemImage: "doc.text")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                copyHookExample(.codex)
                            } label: {
                                Label("Copy Example", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                        }
                    } header: {
                        SectionHeader("Hooks")
                    } footer: {
                        Text("Open File creates the config with the default hooks if missing. Copy Example puts the JSON on the clipboard.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        InlineMessage(message: message, level: messageLevel)
                            .task(id: message) {
                                guard !message.isEmpty else { return }
                                try? await Task.sleep(nanoseconds: 4_000_000_000)
                                withAnimation { message = "" }
                            }

                        HStack {
                            Spacer()
                            Button {
                                health.refresh()
                                setMessage("Refreshed status.", level: .good)
                            } label: {
                                Label("Refresh Status", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
            .padding(24)
        }
    }

    private func setMessage(_ text: String, level: SetupHealthLevel) {
        withAnimation { message = text; messageLevel = level }
    }

    private func installCLI() {
        guard let sourceURL = Bundle.main.url(forResource: "floatify", withExtension: nil) else {
            setMessage("Bundled floatify CLI not found inside the app bundle.", level: .error)
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
            setMessage("Installed /usr/local/bin/floatify.", level: .good)
        } catch {
            setMessage("Failed to install CLI symlink: \(error.localizedDescription)", level: .error)
        }

        health.refresh()
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
            setMessage("Opened \(configuration.title.lowercased()).", level: .good)
        } catch {
            setMessage("Failed to open \(configuration.title.lowercased()): \(error.localizedDescription)", level: .error)
        }

        health.refresh()
    }

    private func copyHookExample(_ configuration: HookConfiguration) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(configuration.defaultContents, forType: .string)
        setMessage("Copied \(configuration.title.lowercased()) example JSON.", level: .good)
    }
}
