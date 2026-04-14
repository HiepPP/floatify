import AppKit

struct SessionDescriptor: Equatable {
    let id: String
    let project: String
    let isRunning: Bool
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
    private var projectCache: [Int: String] = [:]

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
            sessions.append(
                SessionDescriptor(
                    id: "claude:\(pid)",
                    project: cachedProjectName(for: pid),
                    isRunning: false
                )
            )
        }

        projectCache = projectCache.filter { activePIDs.contains($0.key) }
        return sessions.sorted { $0.id < $1.id }
    }

    private func cachedProjectName(for pid: Int) -> String {
        if let cached = projectCache[pid] {
            return cached
        }

        let project = lookupProjectName(for: pid) ?? "Claude Code"
        projectCache[pid] = project
        return project
    }

    private func lookupProjectName(for pid: Int) -> String? {
        guard let output = commandOutput(executablePath: "/usr/sbin/lsof", arguments: ["-a", "-d", "cwd", "-p", "\(pid)"]) else {
            return nil
        }

        for rawLine in output.split(separator: "\n").dropFirst() {
            let parts = rawLine.split(maxSplits: 8, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard let pathField = parts.last else { continue }
            return projectName(for: String(pathField))
        }

        return nil
    }
}

final class CodexActivityMonitor {
    var onSessionsChange: (([SessionDescriptor]) -> Void)?

    private let queue = DispatchQueue(label: "com.floatify.codex-activity")
    private var timer: DispatchSourceTimer?
    private var lastPublished: [SessionDescriptor] = []
    private var lastDetectedActivityAtBySessionID: [String: Date] = [:]
    private var projectCache: [Int: String] = [:]
    private let activeHoldDuration: TimeInterval = 8

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
        guard let output = commandOutput(executablePath: "/bin/ps", arguments: ["-Aww", "-o", "pid=,ppid=,pcpu=,command="]) else {
            return []
        }

        var activeNodePIDs = Set<Int>()
        var vendorCPUByNodePID: [Int: Double] = [:]

        for rawLine in output.split(separator: "\n") {
            let parts = rawLine.split(maxSplits: 3, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard parts.count == 4,
                  let pid = Int(parts[0]),
                  let ppid = Int(parts[1]),
                  let cpu = Double(parts[2]) else {
                continue
            }

            let command = String(parts[3])

            if command.contains("node /opt/homebrew/bin/codex") {
                activeNodePIDs.insert(pid)
                continue
            }

            guard command.contains("/codex/codex") else {
                continue
            }

            activeNodePIDs.insert(ppid)
            vendorCPUByNodePID[ppid] = max(vendorCPUByNodePID[ppid] ?? 0, cpu)
        }

        let activeSessionIDs = Set(activeNodePIDs.map { "codex:\($0)" })
        lastDetectedActivityAtBySessionID = lastDetectedActivityAtBySessionID.filter { activeSessionIDs.contains($0.key) }
        projectCache = projectCache.filter { activeNodePIDs.contains($0.key) }

        let now = Date()
        return activeNodePIDs.sorted().map { nodePID in
            let id = "codex:\(nodePID)"
            let cpu = vendorCPUByNodePID[nodePID] ?? 0
            if cpu >= 0.7 {
                lastDetectedActivityAtBySessionID[id] = now
            }

            let isRunning = lastDetectedActivityAtBySessionID[id].map {
                now.timeIntervalSince($0) < activeHoldDuration
            } ?? false

            return SessionDescriptor(
                id: id,
                project: cachedProjectName(for: nodePID),
                isRunning: isRunning
            )
        }
    }

    private func cachedProjectName(for pid: Int) -> String {
        if let cached = projectCache[pid] {
            return cached
        }

        let project = lookupProjectName(for: pid) ?? "Codex"
        projectCache[pid] = project
        return project
    }

    private func lookupProjectName(for pid: Int) -> String? {
        guard let output = commandOutput(executablePath: "/usr/sbin/lsof", arguments: ["-a", "-d", "cwd", "-p", "\(pid)"]) else {
            return nil
        }

        for rawLine in output.split(separator: "\n").dropFirst() {
            let parts = rawLine.split(maxSplits: 8, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
            guard let pathField = parts.last else { continue }
            return projectName(for: String(pathField))
        }

        return nil
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pipeSource: DispatchSourceRead?
    private let pipePath = "/var/tmp/floatify.pipe"
    private let claudeSessionMonitor = ClaudeSessionMonitor()
    private let codexActivityMonitor = CodexActivityMonitor()
    private var claudeSessionsByID: [String: String] = [:]
    private var claudeRunningStateByID: [String: Bool] = [:]
    private var codexSessionsByID: [String: SessionDescriptor] = [:]

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
    }

    private func setupPersistentStatusFloater() {
        claudeSessionMonitor.onSessionsChange = { [weak self] sessions in
            guard let self else { return }
            self.claudeSessionsByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0.project) })
            self.claudeRunningStateByID = self.claudeRunningStateByID.filter { self.claudeSessionsByID[$0.key] != nil }
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
        var items: [PersistentStatusItem] = claudeSessionsByID.map { id, project in
            let isRunning = claudeRunningStateByID[id] ?? false
            return PersistentStatusItem(
                id: id,
                project: project,
                state: isRunning ? .running : .complete
            )
        }

        items.append(contentsOf: codexSessionsByID.values.map { session in
            PersistentStatusItem(
                id: session.id,
                project: session.project,
                state: session.isRunning ? .running : .complete
            )
        })

        FloatNotificationManager.shared.showPersistentStatuses(items)
    }

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
        menu.addItem(NSMenuItem(title: "Quit Floatify", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func testNotification() {
        for corner in Corner.allCases {
            FloatNotificationManager.shared.show(message: "Test: \(corner.rawValue)", corner: corner, duration: 5, project: "Test")
        }
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
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
            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(pipeFd, &buffer, buffer.count)
            if bytesRead > 0 {
                let data = Data(bytes: buffer, count: bytesRead)
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
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
        if let statusString = json["status"] as? String,
           let isRunning = claudeRunningStatus(from: statusString) {
            let source = (json["source"] as? String)?.lowercased() ?? "claude"
            let projectValue = (json["project"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let project = (projectValue?.isEmpty == false) ? projectValue! : source
            let sessionID = (json["session"] as? String) ?? "\(source):\(project)"

            if source == "claude" {
                claudeSessionsByID[sessionID] = project
                claudeRunningStateByID[sessionID] = isRunning
                refreshPersistentStatuses()
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

    private func claudeRunningStatus(from rawValue: String) -> Bool? {
        switch rawValue.lowercased() {
        case "running":
            return true
        case "complete", "done", "idle":
            return false
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
