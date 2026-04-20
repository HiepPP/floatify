import Foundation
import Darwin

// MARK: - Argument Parsing

var message = "Task complete!"
var corner = "bottomRight"
var duration = "6"
var project = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).lastPathComponent
var effect: String? = nil
var status: String? = nil
var didSetMessage = false
var didSetCorner = false
var didSetDuration = false
var didSetProject = false

let args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let flag = args[index]
    index += 1
    guard index < args.count else { break }

    switch flag {
    case "--message":
        message = args[index]
        didSetMessage = true
    case "--position", "--corner":
        corner = args[index]
        didSetCorner = true
    case "--duration":
        duration = args[index]
        didSetDuration = true
    case "--project":
        project = args[index]
        didSetProject = true
    case "--effect":
        effect = args[index]
    case "--status":
        status = args[index]
    default:
        break
    }
    index += 1
}

// Validate corner
if corner == "cursorFollow" {
    corner = "bottomRight"
}

let validCorners = ["bottomLeft", "bottomRight", "topLeft", "topRight", "center", "menubar", "horizontal"]
guard validCorners.contains(corner) else {
    fputs("Invalid corner '\(corner)'. Use: \(validCorners.joined(separator: ", ")).\n", stderr)
    exit(1)
}

// Validate duration
guard Double(duration) != nil else {
    fputs("Invalid duration '\(duration)'. Must be a number.\n", stderr)
    exit(1)
}

if let status {
    let validStatuses = ["running", "commit", "committing", "push", "pushing", "complete", "done", "idle"]
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
    if let context = inferSessionContext() {
        payload["source"] = context.source
        payload["session"] = context.session
    }
}

let shouldSendNotification = didSetMessage || didSetCorner || didSetDuration || didSetProject || effect != nil || status == nil

if shouldSendNotification {
    payload["message"] = message
    payload["corner"] = corner
    payload["duration"] = Double(duration) ?? 6.0
    payload["project"] = project
}

if let effect = effect {
    payload["effect"] = effect
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
    if shouldSendNotification {
        print("🦆 Sent: \(message)")
    }
    exit(0)
} else {
    fputs("Failed to write to pipe\n", stderr)
    exit(1)
}
