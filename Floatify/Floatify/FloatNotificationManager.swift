import AppKit
import SwiftUI

class FloatPanel: NSPanel {
    var horizontalIndex: Int = 0
    var notificationCorner: Corner = .bottomRight
    var dismissController: DismissController?
    var isPersistentStatusPanel = false

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

enum ClaudeStatusState {
    case running
    case complete

    var message: String {
        switch self {
        case .running:
            return "Still running"
        case .complete:
            return "Complete"
        }
    }

    var indicatorColor: Color {
        switch self {
        case .running:
            return .red
        case .complete:
            return .green
        }
    }
}

struct PersistentStatusItem {
    let id: String
    let project: String
    let state: ClaudeStatusState
}

private struct PersistentStatusStyle {
    let effect: String
    let spriteCharacter: StatusSpriteCharacter
}

class FloatNotificationManager {
    static let shared = FloatNotificationManager()

    private var panels: [FloatPanel] = []
    private var cursorFollowTimers: [FloatPanel: Timer] = [:]
    private var statusPanels: [String: FloatPanel] = [:]
    private var statusPanelMoveObservers: [String: NSObjectProtocol] = [:]
    private let maxPanels = 8
    private let maxHorizontalPanels = 5
    private let horizontalStackOffset: CGFloat = 8
    private let statusPanelVerticalSpacing: CGFloat = 12
    private let statusPanelOriginKeyPrefix = "StatusFloaterOrigin."
    private let statusEffects = ["slide", "fade", "dropdown", "marquee", "trail"]
    private let statusSpriteCharacters: [StatusSpriteCharacter] = [.squirtle, .wartortle, .blastoise]

    private init() {}

    func show(message: String, corner: Corner, duration: TimeInterval = 6, project: String?) {
        DispatchQueue.main.async {
            self.createPanel(message: message, corner: corner, duration: duration, project: project)
        }
    }

    func showPersistentStatuses(_ items: [PersistentStatusItem]) {
        DispatchQueue.main.async {
            let sortedItems = items.sorted {
                if $0.project.localizedCaseInsensitiveCompare($1.project) == .orderedSame {
                    return $0.id < $1.id
                }
                return $0.project.localizedCaseInsensitiveCompare($1.project) == .orderedAscending
            }

            let activeIDs = Set(sortedItems.map(\.id))
            let staleIDs = self.statusPanels.keys.filter { !activeIDs.contains($0) }
            for id in staleIDs {
                self.removeStatusPanel(id: id)
            }

            for (index, item) in sortedItems.enumerated() {
                if let panel = self.statusPanels[item.id] {
                    self.updateStatusPanel(panel, item: item, playsEntryAnimation: false)
                    if !self.hasStoredStatusPanelOrigin(for: item.id) {
                        panel.setFrameOrigin(self.defaultStatusPanelOrigin(for: panel.frame.size, index: index))
                    }
                    panel.orderFrontRegardless()
                    continue
                }

                let panel = self.makePersistentStatusPanel(item: item, index: index)
                self.statusPanels[item.id] = panel
                self.installStatusMoveObserver(for: panel, id: item.id)
                panel.orderFrontRegardless()
            }
        }
    }

    private func createPanel(message: String, corner: Corner, duration: TimeInterval, project: String?) {
        if panels.count >= maxPanels {
            dismissOldest()
        }

        let config = PositionConfigManager.shared.config(for: corner)
        let size = CGSize(width: config.width, height: config.height)
        let origin: CGPoint
        var newPanel = FloatPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        switch corner {
        case .horizontal:
            let result = handleHorizontalPanel(size: size)
            origin = result.origin
            newPanel.horizontalIndex = result.index
        case .cursorFollow:
            origin = CursorTracker.shared.screenCornerPosition(for: .cursorFollow, panelSize: size)
        case .topLeft, .topRight, .center, .menubar:
            origin = handleVerticalPanel(corner: corner, size: size)
        default:
            let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * config.stackOffset
            origin = cornerOrigin(corner: corner, size: size, padding: config.margin, stackOffset: stackOffsetY)
        }

        newPanel.notificationCorner = corner
        newPanel.setFrameOrigin(origin)
        newPanel.level = .popUpMenu
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.ignoresMouseEvents = false

        let dismissController = DismissController()
        newPanel.dismissController = dismissController
        let view = FloatNotificationView(
            message: message,
            project: project,
            corner: corner,
            onTap: { [weak self] in self?.dismiss(panel: newPanel) },
            dismissController: dismissController
        )
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

    private func makePersistentStatusPanel(item: PersistentStatusItem, index: Int) -> FloatPanel {
        let dismissController = DismissController()
        let hostingView = makeStatusHostingView(item: item, dismissController: dismissController, playsEntryAnimation: true)
        let size = fittingPanelSize(for: hostingView)
        let panel = FloatPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isPersistentStatusPanel = true
        panel.notificationCorner = .bottomRight
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.dismissController = dismissController
        panel.contentView = hostingView
        panel.setFrameOrigin(restoredStatusPanelOrigin(for: size, id: item.id, index: index))
        return panel
    }

    private func updateStatusPanel(_ panel: FloatPanel, item: PersistentStatusItem, playsEntryAnimation: Bool) {
        let dismissController = DismissController()
        let hostingView = makeStatusHostingView(
            item: item,
            dismissController: dismissController,
            playsEntryAnimation: playsEntryAnimation
        )
        let size = fittingPanelSize(for: hostingView)

        panel.dismissController = dismissController
        panel.contentView = hostingView
        panel.setContentSize(size)
    }

    private func makeStatusHostingView(
        item: PersistentStatusItem,
        dismissController: DismissController,
        playsEntryAnimation: Bool
    ) -> NSHostingView<FloatNotificationView> {
        let style = statusStyle(for: item.id)
        return NSHostingView(
            rootView: FloatNotificationView(
                message: item.state.message,
                project: item.project,
                corner: .bottomRight,
                effect: style.effect,
                statusIndicatorColor: item.state.indicatorColor,
                spriteCharacter: style.spriteCharacter,
                animatesStatus: item.state == .running,
                isDraggablePanel: true,
                playsEntryAnimation: playsEntryAnimation,
                dismissController: dismissController
            )
        )
    }

    private func statusStyle(for id: String) -> PersistentStatusStyle {
        let seed = stableSeed(for: id)
        return PersistentStatusStyle(
            effect: statusEffects[seed % statusEffects.count],
            spriteCharacter: statusSpriteCharacters[seed % statusSpriteCharacters.count]
        )
    }

    private func stableSeed(for text: String) -> Int {
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }

    private func fittingPanelSize(for hostingView: NSView) -> CGSize {
        hostingView.layoutSubtreeIfNeeded()
        let size = hostingView.fittingSize
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    private func installStatusMoveObserver(for panel: FloatPanel, id: String) {
        if let observer = statusPanelMoveObservers[id] {
            NotificationCenter.default.removeObserver(observer)
        }

        statusPanelMoveObservers[id] = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self, weak panel] _ in
            guard let origin = panel?.frame.origin else { return }
            self?.saveStatusPanelOrigin(origin, id: id)
        }
    }

    private func removeStatusPanel(id: String) {
        if let observer = statusPanelMoveObservers[id] {
            NotificationCenter.default.removeObserver(observer)
            statusPanelMoveObservers.removeValue(forKey: id)
        }

        if let panel = statusPanels[id] {
            panel.orderOut(nil)
            statusPanels.removeValue(forKey: id)
        }
    }

    private func restoredStatusPanelOrigin(for size: CGSize, id: String, index: Int) -> CGPoint {
        let defaults = UserDefaults.standard
        let defaultOrigin = defaultStatusPanelOrigin(for: size, index: index)
        guard let storedOrigin = defaults.dictionary(forKey: statusPanelOriginKey(for: id)) else {
            return defaultOrigin
        }

        guard let x = storedOrigin["x"] as? Double,
              let y = storedOrigin["y"] as? Double else {
            return defaultOrigin
        }

        return clampedStatusPanelOrigin(CGPoint(x: x, y: y), size: size)
    }

    private func saveStatusPanelOrigin(_ origin: CGPoint, id: String) {
        UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: statusPanelOriginKey(for: id))
    }

    private func hasStoredStatusPanelOrigin(for id: String) -> Bool {
        UserDefaults.standard.dictionary(forKey: statusPanelOriginKey(for: id)) != nil
    }

    private func statusPanelOriginKey(for id: String) -> String {
        statusPanelOriginKeyPrefix + id
    }

    private func defaultStatusPanelOrigin(for size: CGSize, index: Int) -> CGPoint {
        let config = PositionConfigManager.shared.config(for: .bottomRight)
        let stackOffset = CGFloat(index) * (size.height + statusPanelVerticalSpacing)
        return cornerOrigin(corner: .bottomRight, size: size, padding: config.margin, stackOffset: stackOffset)
    }

    private func clampedStatusPanelOrigin(_ origin: CGPoint, size: CGSize) -> CGPoint {
        let candidateRect = CGRect(origin: origin, size: size)
        let screen = NSScreen.screens.first { $0.frame.intersects(candidateRect) } ?? NSScreen.main
        guard let screen else {
            return origin
        }

        let frame = screen.frame
        let minX = frame.minX
        let maxX = frame.maxX - size.width
        let minY = frame.minY
        let maxY = frame.maxY - size.height

        return CGPoint(
            x: min(max(origin.x, minX), maxX),
            y: min(max(origin.y, minY), maxY)
        )
    }

    private func handleHorizontalPanel(size: CGSize) -> (origin: CGPoint, index: Int) {
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

    private func handleVerticalPanel(corner: Corner, size: CGSize) -> CGPoint {
        let config = PositionConfigManager.shared.config(for: corner)
        let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * config.stackOffset
        return cornerOrigin(corner: corner, size: size, padding: config.margin, stackOffset: stackOffsetY)
    }

    private func startCursorTracking(for panel: FloatPanel) {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak panel] timer in
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
        if panel.notificationCorner == .cursorFollow {
            stopCursorTracking(for: panel)
        }

        if let controller = panel.dismissController {
            controller.dismiss { [weak self] in
                panel.orderOut(nil)
                self?.panels.removeAll { $0 === panel }
                self?.repositionPanels()
            }
        } else {
            panel.orderOut(nil)
            panels.removeAll { $0 === panel }
            repositionPanels()
        }
    }

    private func dismissOldest() {
        guard let oldest = panels.first else { return }
        dismiss(panel: oldest)
    }

    private func repositionPanels() {
        for (index, panel) in panels.enumerated() {
            let config = PositionConfigManager.shared.config(for: panel.notificationCorner)
            let offsetY = CGFloat(index) * config.stackOffset
            let size = panel.frame.size
            let newOrigin = cornerOrigin(corner: panel.notificationCorner, size: size, padding: config.margin, stackOffset: offsetY)
            panel.setFrameOrigin(newOrigin)
        }
    }

    private func cornerOrigin(corner: Corner, size: CGSize, padding: CGFloat = 0, stackOffset: CGFloat = 0) -> CGPoint {
        guard let screen = NSScreen.main else {
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
