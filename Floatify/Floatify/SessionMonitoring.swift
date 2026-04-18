import Foundation

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

private enum ProcessInspection {
    static func commandOutput(executablePath: String, arguments: [String]) -> String? {
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

    static func workingDirectory(for pid: Int) -> String? {
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

    static func modifiedFilesCount(for projectPath: String?) -> Int {
        guard let path = projectPath else { return 0 }
        guard let output = commandOutput(executablePath: "/usr/bin/git", arguments: ["-C", path, "status", "--porcelain"]) else {
            return 0
        }
        return output.split(separator: "\n").count
    }

    static func codexSessionLogPath(for pid: Int) -> String? {
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
        guard let output = ProcessInspection.commandOutput(executablePath: "/bin/ps", arguments: ["-Ao", "pid=,ppid=,command="]) else {
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
            let lastActivity = lastActivityCache[pid] ?? Date()
            let modifiedCount = ProcessInspection.modifiedFilesCount(for: projectContext.path)

            lastActivityCache[pid] = lastActivity
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

        let projectPath = ProcessInspection.workingDirectory(for: pid)
        let context = ProjectContext(
            name: projectPath.map(projectName(for:)) ?? fallbackProject,
            path: projectPath
        )
        projectCache[pid] = context
        return context
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
        guard let output = ProcessInspection.commandOutput(executablePath: "/bin/ps", arguments: ["-Aww", "-o", "pid=,ppid=,command="]) else {
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
            let projectContext = cachedProjectContext(for: nodePID, fallbackProject: "Codex")
            let activityState = cachedActivityState(for: nodePID, vendorPID: vendorPIDByNodePID[nodePID], fallbackDate: now)
            let modifiedCount = ProcessInspection.modifiedFilesCount(for: projectContext.path)

            modifiedFilesCache[nodePID] = modifiedCount

            return SessionDescriptor(
                id: "codex:\(nodePID)",
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
        let sessionLogPath = ProcessInspection.codexSessionLogPath(for: vendorPID)
        if let sessionLogPath {
            sessionLogPathCache[nodePID] = sessionLogPath
        }
        return sessionLogPath
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

        let projectPath = ProcessInspection.workingDirectory(for: pid)
        let context = ProjectContext(
            name: projectPath.map(projectName(for:)) ?? fallbackProject,
            path: projectPath
        )
        projectCache[pid] = context
        return context
    }
}
