import Foundation

enum Corner: String, CaseIterable {
    case bottomLeft
    case bottomRight
    case topLeft
    case topRight
    case center
    case menubar
    case horizontal
    case cursorFollow

    static var allCases: [Corner] {
        [
            .bottomLeft,
            .bottomRight,
            .topLeft,
            .topRight,
            .center,
            .menubar,
            .horizontal
        ]
    }

    var defaultEffect: String {
        switch self {
        case .bottomLeft, .bottomRight, .topLeft, .topRight:
            return "slide"
        case .center:
            return "fade"
        case .menubar:
            return "dropdown"
        case .horizontal:
            return "marquee"
        case .cursorFollow:
            return "trail"
        }
    }

    var defaultSound: String? {
        switch self {
        case .bottomLeft, .bottomRight, .topLeft, .topRight:
            return nil
        case .center:
            return "pop"
        case .menubar:
            return "tink"
        case .horizontal:
            return nil
        case .cursorFollow:
            return nil
        }
    }
}
