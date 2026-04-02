import AppKit
import SwiftUI

// MARK: - DuckPanel

class DuckPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

// MARK: - DuckNotificationManager

class DuckNotificationManager {
    static let shared = DuckNotificationManager()
    private var panels: [DuckPanel] = []
    private let maxPanels = 3
    private let stackOffset: CGFloat = 4

    private init() {}

    func show(message: String, corner: Corner, duration: TimeInterval = 6) {
        DispatchQueue.main.async {
            self.createPanel(message: message, corner: corner, duration: duration)
        }
    }

    private func createPanel(message: String, corner: Corner, duration: TimeInterval) {
        // Enforce max panel cap — dismiss oldest if needed
        if panels.count >= maxPanels {
            dismissOldest()
        }

        let size = CGSize(width: 280, height: 68)
        let stackOffsetY = CGFloat(panels.count) * stackOffset
        let origin = cornerOrigin(corner: corner, size: size, stackOffset: stackOffsetY)

        let panel = DuckPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false

        let view = DuckNotificationView(message: message) { [weak self, weak panel] in
            guard let panel = panel else { return }
            self?.dismiss(panel: panel)
        }
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFront(nil)
        panels.append(panel)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self, weak panel] in
            guard let panel = panel else { return }
            self?.dismiss(panel: panel)
        }
    }

    private func dismiss(panel: DuckPanel) {
        panel.orderOut(nil)
        panels.removeAll { $0 === panel }
        repositionPanels()
    }

    private func dismissOldest() {
        guard let oldest = panels.first else { return }
        dismiss(panel: oldest)
    }

    private func repositionPanels() {
        for (index, panel) in panels.enumerated() {
            let offsetY = CGFloat(index) * stackOffset
            guard let frame = panel.contentView?.window?.frame else { continue }
            let size = frame.size
            let corner: Corner = frame.origin.x < (NSScreen.main?.visibleFrame.midX ?? 0) ? .bottomLeft : .bottomRight
            let newOrigin = cornerOrigin(corner: corner, size: size, stackOffset: offsetY)
            panel.setFrameOrigin(newOrigin)
        }
    }

    private func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 16, stackOffset: CGFloat = 0) -> CGPoint {
        guard let frame = NSScreen.main?.visibleFrame else { return .zero }
        switch corner {
        case .bottomLeft:
            return CGPoint(x: frame.minX + padding, y: frame.minY + padding + stackOffset)
        case .bottomRight:
            return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding + stackOffset)
        }
    }
}
