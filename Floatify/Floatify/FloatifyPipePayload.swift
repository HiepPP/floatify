import Foundation

struct FloatifyPipePayload: Decodable {
    let project: String?
    let status: String?
    let source: String?
    let session: String?
    let projectPath: String?

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

    var normalizedProjectPath: String? {
        let trimmed = projectPath?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    var statusSessionID: String {
        session ?? "\(normalizedSource):\(statusProject)"
    }
}
