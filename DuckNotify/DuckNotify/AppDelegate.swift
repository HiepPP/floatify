import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupDistributedNotification()
        installCLIToolIfNeeded()
    }

    // MARK: - Menu Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🦆"
        }

        let menu = NSMenu()
        let testItem = NSMenuItem(title: "Test Notification", action: #selector(testNotification), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit DuckNotify", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func testNotification() {
        DuckNotificationManager.shared.show(message: "Test notification! 🦆", corner: .bottomRight, duration: 5)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Distributed Notification

    private let notificationName = "com.ducknotify.newNotification"

    private func setupDistributedNotification() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleNotification(_:)),
            name: NSNotification.Name(notificationName),
            object: nil
        )
    }

    @objc private func handleNotification(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let data = try? JSONSerialization.data(withJSONObject: userInfo),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return }

        let message = json["message"] as? String ?? "Task complete!"
        let cornerStr = json["corner"] as? String ?? "bottomRight"
        let corner: Corner = cornerStr == "bottomLeft" ? .bottomLeft : .bottomRight
        let duration = json["duration"] as? TimeInterval ?? 6.0

        DuckNotificationManager.shared.show(message: message, corner: corner, duration: duration)
    }

    // MARK: - CLI Symlink Installation

    private func installCLIToolIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "CLISymlinkInstalled") else { return }

        let alert = NSAlert()
        alert.messageText = "Install duck-notify CLI?"
        alert.informativeText = "DuckNotify needs to create a symlink at /usr/local/bin/duck-notify so Claude Code can trigger notifications. This requires administrator privileges."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Skip")

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let src = Bundle.main.url(forResource: "duck-notify", withExtension: nil)
        guard let srcURL = src else {
            print("duck-notify binary not found in app bundle")
            return
        }

        let dest = URL(fileURLWithPath: "/usr/local/bin/duck-notify")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: srcURL)
            defaults.set(true, forKey: "CLISymlinkInstalled")
            print("Installed duck-notify to /usr/local/bin/")
        } catch {
            let permAlert = NSAlert()
            permAlert.messageText = "Permission denied"
            permAlert.informativeText = "Could not create /usr/local/bin/duck-notify. Run: sudo ln -s \(srcURL.path) /usr/local/bin/duck-notify"
            permAlert.alertStyle = .warning
            permAlert.runModal()
        }
    }
}
