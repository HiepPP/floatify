import AppKit
import ServiceManagement
import SwiftUI

struct GeneralTab: View {
    @Environment(FloatifySettings.self) private var settings
    @Environment(SettingsHealthModel.self) private var health

    @State private var message = ""
    @State private var messageLevel: SetupHealthLevel = .good

    private let timeoutFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.allowsFloats = false
        f.minimum = 1
        f.maximum = 3600
        return f
    }()

    var body: some View {
        @Bindable var settings = settings
        let snapshot = health.snapshot

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TabHeader(
                    title: "General",
                    subtitle: "Behavior, startup, and app location.",
                    symbol: "gearshape.fill"
                )

                Form {
                    Section {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Idle timeout")
                                Text("Delay before transitioning to idle, and idle to complete.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            TextField("", value: $settings.idleTimeout, formatter: timeoutFormatter)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                            Text("seconds")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    } header: {
                        SectionHeader("Status Transitions")
                    }

                    Section {
                        HealthRow(
                            title: "App location",
                            symbol: "app.badge",
                            item: snapshot.appLocation
                        ) {
                            Button {
                                NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
                            } label: {
                                Label("Reveal App", systemImage: "folder")
                            }
                            .buttonStyle(.bordered)
                        }

                        Divider()

                        HealthRow(
                            title: "Launch at login",
                            symbol: "power",
                            item: snapshot.launchAtLogin
                        ) {
                            Button {
                                setLaunchAtLogin(enabled: snapshot.launchAtLoginStatus != .enabled)
                            } label: {
                                Label(
                                    snapshot.launchAtLoginStatus == .enabled ? "Disable" : "Enable",
                                    systemImage: snapshot.launchAtLoginStatus == .enabled ? "pause.circle" : "play.circle"
                                )
                            }
                            .buttonStyle(.bordered)
                            .disabled(snapshot.launchAtLoginStatus == .notFound)
                        }
                    } header: {
                        SectionHeader("Install & Startup")
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
                                setMessage("Refreshed setup health.", level: .good)
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

    private func setLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            health.refresh()

            if enabled, health.snapshot.launchAtLoginStatus == .requiresApproval {
                setMessage("Launch at login was requested. Approve Floatify in System Settings -> General -> Login Items.", level: .warning)
            } else {
                setMessage(enabled ? "Launch at login enabled." : "Launch at login disabled.", level: .good)
            }
        } catch {
            health.refresh()
            setMessage("Failed to update launch at login: \(error.localizedDescription)", level: .error)
        }
    }
}
