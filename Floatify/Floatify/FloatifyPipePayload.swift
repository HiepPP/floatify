import Foundation

struct FloatifyPipePayload: Decodable {
    let message: String?
    let project: String?
    let corner: String?
    let duration: TimeInterval?
    let status: String?
    let source: String?
    let session: String?

    var normalizedSource: String {
        source?.lowercased() ?? "claude"
    }

    var normalizedProject: String? {
        let trimmed = project?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    var statusProject: String {
        normalizedProject ?? normalizedSource
    }

    var statusSessionID: String {
        session ?? "\(normalizedSource):\(statusProject)"
    }

    var notificationMessage: String {
        message ?? "Task complete!"
    }

    var notificationProject: String {
        normalizedProject ?? "Claude Code"
    }

    var notificationCorner: Corner {
        switch corner.flatMap(Corner.init(rawValue:)) {
        case .cursorFollow:
            return .bottomRight
        case let resolved?:
            return resolved
        case nil:
            return .bottomRight
        }
    }

    var notificationDuration: TimeInterval {
        duration ?? 6.0
    }
}
