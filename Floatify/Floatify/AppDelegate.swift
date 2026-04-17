import AppKit
import SwiftUI

struct SessionDescriptor: Equatable {
    let id: String
    let project: String
    let projectPath: String?
    let isRunning: Bool
    let isTaskStateKnown: Bool
    let lastActivity: Date
    let modifiedFilesCount: Int
}

private struct ProjectContext: Equatable {
    let name: String
    let path: String?
}

private func commandOutput(executablePath: String, arguments: [String]) -> String? {
    let process = Process()
    let outputPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executablePath)
    process.arguments = arguments
    process.standardOutput = outputPipe
    process.standardError = Pipe()

    do {
        try process.run()
    } catch {
        return nil
    }

    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        return nil
    }

    return String(data: data, encoding: .utf8)
}

private func projectName(for path: String) -> String {
    let name = URL(fileURLWithPath: path).lastPathComponent
    return name.isEmpty ? path : name
}

final class ClaudeSessionMonitor {
    var onSessionsChange: (([SessionDescriptor]) -> Void)?

    private let queue = DispatchQueue(label: "com.floatify.claude-sessions")
    private var timer: DispatchSourceTimer?
    private var lastPublished: [SessionDescriptor] = []
    private var projectCache: [Int: ProjectContext] = [:]
    private var lastActivityCache: [Int: Date] = [:]
    private var modifiedFilesCache: [Int: Int] = [:]

    func start() {
        stop()
        publish(force: true)

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2.0, repeating: 2.0)
        timer.setEventHandler { [weak self] in
            self?.publish(force: false)
        }
        self.timer = timer
        timer.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func publish(force: Bool) {
        let sessions = detectSessions()
        guard force || sessions != lastPublished else { return }
        lastPublished = sessions

        DispatchQueue.main.async { [weak self] in
            self?.onSessionsChange?(sessions)
        }
    }

    private func detectSessions() -> [SessionDescriptor] {
        guard let output = commandOutput(executablePath: "/bin/ps", arguments: ["-Ao", "pid=,ppid=,command="]) else {
            return []
        }

        var activePIDs = Set<Int>()
        var sessions: [SessionDescriptor] = []

        for rawLine in output.split(separator: "\n") {
            let parts = rawLine.split(maxSplits: 2, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard parts.count == 3, let pid = Int(parts[0]) else {
                continue
            }

            let command = String(parts[2])
            guard command.hasPrefix("claude --ide") else {
                continue
            }

            activePIDs.insert(pid)
            let projectContext = cachedProjectContext(for: pid, fallbackProject: "Claude Code")

            // Get or create last activity timestamp
            let lastActivity = lastActivityCache[pid] ?? Date()
            lastActivityCache[pid] = lastActivity

            // Count modified files in git repo
            let modifiedCount = countModifiedFiles(for: projectContext.path)
            modifiedFilesCache[pid] = modifiedCount

            sessions.append(
                SessionDescriptor(
                    id: "claude:\(pid)",
                    project: projectContext.name,
                    projectPath: projectContext.path,
                    isRunning: false,
                    isTaskStateKnown: false,
                    lastActivity: lastActivity,
                    modifiedFilesCount: modifiedCount
                )
            )
        }

        projectCache = projectCache.filter { activePIDs.contains($0.key) }
        lastActivityCache = lastActivityCache.filter { activePIDs.contains($0.key) }
        modifiedFilesCache = modifiedFilesCache.filter { activePIDs.contains($0.key) }
        return sessions.sorted { $0.id < $1.id }
    }

    private func cachedProjectContext(for pid: Int, fallbackProject: String) -> ProjectContext {
        if let cached = projectCache[pid] {
            return cached
        }

        let projectPath = lookupProjectPath(for: pid)
        let context = ProjectContext(
            name: projectPath.map(projectName(for:)) ?? fallbackProject,
            path: projectPath
        )
        projectCache[pid] = context
        return context
    }

    private func lookupProjectPath(for pid: Int) -> String? {
        guard let output = commandOutput(executablePath: "/usr/sbin/lsof", arguments: ["-a", "-d", "cwd", "-p", "\(pid)"]) else {
            return nil
        }

        for rawLine in output.split(separator: "\n").dropFirst() {
            let parts = rawLine.split(maxSplits: 8, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard let pathField = parts.last else { continue }
            return String(pathField)
        }

        return nil
    }

    private func countModifiedFiles(for projectPath: String?) -> Int {
        guard let path = projectPath else { return 0 }
        guard let output = commandOutput(executablePath: "/usr/bin/git", arguments: ["-C", path, "status", "--porcelain"]) else {
            return 0
        }
        return output.split(separator: "\n").count
    }
}

final class CodexActivityMonitor {
    var onSessionsChange: (([SessionDescriptor]) -> Void)?

    private struct ActivityState {
        let isRunning: Bool
        let hasTaskState: Bool
        let lastActivity: Date
    }

    private let queue = DispatchQueue(label: "com.floatify.codex-activity")
    private var timer: DispatchSourceTimer?
    private var lastPublished: [SessionDescriptor] = []
    private var projectCache: [Int: ProjectContext] = [:]
    private var sessionLogPathCache: [Int: String] = [:]
    private var modifiedFilesCache: [Int: Int] = [:]
    private let sessionTailByteCount = 32 * 1024
    private let timestampFormatterWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func start() {
        stop()
        publishSessions(force: true)

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1.5, repeating: 1.5)
        timer.setEventHandler { [weak self] in
            self?.publishSessions(force: false)
        }
        self.timer = timer
        timer.resume()
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func publishSessions(force: Bool) {
        let sessions = detectCodexSessions()
        guard force || sessions != lastPublished else { return }
        lastPublished = sessions

        DispatchQueue.main.async { [weak self] in
            self?.onSessionsChange?(sessions)
        }
    }

    private func detectCodexSessions() -> [SessionDescriptor] {
        guard let output = commandOutput(executablePath: "/bin/ps", arguments: ["-Aww", "-o", "pid=,ppid=,command="]) else {
            return []
        }

        var activeNodePIDs = Set<Int>()
        var vendorPIDByNodePID: [Int: Int] = [:]

        for rawLine in output.split(separator: "\n") {
            let parts = rawLine.split(maxSplits: 2, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard parts.count == 3,
                  let pid = Int(parts[0]),
                  let ppid = Int(parts[1]) else {
                continue
            }

            let command = String(parts[2])

            if command.contains("node /opt/homebrew/bin/codex") {
                activeNodePIDs.insert(pid)
                continue
            }

            guard command.contains("/codex/codex") else {
                continue
            }

            activeNodePIDs.insert(ppid)
            vendorPIDByNodePID[ppid] = pid
        }

        projectCache = projectCache.filter { activeNodePIDs.contains($0.key) }
        sessionLogPathCache = sessionLogPathCache.filter { activeNodePIDs.contains($0.key) }
        modifiedFilesCache = modifiedFilesCache.filter { activeNodePIDs.contains($0.key) }

        let now = Date()
        return activeNodePIDs.sorted().map { nodePID in
            let id = "codex:\(nodePID)"
            let projectContext = cachedProjectContext(for: nodePID, fallbackProject: "Codex")
            let activityState = cachedActivityState(for: nodePID, vendorPID: vendorPIDByNodePID[nodePID], fallbackDate: now)

            // Count modified files in git repo
            let modifiedCount = countModifiedFiles(for: projectContext.path)
            modifiedFilesCache[nodePID] = modifiedCount

            return SessionDescriptor(
                id: id,
                project: projectContext.name,
                projectPath: projectContext.path,
                isRunning: activityState.isRunning,
                isTaskStateKnown: activityState.hasTaskState,
                lastActivity: activityState.lastActivity,
                modifiedFilesCount: modifiedCount
            )
        }
    }

    private func cachedActivityState(for nodePID: Int, vendorPID: Int?, fallbackDate: Date) -> ActivityState {
        let sessionLogPath = cachedSessionLogPath(for: nodePID, vendorPID: vendorPID)
        return readActivityState(from: sessionLogPath, fallbackDate: fallbackDate)
    }

    private func cachedSessionLogPath(for nodePID: Int, vendorPID: Int?) -> String? {
        if let cached = sessionLogPathCache[nodePID],
           FileManager.default.fileExists(atPath: cached) {
            return cached
        }

        guard let vendorPID else { return nil }
        let sessionLogPath = lookupSessionLogPath(for: vendorPID)
        if let sessionLogPath {
            sessionLogPathCache[nodePID] = sessionLogPath
        }
        return sessionLogPath
    }

    private func lookupSessionLogPath(for pid: Int) -> String? {
        guard let output = commandOutput(executablePath: "/usr/sbin/lsof", arguments: ["-p", "\(pid)"]) else {
            return nil
        }

        let sessionRoot = "\(NSHomeDirectory())/.codex/sessions/"
        for rawLine in output.split(separator: "\n").dropFirst() {
            let parts = rawLine.split(maxSplits: 8, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard let pathField = parts.last else { continue }
            let path = String(pathField)
            guard path.hasPrefix(sessionRoot), path.hasSuffix(".jsonl") else {
                continue
            }
            return path
        }

        return nil
    }

    private func readActivityState(from sessionLogPath: String?, fallbackDate: Date) -> ActivityState {
        guard let sessionLogPath else {
            return ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
        }

        guard let fileHandle = FileHandle(forReadingAtPath: sessionLogPath) else {
            return ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
        }
        defer {
            fileHandle.closeFile()
        }

        let fileSize = (try? fileHandle.seekToEnd()) ?? 0
        let readSize = min(UInt64(sessionTailByteCount), fileSize)
        if readSize == 0 {
            return ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
        }

        try? fileHandle.seek(toOffset: fileSize - readSize)
        let data = fileHandle.readDataToEndOfFile()
        guard var contents = String(data: data, encoding: .utf8) else {
            return ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
        }

        if readSize < fileSize, let firstNewline = contents.firstIndex(of: "\n") {
            contents = String(contents[contents.index(after: firstNewline)...])
        }

        var fallbackActivityAt: Date?
        for rawLine in contents.split(separator: "\n").reversed() {
            guard let lineData = rawLine.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  let timestampRaw = json["timestamp"] as? String,
                  let timestamp = parsedTimestamp(from: timestampRaw),
                  let type = json["type"] as? String,
                  type == "event_msg",
                  let payload = json["payload"] as? [String: Any],
                  let eventType = payload["type"] as? String else {
                continue
            }

            if fallbackActivityAt == nil,
               eventType == "user_message" || eventType == "agent_message" {
                fallbackActivityAt = timestamp
            }

            if eventType == "task_complete" {
                return ActivityState(isRunning: false, hasTaskState: true, lastActivity: timestamp)
            }

            if eventType == "task_started" {
                return ActivityState(isRunning: true, hasTaskState: true, lastActivity: timestamp)
            }
        }

        let fileModificationDate = (try? FileManager.default.attributesOfItem(atPath: sessionLogPath))?[.modificationDate] as? Date
        return ActivityState(
            isRunning: false,
            hasTaskState: false,
            lastActivity: fallbackActivityAt ?? fileModificationDate ?? fallbackDate
        )
    }

    private func parsedTimestamp(from rawValue: String) -> Date? {
        if let parsed = timestampFormatterWithFractionalSeconds.date(from: rawValue) {
            return parsed
        }
        return timestampFormatter.date(from: rawValue)
    }

    private func cachedProjectContext(for pid: Int, fallbackProject: String) -> ProjectContext {
        if let cached = projectCache[pid] {
            return cached
        }

        let projectPath = lookupProjectPath(for: pid)
        let context = ProjectContext(
            name: projectPath.map(projectName(for:)) ?? fallbackProject,
            path: projectPath
        )
        projectCache[pid] = context
        return context
    }

    private func lookupProjectPath(for pid: Int) -> String? {
        guard let output = commandOutput(executablePath: "/usr/sbin/lsof", arguments: ["-a", "-d", "cwd", "-p", "\(pid)"]) else {
            return nil
        }

        for rawLine in output.split(separator: "\n").dropFirst() {
            let parts = rawLine.split(maxSplits: 8, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard let pathField = parts.last else { continue }
            return String(pathField)
        }

        return nil
    }

    private func countModifiedFiles(for projectPath: String?) -> Int {
        guard let path = projectPath else { return 0 }
        guard let output = commandOutput(executablePath: "/usr/bin/git", arguments: ["-C", path, "status", "--porcelain"]) else {
            return 0
        }
        return output.split(separator: "\n").count
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var pipeSource: DispatchSourceRead?
    private let pipePath = "/var/tmp/floatify.pipe"
    private let claudeSessionMonitor = ClaudeSessionMonitor()
    private let codexActivityMonitor = CodexActivityMonitor()
    private var claudeSessionsByID: [String: SessionDescriptor] = [:]
    private var codexSessionsByID: [String: SessionDescriptor] = [:]
    private var statusItemsByID: [String: PersistentStatusItem] = [:]
    private var idleTransitionTimers: [String: Timer] = [:]
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPipeListener()
        installCLIToolIfNeeded()
        SoundManager.shared.loadSounds()
        CursorTracker.shared.startTracking()
        setupPersistentStatusFloater()
    }

    func applicationWillTerminate(_ notification: Notification) {
        claudeSessionMonitor.stop()
        codexActivityMonitor.stop()
        idleTransitionTimers.values.forEach { $0.invalidate() }
    }

    private func setupPersistentStatusFloater() {
        claudeSessionMonitor.onSessionsChange = { [weak self] sessions in
            guard let self else { return }
            self.claudeSessionsByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
            self.refreshPersistentStatuses()
        }

        codexActivityMonitor.onSessionsChange = { [weak self] sessions in
            guard let self else { return }
            self.codexSessionsByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
            self.refreshPersistentStatuses()
        }

        claudeSessionMonitor.start()
        codexActivityMonitor.start()
        refreshPersistentStatuses()
    }

    private func refreshPersistentStatuses() {
        let sessionsByID = activeSessionsByID()
        pruneInactiveStatuses(activeIDs: Set(sessionsByID.keys))

        let items = sessionsByID.values.map { session in
            let item = statusItemsByID[session.id]
            return PersistentStatusItem(
                id: session.id,
                project: session.project,
                projectPath: session.projectPath,
                state: item?.state ?? fallbackState(for: session),
                lastActivity: item?.lastActivity ?? session.lastActivity,
                modifiedFilesCount: session.modifiedFilesCount
            )
        }
        FloatNotificationManager.shared.showPersistentStatuses(items)
    }

    private func activeSessionsByID() -> [String: SessionDescriptor] {
        claudeSessionsByID.merging(codexSessionsByID) { current, _ in current }
    }

    private func pruneInactiveStatuses(activeIDs: Set<String>) {
        for (sessionID, timer) in idleTransitionTimers where !activeIDs.contains(sessionID) {
            timer.invalidate()
        }

        idleTransitionTimers = idleTransitionTimers.filter { activeIDs.contains($0.key) }
        statusItemsByID = statusItemsByID.filter { activeIDs.contains($0.key) }
    }

    private func monitoredSession(for sessionID: String) -> SessionDescriptor? {
        claudeSessionsByID[sessionID] ?? codexSessionsByID[sessionID]
    }

    private func fallbackState(for session: SessionDescriptor) -> ClaudeStatusState {
        guard session.id.hasPrefix("codex:"), session.isTaskStateKnown else {
            return .complete
        }

        if session.isRunning {
            return .running
        }

        if Date().timeIntervalSince(session.lastActivity) < idleTimeoutSeconds {
            return .idle
        }

        return .complete
    }

    private func makeStatusItem(sessionID: String, project: String, state: ClaudeStatusState, lastActivity: Date) -> PersistentStatusItem {
        let monitoredSession = monitoredSession(for: sessionID)
        let existingItem = statusItemsByID[sessionID]
        return PersistentStatusItem(
            id: sessionID,
            project: monitoredSession?.project ?? existingItem?.project ?? project,
            projectPath: monitoredSession?.projectPath ?? existingItem?.projectPath,
            state: state,
            lastActivity: lastActivity,
            modifiedFilesCount: monitoredSession?.modifiedFilesCount ?? existingItem?.modifiedFilesCount ?? 0
        )
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🦆"
        }

        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: nil, keyEquivalent: ",")
        settingsItem.target = nil
        settingsItem.representedObject = self
        settingsItem.action = #selector(AppDelegate.openSettings(_:))
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(title: "Test Notification", action: #selector(testNotification), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)

        let arrangeItem = NSMenuItem(title: "Arrange", action: #selector(arrangeFloaters), keyEquivalent: "")
        arrangeItem.target = self
        menu.addItem(arrangeItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Floatify", action: #selector(quit), keyEquivalent: "q")

        menu.delegate = self
        statusItem.menu = menu
    }

    @objc func openSettings(_ sender: Any?) {
        NSLog("Floatify: openSettings called with sender: \(String(describing: sender))")
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Floatify Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        NSLog("Floatify: Settings window created and shown")
    }

    @objc func openSettings() {
        NSLog("Floatify: openSettings called")
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 280),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Floatify Settings"
        window.contentView = NSHostingView(rootView: SettingsView())
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSLog("Floatify: Settings window created and shown")
    }

    @objc private func testNotification() {
        for corner in Corner.allCases {
            FloatNotificationManager.shared.show(message: "Test: \(corner.rawValue)", corner: corner, duration: 5, project: "Test")
        }
    }

    @objc private func arrangeFloaters() {
        FloatNotificationManager.shared.arrangePersistentStatuses()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == settingsWindow {
            settingsWindow = nil
        }
    }

    private func setupPipeListener() {
        NSLog("Floatify: Setting up pipe at %@", pipePath)

        if !FileManager.default.fileExists(atPath: pipePath) {
            let result = mkfifo(pipePath, 0o666)
            NSLog("Floatify: mkfifo result: %d, errno: %d", result, errno)
        }

        try? FileManager.default.removeItem(atPath: pipePath)
        let mkresult = mkfifo(pipePath, 0o666)
        NSLog("Floatify: mkfifo second call result: %d, errno: %d", mkresult, errno)

        let pipeFd = open(pipePath, O_RDONLY | O_NONBLOCK)
        NSLog("Floatify: pipeFd: %d, errno: %d", pipeFd, errno)
        guard pipeFd >= 0 else {
            print("Failed to open pipe at \(pipePath)")
            return
        }

        pipeSource = DispatchSource.makeReadSource(fileDescriptor: pipeFd, queue: .main)
        pipeSource?.setEventHandler { [weak self] in
            NSLog("Floatify: Pipe event triggered")
            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(pipeFd, &buffer, buffer.count)
            NSLog("Floatify: Bytes read: %d", bytesRead)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    NSLog("Floatify: Received JSON: %@", json)
                    self?.handleJSON(json)
                }
            }
        }
        pipeSource?.setCancelHandler {
            close(pipeFd)
        }
        pipeSource?.resume()
    }

    private func handleJSON(_ json: [String: Any]) {
        NSLog("Floatify: handleJSON called with: %@", json)
        if let statusString = json["status"] as? String,
           let state = claudeStatusState(from: statusString) {
            let source = (json["source"] as? String)?.lowercased() ?? "claude"
            let projectValue = (json["project"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let project = (projectValue?.isEmpty == false) ? projectValue! : source
            let sessionID = (json["session"] as? String) ?? "\(source):\(project)"

            let now = Date()
            idleTransitionTimers[sessionID]?.invalidate()
            idleTransitionTimers.removeValue(forKey: sessionID)

            let displayState: ClaudeStatusState = (state == .complete) ? .idle : state
            statusItemsByID[sessionID] = makeStatusItem(
                sessionID: sessionID,
                project: project,
                state: displayState,
                lastActivity: now
            )
            refreshPersistentStatuses()

            if state == .idle || state == .complete {
                idleTransitionTimers[sessionID] = Timer.scheduledTimer(withTimeInterval: idleTimeoutSeconds, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    guard let currentItem = self.statusItemsByID[sessionID] else { return }
                    self.statusItemsByID[sessionID] = PersistentStatusItem(
                        id: currentItem.id,
                        project: currentItem.project,
                        projectPath: self.monitoredSession(for: sessionID)?.projectPath ?? currentItem.projectPath,
                        state: .complete,
                        lastActivity: currentItem.lastActivity,
                        modifiedFilesCount: self.monitoredSession(for: sessionID)?.modifiedFilesCount ?? currentItem.modifiedFilesCount
                    )
                    self.idleTransitionTimers.removeValue(forKey: sessionID)
                    self.refreshPersistentStatuses()
                }
            }
        }

        guard json["message"] != nil else { return }

        let message = json["message"] as? String ?? "Task complete!"
        let project = json["project"] as? String ?? "Claude Code"
        let cornerStr = json["corner"] as? String ?? "bottomRight"
        let corner: Corner

        switch cornerStr {
        case "bottomLeft":
            corner = .bottomLeft
        case "bottomRight":
            corner = .bottomRight
        case "topLeft":
            corner = .topLeft
        case "topRight":
            corner = .topRight
        case "center":
            corner = .center
        case "menubar":
            corner = .menubar
        case "horizontal":
            corner = .horizontal
        case "cursorFollow":
            corner = .cursorFollow
        default:
            corner = .bottomRight
        }

        let duration = json["duration"] as? TimeInterval ?? 6.0

        DispatchQueue.main.async {
            FloatNotificationManager.shared.show(message: message, corner: corner, duration: duration, project: project)
        }
    }

    private var idleTimeoutSeconds: TimeInterval {
        let stored = UserDefaults.standard.integer(forKey: "IdleTimeout")
        return stored > 0 ? TimeInterval(stored) : 15.0
    }

    private func claudeStatusState(from rawValue: String) -> ClaudeStatusState? {
        switch rawValue.lowercased() {
        case "running":
            return .running
        case "idle":
            return .idle
        case "complete", "done":
            return .complete
        default:
            return nil
        }
    }

    private func installCLIToolIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "CLISymlinkInstalled") else { return }

        let src = Bundle.main.url(forResource: "floatify", withExtension: nil)
        guard let srcURL = src else {
            NSLog("Floatify: floatify binary not found in app bundle")
            return
        }

        let dest = URL(fileURLWithPath: "/usr/local/bin/floatify")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: srcURL)
            defaults.set(true, forKey: "CLISymlinkInstalled")
            NSLog("Floatify: Installed floatify to /usr/local/bin/")
        } catch {
            NSLog("Floatify: Failed to install floatify CLI: %@", error.localizedDescription)
        }
    }
}
