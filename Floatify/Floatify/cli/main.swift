import Foundation
import Darwin

// MARK: - Argument Parsing

var project = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
var status: String? = nil

let args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let flag = args[index]
    index += 1
    guard index < args.count else { break }

    switch flag {
    case "--project":
        project = args[index]
    case "--status":
        status = args[index]
    default:
        break
    }
    index += 1
}

if let status {
    let validStatuses = ["running", "complete", "idle"]
    guard validStatuses.contains(status.lowercased()) else {
        fputs("Invalid status '\(status)'. Use: \(validStatuses.joined(separator: ", ")).\n", stderr)
        exit(1)
    }
}

// MARK: - Write to Pipe

let pipePath = "/var/tmp/floatify.pipe"

var payload: [String: Any] = [:]

func inferSessionContext() -> (source: String, session: String)? {
    var pid = Int(getppid())
    var hopCount = 0

    while pid > 1, hopCount < 20 {
        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-p", "\(pid)", "-o", "ppid=,command="]
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              let output = String(data: data, encoding: .utf8) else {
            return nil
        }

        let rawLine = output.split(separator: "\n").first ?? ""
        let parts = rawLine.split(maxSplits: 1, omittingEmptySubsequences: true, whereSeparator: \.isWhitespace)
        guard parts.count == 2, let parentPID = Int(parts[0]) else {
            return nil
        }

        let command = String(parts[1])

        if command.hasPrefix("claude ") {
            return ("claude", "claude:\(pid)")
        }

        if command.contains("node /opt/homebrew/bin/codex") {
            return ("codex", "codex:\(pid)")
        }

        if command.contains("/codex/codex") {
            return ("codex", "codex:\(parentPID)")
        }

        guard parentPID != pid else {
            break
        }

        pid = parentPID
        hopCount += 1
    }

    return nil
}

if let status {
    payload["status"] = status
    payload["project"] = project
    payload["projectPath"] = FileManager.default.currentDirectoryPath
    if let context = inferSessionContext() {
        payload["source"] = context.source
        payload["session"] = context.session
    }
}

guard !payload.isEmpty else {
    exit(0)
}

guard let data = try? JSONSerialization.data(withJSONObject: payload) else {
    fputs("Failed to encode payload\n", stderr)
    exit(1)
}

// Open pipe for writing
let pipeFd = open(pipePath, O_WRONLY | O_NONBLOCK)
if pipeFd < 0 {
    if errno == EACCES || errno == EPERM {
        fputs("🦆 Permission denied - check app permissions\n", stderr)
    } else {
        fputs("🦆 Floatify.app is not running\n", stderr)
    }
    exit(1)
}

let bytesWritten = data.withUnsafeBytes { buffer -> Int in
    return write(pipeFd, buffer.baseAddress!, data.count)
}
close(pipeFd)

if bytesWritten == data.count {
    print("🦆 Sent status: \(status ?? "unknown")")
    exit(0)
} else {
    fputs("Failed to write to pipe\n", stderr)
    exit(1)
}
