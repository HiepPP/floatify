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
    private struct CommandCacheEntry {
        let output: String?
        let timestamp: Date
    }

    private struct ModifiedFilesCacheEntry {
        let count: Int
        let timestamp: Date
    }

    private static let commandCacheMaxEntries = 64
    private static let commandCachePruneAge: TimeInterval = 120
    private static let modifiedFilesCacheTTL: TimeInterval = 30
    private static let modifiedFilesCacheMaxEntries = 32
    private static var commandOutputCache: [String: CommandCacheEntry] = [:]
    private static var modifiedFilesCache: [String: ModifiedFilesCacheEntry] = [:]
    private static let commandOutputCacheLock = NSLock()
    private static let modifiedFilesCacheLock = NSLock()

    static func commandOutput(executablePath: String, arguments: [String], cacheTTL: TimeInterval? = nil) -> String? {
        let cacheKey = ([executablePath] + arguments).joined(separator: "\u{1F}")
        let now = Date()

        if let cacheTTL {
            commandOutputCacheLock.lock()
            if let cached = commandOutputCache[cacheKey],
               now.timeIntervalSince(cached.timestamp) < cacheTTL {
                commandOutputCacheLock.unlock()
                return cached.output
            }
            commandOutputCacheLock.unlock()
        }

        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        let output: String?

        do {
            try process.run()
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            output = process.terminationStatus == 0 ? String(data: data, encoding: .utf8) : nil
        } catch {
            output = nil
        }

        if cacheTTL != nil {
            commandOutputCacheLock.lock()
            commandOutputCache[cacheKey] = CommandCacheEntry(output: output, timestamp: now)
            if commandOutputCache.count > commandCacheMaxEntries {
                let cutoff = now.addingTimeInterval(-commandCachePruneAge)
                commandOutputCache = commandOutputCache.filter { $0.value.timestamp > cutoff }
            }
            commandOutputCacheLock.unlock()
        }

        return output
    }

    static func workingDirectory(for pid: Int) -> String? {
        guard let output = commandOutput(
            executablePath: "/usr/sbin/lsof",
            arguments: ["-a", "-d", "cwd", "-p", "\(pid)"],
            cacheTTL: 60
        ) else {
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
        let now = Date()

        modifiedFilesCacheLock.lock()
        let cachedEntry = modifiedFilesCache[path]
        if let cachedEntry,
           now.timeIntervalSince(cachedEntry.timestamp) < modifiedFilesCacheTTL {
            modifiedFilesCacheLock.unlock()
            return cachedEntry.count
        }
        modifiedFilesCacheLock.unlock()

        guard let output = commandOutput(executablePath: "/usr/bin/git", arguments: ["-C", path, "status", "--porcelain"]) else {
            return cachedEntry?.count ?? 0
        }

        let count = output.split(separator: "\n").count

        modifiedFilesCacheLock.lock()
        modifiedFilesCache[path] = ModifiedFilesCacheEntry(count: count, timestamp: now)
        if modifiedFilesCache.count > modifiedFilesCacheMaxEntries {
            let cutoff = now.addingTimeInterval(-(modifiedFilesCacheTTL * 6))
            modifiedFilesCache = modifiedFilesCache.filter { $0.value.timestamp > cutoff }
        }
        modifiedFilesCacheLock.unlock()

        return count
    }

    static func codexSessionLogPath(for pid: Int) -> String? {
        guard let output = commandOutput(
            executablePath: "/usr/sbin/lsof",
            arguments: ["-p", "\(pid)"],
            cacheTTL: 20
        ) else {
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
        guard let output = ProcessInspection.commandOutput(
            executablePath: "/bin/ps",
            arguments: ["-Aww", "-o", "pid=,ppid=,command="],
            cacheTTL: 3
        ) else {
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

    private struct ActivityStateCacheEntry {
        let fileSize: UInt64
        let modificationDate: Date?
        let state: ActivityState
    }

    private let queue = DispatchQueue(label: "com.floatify.codex-activity")
    private var timer: DispatchSourceTimer?
    private var lastPublished: [SessionDescriptor] = []
    private var projectCache: [Int: ProjectContext] = [:]
    private var sessionLogPathCache: [Int: String] = [:]
    private var modifiedFilesCache: [Int: Int] = [:]
    private var activityStateCache: [String: ActivityStateCacheEntry] = [:]
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
        guard let output = ProcessInspection.commandOutput(
            executablePath: "/bin/ps",
            arguments: ["-Aww", "-o", "pid=,ppid=,command="],
            cacheTTL: 3
        ) else {
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
        let activeLogPaths = Set(sessionLogPathCache.values)
        activityStateCache = activityStateCache.filter { activeLogPaths.contains($0.key) }

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

        let attributes = try? FileManager.default.attributesOfItem(atPath: sessionLogPath)
        let fileSize = (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
        let fileModificationDate = attributes?[.modificationDate] as? Date

        if let cached = activityStateCache[sessionLogPath],
           cached.fileSize == fileSize,
           cached.modificationDate == fileModificationDate {
            return cached.state
        }

        guard let fileHandle = FileHandle(forReadingAtPath: sessionLogPath) else {
            return ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
        }
        defer {
            fileHandle.closeFile()
        }

        let actualFileSize = max((try? fileHandle.seekToEnd()) ?? 0, fileSize)
        let readSize = min(UInt64(sessionTailByteCount), actualFileSize)
        if readSize == 0 {
            let state = ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
            activityStateCache[sessionLogPath] = ActivityStateCacheEntry(
                fileSize: actualFileSize,
                modificationDate: fileModificationDate,
                state: state
            )
            return state
        }

        try? fileHandle.seek(toOffset: actualFileSize - readSize)
        let data = fileHandle.readDataToEndOfFile()
        guard var contents = String(data: data, encoding: .utf8) else {
            return ActivityState(isRunning: false, hasTaskState: false, lastActivity: fallbackDate)
        }

        if readSize < actualFileSize, let firstNewline = contents.firstIndex(of: "\n") {
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
                let state = ActivityState(isRunning: false, hasTaskState: true, lastActivity: timestamp)
                activityStateCache[sessionLogPath] = ActivityStateCacheEntry(
                    fileSize: actualFileSize,
                    modificationDate: fileModificationDate,
                    state: state
                )
                return state
            }

            if eventType == "task_started" {
                let state = ActivityState(isRunning: true, hasTaskState: true, lastActivity: timestamp)
                activityStateCache[sessionLogPath] = ActivityStateCacheEntry(
                    fileSize: actualFileSize,
                    modificationDate: fileModificationDate,
                    state: state
                )
                return state
            }
        }

        let state = ActivityState(
            isRunning: false,
            hasTaskState: false,
            lastActivity: fallbackActivityAt ?? fileModificationDate ?? fallbackDate
        )
        activityStateCache[sessionLogPath] = ActivityStateCacheEntry(
            fileSize: actualFileSize,
            modificationDate: fileModificationDate,
            state: state
        )
        return state
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
