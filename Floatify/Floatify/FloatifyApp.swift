import AppKit
import SwiftUI

@main
struct FloatifyApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let settings = FloatifySettings.shared
    private let visualCatalog = FloaterVisualCatalog.shared

    var body: some Scene {
        MenuBarExtra("🦆") {
            FloatifyMenuBarContent()
        }

        Settings {
            SettingsView()
                .environment(settings)
                .environment(visualCatalog)
        }
    }
}

private struct FloatifyMenuBarContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings...") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Test Notification") {
            for corner in Corner.allCases {
                FloatNotificationManager.shared.show(
                    message: "Test: \(corner.rawValue)",
                    corner: corner,
                    duration: 5,
                    project: "Test"
                )
            }
        }

        Button("Arrange") {
            FloatNotificationManager.shared.arrangePersistentStatuses()
        }

        Divider()

        Button("Quit Floatify") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
