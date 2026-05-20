import AppKit
import Darwin

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
    private var standaloneStatusItemIDs: Set<String> = []
    private var completionAcknowledgementTracker = CompletionAcknowledgementTracker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if ProcessInfo.processInfo.environment["FLOATIFY_PREBUILD_EFFECTS"] == "1" {
            do {
                let summary = try SlaySnapshotCache.prebuildBundledAssets(settings: settings)
                NSLog(
                    "Floatify: prebuilt %d effect sequences (%d frames)",
                    summary.sequenceCount,
                    summary.frameCount
                )
            } catch {
                NSLog("Floatify: failed to prebuild effect frames: %@", error.localizedDescription)
                exit(1)
            }

            exit(0)
        }

        setupPipeListener()
        installCLIToolIfNeeded()
        SoundManager.shared.loadSounds()
        setupPersistentStatusFloater()

        DispatchQueue.main.async {
            SlaySnapshotCache.prewarmCurrentConfiguration(settings: self.settings)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        claudeSessionMonitor.stop()
        codexActivityMonitor.stop()
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

        var items = sessionsByID.values.map { session in
            visibleStatusItem(rawStatusItem(for: session))
        }
        items.append(
            contentsOf: statusItemsByID.values.filter {
                standaloneStatusItemIDs.contains($0.id) && sessionsByID[$0.id] == nil
            }.map(visibleStatusItem(_:))
        )

        FloaterPanelManager.shared.showPersistentStatuses(
            items,
            onItemAvatarTap: { [weak self] item in
                self?.acknowledgeCompletionIfFinished(for: item)
            }
        )
    }

    private func visibleStatusItem(_ item: PersistentStatusItem) -> PersistentStatusItem {
        PersistentStatusItem(
            id: item.id,
            project: item.project,
            projectPath: item.projectPath,
            state: completionAcknowledgementTracker.visibleState(for: item.state, sessionID: item.id),
            lastActivity: item.lastActivity,
            modifiedFilesCount: item.modifiedFilesCount
        )
    }

    private func acknowledgeCompletionIfFinished(for item: PersistentStatusItem) {
        let rawState = resolvedRawState(for: item)
        guard rawState != .running else { return }

        completionAcknowledgementTracker.acknowledge(sessionID: item.id)
        refreshPersistentStatuses()
    }

    private func rawStatusItem(for session: SessionDescriptor) -> PersistentStatusItem {
        let item = statusItemsByID[session.id]
        let rawState = PersistentStatusStateResolver.rawState(
            storedState: item?.state,
            monitoredState: fallbackState(for: session),
            isTaskStateKnown: session.isTaskStateKnown
        )

        if rawState == .running {
            completionAcknowledgementTracker.markRunning(sessionID: session.id)
        }

        return PersistentStatusItem(
            id: session.id,
            project: session.project,
            projectPath: session.projectPath,
            state: rawState,
            lastActivity: item?.lastActivity ?? session.lastActivity,
            modifiedFilesCount: session.modifiedFilesCount
        )
    }

    private func resolvedRawState(for item: PersistentStatusItem) -> ClaudeStatusState {
        guard let session = monitoredSession(for: item.id) else {
            return statusItemsByID[item.id]?.state ?? item.state
        }

        return PersistentStatusStateResolver.rawState(
            storedState: statusItemsByID[item.id]?.state,
            monitoredState: fallbackState(for: session),
            isTaskStateKnown: session.isTaskStateKnown
        )
    }

    private func activeSessionsByID() -> [String: SessionDescriptor] {
        claudeSessionsByID.merging(codexSessionsByID) { current, _ in current }
    }

    private func pruneInactiveStatuses(activeIDs: Set<String>) {
        statusItemsByID = statusItemsByID.filter {
            activeIDs.contains($0.key) || standaloneStatusItemIDs.contains($0.key)
        }
        standaloneStatusItemIDs.formIntersection(statusItemsByID.keys)
        completionAcknowledgementTracker.prune(activeIDs: activeIDs.union(standaloneStatusItemIDs))
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

    private func makeStatusItem(
        sessionID: String,
        project: String,
        projectPath: String?,
        state: ClaudeStatusState,
        lastActivity: Date
    ) -> PersistentStatusItem {
        let monitoredSession = monitoredSession(for: sessionID)
        let existingItem = statusItemsByID[sessionID]
        let resolvedProjectPath = monitoredSession?.projectPath ?? existingItem?.projectPath ?? projectPath
        let modifiedFilesCount = monitoredSession?.modifiedFilesCount
            ?? ProcessInspection.modifiedFilesCount(for: resolvedProjectPath)

        return PersistentStatusItem(
            id: sessionID,
            project: monitoredSession?.project ?? existingItem?.project ?? project,
            projectPath: resolvedProjectPath,
            state: state,
            lastActivity: lastActivity,
            modifiedFilesCount: modifiedFilesCount
        )
    }

    private func setupPipeListener() {
        NSLog("Floatify: Setting up pipe at %@", pipePath)

        if FileManager.default.fileExists(atPath: pipePath) {
            do {
                try FileManager.default.removeItem(atPath: pipePath)
            } catch {
                NSLog("Floatify: failed to remove existing pipe at %@: %@", pipePath, error.localizedDescription)
                return
            }
        }

        errno = 0
        let mkresult = mkfifo(pipePath, 0o666)
        NSLog("Floatify: mkfifo result: %d, errno: %d", mkresult, errno)
        guard mkresult == 0 else {
            print("Failed to create pipe at \(pipePath)")
            return
        }

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
    }

    private func applyStatusUpdate(state: ClaudeStatusState, payload: FloatifyPipePayload) {
        let sessionID = payload.statusSessionID
        let now = Date()

        if state == .running {
            completionAcknowledgementTracker.markRunning(sessionID: sessionID)
        } else {
            completionAcknowledgementTracker.markCompleted(sessionID: sessionID)
        }

        if payload.session == nil && monitoredSession(for: sessionID) == nil {
            standaloneStatusItemIDs.insert(sessionID)
        } else {
            standaloneStatusItemIDs.remove(sessionID)
        }

        statusItemsByID[sessionID] = makeStatusItem(
            sessionID: sessionID,
            project: payload.statusProject,
            projectPath: payload.normalizedProjectPath,
            state: state,
            lastActivity: now
        )
        refreshPersistentStatuses()
    }

    private func claudeStatusState(from rawValue: String) -> ClaudeStatusState? {
        switch rawValue.lowercased() {
        case "running":
            return .running
        case "idle":
            return .idle
        case "complete":
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
