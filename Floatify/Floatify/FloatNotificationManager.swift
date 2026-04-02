import AppKit
import SwiftUI
import os.log

// MARK: - FloatPanel

class FloatPanel: NSPanel {
    var horizontalIndex: Int = 0

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }
}

// MARK: - FloatNotificationManager

class FloatNotificationManager {
    static let shared = FloatNotificationManager()
    private var panels: [FloatPanel] = []
    private var cursorFollowTimers: [FloatPanel: Timer] = [:]
    private let maxPanels = 3
    private let maxHorizontalPanels = 5
    private let stackOffset: CGFloat = 4
    private let horizontalStackOffset: CGFloat = 8
    private let log = OSLog(subsystem: "com.floatify", category: "panel")

    private init() {}

    func show(message: String, corner: Corner, duration: TimeInterval = 6) {
        DispatchQueue.main.async {
            self.createPanel(message: message, corner: corner, duration: duration)
        }
    }

    private func createPanel(message: String, corner: Corner, duration: TimeInterval) {
        if panels.count >= maxPanels {
            dismissOldest()
        }

        let size = CGSize(width: 280, height: 68)
        let origin: CGPoint
        var newPanel = FloatPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        switch corner {
        case .horizontal:
            let result = handleHorizontalPanel(panel: &newPanel, size: size)
            origin = result.origin
            newPanel.horizontalIndex = result.index
        case .cursorFollow:
            origin = handleCursorFollowPanel(panel: &newPanel, size: size)
        case .topLeft, .topRight, .center, .menubar:
            origin = handleVerticalPanel(corner: corner, size: size)
        default:
            let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * stackOffset
            origin = cornerOrigin(corner: corner, size: size, stackOffset: stackOffsetY)
        }

        newPanel.setFrameOrigin(origin)
        newPanel.level = .popUpMenu
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.ignoresMouseEvents = false

        let view = FloatNotificationView(message: message, corner: corner) { [weak self] in
            self?.dismiss(panel: newPanel)
        }
        newPanel.contentView = NSHostingView(rootView: view)
        newPanel.orderFront(nil)
        panels.append(newPanel)

        if corner == .cursorFollow {
            startCursorTracking(for: newPanel)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.dismiss(panel: newPanel)
        }
    }

    private func handleHorizontalPanel(panel: inout FloatPanel, size: CGSize) -> (origin: CGPoint, index: Int) {
        let horizontalPanels = panels.filter { $0.horizontalIndex > 0 }
        let index = horizontalPanels.count + 1
        if index > maxHorizontalPanels {
            if let oldest = panels.first(where: { $0.horizontalIndex > 0 }) {
                dismiss(panel: oldest)
            }
        }
        let offsetX = CGFloat(index) * horizontalStackOffset
        return (horizontalOrigin(size: size, offset: offsetX), index)
    }

    private func handleCursorFollowPanel(panel: inout FloatPanel, size: CGSize) -> CGPoint {
        return CursorTracker.shared.screenCornerPosition(for: .cursorFollow, panelSize: size)
    }

    private func handleVerticalPanel(corner: Corner, size: CGSize) -> CGPoint {
        let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * stackOffset
        return cornerOrigin(corner: corner, size: size, stackOffset: stackOffsetY)
    }

    private func startCursorTracking(for panel: FloatPanel) {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak panel] timer in
            guard let panel = panel, panel.isVisible else {
                timer.invalidate()
                return
            }
            let newOrigin = CursorTracker.shared.screenCornerPosition(for: .cursorFollow, panelSize: panel.frame.size)
            panel.setFrameOrigin(newOrigin)
        }
        cursorFollowTimers[panel] = timer
    }

    private func stopCursorTracking(for panel: FloatPanel) {
        cursorFollowTimers[panel]?.invalidate()
        cursorFollowTimers.removeValue(forKey: panel)
    }

    private func dismiss(panel: FloatPanel) {
        stopCursorTracking(for: panel)
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

    private func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 0, stackOffset: CGFloat = 0) -> CGPoint {
        guard let screen = NSScreen.main else {
            print("DEBUG: No main screen, returning zero")
            return .zero
        }
        let frame = screen.frame
        switch corner {
        case .bottomLeft:
            return CGPoint(x: frame.minX + padding, y: frame.minY + padding + stackOffset)
        case .bottomRight:
            return CGPoint(x: frame.maxX - size.width - padding, y: frame.minY + padding + stackOffset)
        case .topLeft:
            return CGPoint(x: frame.minX + padding, y: frame.maxY - size.height - padding - stackOffset)
        case .topRight:
            return CGPoint(x: frame.maxX - size.width - padding, y: frame.maxY - size.height - padding - stackOffset)
        case .center:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2 + stackOffset)
        case .menubar:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.maxY - size.height - padding - stackOffset)
        case .horizontal:
            return CGPoint(x: frame.midX - size.width / 2, y: frame.minY + padding + stackOffset)
        case .cursorFollow:
            return CursorTracker.shared.screenCornerPosition(for: corner, panelSize: size)
        }
    }

    private func horizontalOrigin(size: CGSize, offset: CGFloat) -> CGPoint {
        guard let screen = NSScreen.main else { return .zero }
        let frame = screen.frame
        return CGPoint(x: frame.midX - size.width / 2 + offset, y: frame.minY + 20)
    }
}
