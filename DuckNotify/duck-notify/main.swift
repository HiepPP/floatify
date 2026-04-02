import Foundation

// MARK: - Argument Parsing

var message = "Task complete!"
var corner = "bottomRight"
var duration = "6"

let args = Array(CommandLine.arguments.dropFirst())
var index = 0
while index < args.count {
    let flag = args[index]
    index += 1
    guard index < args.count else { break }

    switch flag {
    case "--message":
        message = args[index]
    case "--corner":
        corner = args[index]
    case "--duration":
        duration = args[index]
    default:
        break
    }
    index += 1
}

// Validate corner
guard corner == "bottomLeft" || corner == "bottomRight" else {
    fputs("Invalid corner '\(corner)'. Use 'bottomLeft' or 'bottomRight'.\n", stderr)
    exit(1)
}

// Validate duration
guard Double(duration) != nil else {
    fputs("Invalid duration '\(duration)'. Must be a number.\n", stderr)
    exit(1)
}

// MARK: - DistributedNotification

let payload: [String: Any] = [
    "message":  message,
    "corner":   corner,
    "duration": duration
]

let notificationName = "com.ducknotify.newNotification"
DistributedNotificationCenter.default().postNotificationName(
    NSNotification.Name(notificationName),
    object: nil,
    userInfo: payload,
    deliverImmediately: true
)

print("🦆 Sent: \(message)")
