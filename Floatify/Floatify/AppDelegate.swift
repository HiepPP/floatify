import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = FloatifySettings.shared
    private let pipePath = "/var/tmp/floatify.pipe"
    private let pipeDecoder = JSONDecoder()
    private let claudeSessionMonitor = ClaudeSessionMonitor()
    private let codexActivityMonitor = CodexActivityMonitor()

    private var pipeSource: DispatchSourceRead?
    private var claudeSessionsByID: [String: SessionDescriptor] = [:]
    private var codexSessionsByID: [String: SessionDescriptor] = [:]
    private var statusItemsByID: [String: PersistentStatusItem] = [:]
    private var idleTransitionTimers: [String: Timer] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
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

        if Date().timeIntervalSince(session.lastActivity) < settings.idleTimeoutSeconds {
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
            guard let self else { return }

            NSLog("Floatify: Pipe event triggered")
            var buffer = [UInt8](repeating: 0, count: 4096)
            let bytesRead = read(pipeFd, &buffer, buffer.count)
            NSLog("Floatify: Bytes read: %d", bytesRead)

            guard bytesRead > 0 else { return }
            let data = Data(buffer.prefix(bytesRead))

            if let payload = try? self.pipeDecoder.decode(FloatifyPipePayload.self, from: data) {
                self.handlePayload(payload)
            }
        }
        pipeSource?.setCancelHandler {
            close(pipeFd)
        }
        pipeSource?.resume()
    }

    private func handlePayload(_ payload: FloatifyPipePayload) {
        if let statusString = payload.status,
           let state = claudeStatusState(from: statusString) {
            applyStatusUpdate(state: state, payload: payload)
        }

        guard payload.message != nil else { return }
        showNotification(payload)
    }

    private func applyStatusUpdate(state: ClaudeStatusState, payload: FloatifyPipePayload) {
        let sessionID = payload.statusSessionID
        let now = Date()

        idleTransitionTimers[sessionID]?.invalidate()
        idleTransitionTimers.removeValue(forKey: sessionID)

        let displayState: ClaudeStatusState = state == .complete ? .idle : state
        statusItemsByID[sessionID] = makeStatusItem(
            sessionID: sessionID,
            project: payload.statusProject,
            state: displayState,
            lastActivity: now
        )
        refreshPersistentStatuses()

        guard state == .idle || state == .complete else { return }

        idleTransitionTimers[sessionID] = Timer.scheduledTimer(withTimeInterval: settings.idleTimeoutSeconds, repeats: false) { [weak self] _ in
            guard let self, let currentItem = self.statusItemsByID[sessionID] else { return }

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

    private func showNotification(_ payload: FloatifyPipePayload) {
        DispatchQueue.main.async {
            FloatNotificationManager.shared.show(
                message: payload.notificationMessage,
                corner: payload.notificationCorner,
                duration: payload.notificationDuration,
                project: payload.notificationProject
            )
        }
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
        guard !defaults.bool(forKey: FloatifySettings.cliSymlinkInstalledKey) else { return }

        let src = Bundle.main.url(forResource: "floatify", withExtension: nil)
        guard let srcURL = src else {
            NSLog("Floatify: floatify binary not found in app bundle")
            return
        }

        let dest = URL(fileURLWithPath: "/usr/local/bin/floatify")
        try? FileManager.default.removeItem(at: dest)

        do {
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: srcURL)
            defaults.set(true, forKey: FloatifySettings.cliSymlinkInstalledKey)
            NSLog("Floatify: Installed floatify to /usr/local/bin/")
        } catch {
            NSLog("Floatify: Failed to install floatify CLI: %@", error.localizedDescription)
        }
    }
}
