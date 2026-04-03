import AppKit
import Foundation

final class CursorTracker {
    static let shared = CursorTracker()

    var edgePadding: CGFloat = 20

    var currentPosition: CGPoint {
        NSEvent.mouseLocation
    }

    private init() {}

    func startTracking() {
        // No-op: NSEvent.mouseLocation always returns current position
    }

    func stopTracking() {
        // No-op
    }

    func clampedPosition(in rect: CGRect) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero
        let pos = NSEvent.mouseLocation

        var x = pos.x
        var y = pos.y

        x = max(rect.minX + edgePadding, min(x, rect.maxX - edgePadding))
        y = max(rect.minY + edgePadding, min(y, rect.maxY - edgePadding))

        x = max(edgePadding, min(x, screen.width - edgePadding))
        y = max(edgePadding, min(y, screen.height - edgePadding))

        return CGPoint(x: x, y: y)
    }

    func screenCornerPosition(for corner: Corner, panelSize: CGSize) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero

        switch corner {
        case .bottomLeft:
            return CGPoint(x: edgePadding + panelSize.width / 2, y: edgePadding + panelSize.height / 2)
        case .bottomRight:
            return CGPoint(x: screen.width - edgePadding - panelSize.width / 2, y: edgePadding + panelSize.height / 2)
        case .topLeft:
            return CGPoint(x: edgePadding + panelSize.width / 2, y: screen.height - edgePadding - panelSize.height / 2)
        case .topRight:
            return CGPoint(x: screen.width - edgePadding - panelSize.width / 2, y: screen.height - edgePadding - panelSize.height / 2)
        case .center:
            return CGPoint(x: screen.midX, y: screen.midY)
        case .menubar:
            return CGPoint(x: screen.midX, y: screen.height - edgePadding - panelSize.height / 2)
        case .horizontal:
            return CGPoint(x: screen.midX, y: edgePadding + panelSize.height / 2)
        case .cursorFollow:
            return clampedPosition(in: screen)
        }
    }
}
