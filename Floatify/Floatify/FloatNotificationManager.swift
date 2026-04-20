import AppKit
import Observation
import SwiftUI

class FloatPanel: NSPanel {
    var horizontalIndex: Int = 0
    var notificationCorner: Corner = .bottomRight
    var dismissController: DismissController?
    var isPersistentStatusPanel = false
    var temporaryMessage: String?
    var temporaryProject: String?

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

enum ClaudeStatusState: Equatable {
    case running
    case committing
    case pushing
    case idle
    case complete

    var isProgressState: Bool {
        switch self {
        case .running, .committing, .pushing:
            return true
        case .idle, .complete:
            return false
        }
    }

    var animatesIndicator: Bool {
        isProgressState || self == .idle
    }

    var message: String {
        switch self {
        case .running:
            return "Still running"
        case .committing:
            return "Committing changes"
        case .pushing:
            return "Pushing changes"
        case .idle:
            return "Idle"
        case .complete:
            return "Complete"
        }
    }

    var indicatorColor: Color {
        switch self {
        case .running:
            return FloaterPalette.running
        case .committing:
            return FloaterPalette.committing
        case .pushing:
            return FloaterPalette.pushing
        case .idle:
            return FloaterPalette.idle
        case .complete:
            return FloaterPalette.complete
        }
    }
}

struct PersistentStatusItem: Identifiable {
    let id: String
    let project: String
    let projectPath: String?
    let state: ClaudeStatusState
    let lastActivity: Date
    let modifiedFilesCount: Int
}

struct FloaterPanelItem: Identifiable {
    let item: PersistentStatusItem
    let dismissController: DismissController
    let playsEntryAnimation: Bool
    let shouldShake: Bool
    let effect: String
    let avatar: FloaterAvatarDefinition?
    let effectPreset: FloaterEffectPreset
    let floaterSize: FloaterSize
    let renderMode: FloaterRenderMode

    var id: String { item.id }
}

private struct PersistentStatusStyle {
    let effect: String
    let avatar: FloaterAvatarDefinition?
    let effectPreset: FloaterEffectPreset
}

class FloatNotificationManager {
    static let shared = FloatNotificationManager()

    private let settings = FloatifySettings.shared
    private let visualCatalog = FloaterVisualCatalog.shared
    private var panels: [FloatPanel] = []
    private var cursorFollowTimers: [FloatPanel: Timer] = [:]
    private var floaterPanel: FloatPanel?
    private var floaterHostingView: NSHostingView<FloaterPanelView>?
    private var floaterPanelMoveObserver: NSObjectProtocol?
    private var visualCatalogObserver: NSObjectProtocol?
    private var currentStatusItemsByID: [String: PersistentStatusItem] = [:]
    private var floaterDismissControllers: [String: DismissController] = [:]
    private var hiddenStatusPanelIDs: Set<String> = []
    private var closingStatusPanelIDs: Set<String> = []
    private let maxPanels = 8
    private let maxHorizontalPanels = 5
    private let horizontalStackOffset: CGFloat = 8
    private let floaterPanelSpacing: CGFloat = 6
    private let floaterPanelOriginKey = "FloaterPanelOrigin"
    private let floaterPanelCollapsedKey = "FloaterPanelCollapsed"
    private let floaterPanelAnimationDuration: TimeInterval = 0.38
    private let floaterPanelSpringDamping: CGFloat = 0.82
    private let floaterPanelSpringVelocity: CGFloat = 0.45
    private let statusEffects = ["slide", "fade", "dropdown", "marquee", "trail"]
    private var isFloaterPanelCollapsed: Bool

    private init() {
        isFloaterPanelCollapsed = UserDefaults.standard.bool(forKey: floaterPanelCollapsedKey)
        observeSettings()
        observeVisualCatalog()
    }

    deinit {
        if let visualCatalogObserver {
            NotificationCenter.default.removeObserver(visualCatalogObserver)
        }
    }

    func show(message: String, corner: Corner, duration: TimeInterval = 6, project: String?) {
        NSLog("Floatify: show() called - message: %@, corner: %@, duration: %.1f, project: %@", message, corner.rawValue, duration, project ?? "nil")
        DispatchQueue.main.async {
            let effectiveCorner: Corner = corner == .cursorFollow ? .bottomRight : corner
            self.createPanel(message: message, corner: effectiveCorner, duration: duration, project: project)
        }
    }

    func showPersistentStatuses(_ items: [PersistentStatusItem]) {
        DispatchQueue.main.async {
            let activeIDs = Set(items.map(\.id))
            self.hiddenStatusPanelIDs.formIntersection(activeIDs)
            self.closingStatusPanelIDs.formIntersection(activeIDs)
            self.floaterDismissControllers = self.floaterDismissControllers.filter { activeIDs.contains($0.key) }

            let visibleItems = items
                .filter { !self.hiddenStatusPanelIDs.contains($0.id) }
                .sorted(by: Self.sortPersistentItems(_:_:))
            let previousItemsByID = self.currentStatusItemsByID
            let previousIDs = Set(previousItemsByID.keys)

            // Shake when an item enters idle (yellow) from any non-idle state - i.e., Claude just finished
            let shakingItemIDs = Set(visibleItems.filter { item in
                guard let previous = previousItemsByID[item.id] else { return false }
                return previous.state != .idle && item.state == .idle
            }.map(\.id))

            self.currentStatusItemsByID = Dictionary(uniqueKeysWithValues: visibleItems.map { ($0.id, $0) })
            self.refreshFloaterPanel(
                animatedItemIDs: Set(visibleItems.map(\.id)).subtracting(previousIDs),
                shakingItemIDs: shakingItemIDs
            )
        }
    }

    func arrangePersistentStatuses() {
        DispatchQueue.main.async {
            guard let panel = self.floaterPanel else { return }
            let origin = self.defaultFloaterPanelOrigin(for: panel.frame.size)
            panel.setFrameOrigin(origin)
            self.saveFloaterPanelOrigin(origin)
            panel.orderFrontRegardless()
        }
    }

    private static func sortPersistentItems(_ lhs: PersistentStatusItem, _ rhs: PersistentStatusItem) -> Bool {
        if lhs.project.localizedCaseInsensitiveCompare(rhs.project) == .orderedSame {
            return lhs.id < rhs.id
        }
        return lhs.project.localizedCaseInsensitiveCompare(rhs.project) == .orderedAscending
    }

    private func createPanel(message: String, corner: Corner, duration: TimeInterval, project: String?) {
        NSLog("Floatify: createPanel() called - panels.count: %d", panels.count)
        if panels.count >= maxPanels {
            dismissOldest()
        }

        NSLog("Floatify: Getting config for corner: %@", corner.rawValue)
        let config = PositionConfigManager.shared.config(for: corner)
        NSLog("Floatify: Config - width: %.1f, height: %.1f", config.width, config.height)
        let size = CGSize(width: config.width, height: config.height)
        NSLog("Floatify: Creating FloatPanel")
        let origin: CGPoint
        let newPanel = makeBasePanel(size: size)
        NSLog("Floatify: FloatPanel created successfully")

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
            NSLog("Floatify: Using default corner handling")
            let stackOffsetY = CGFloat(panels.filter { $0.horizontalIndex == 0 }.count) * config.stackOffset
            origin = cornerOrigin(corner: corner, size: size, padding: config.margin, stackOffset: stackOffsetY)
        }
        NSLog("Floatify: Origin calculated: %@", NSStringFromPoint(origin))

        newPanel.notificationCorner = corner
        newPanel.setFrameOrigin(origin)
        let dismissController = DismissController()
        newPanel.dismissController = dismissController
        newPanel.temporaryMessage = message
        newPanel.temporaryProject = project
        newPanel.contentView = makeTemporaryNotificationHostingView(
            message: message,
            project: project,
            corner: corner,
            dismissController: dismissController
        )
        newPanel.orderFront(nil)
        NSLog("Floatify: Panel ordered front at origin: %@", NSStringFromPoint(origin))
        panels.append(newPanel)

        if corner == .cursorFollow {
            startCursorTracking(for: newPanel)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            guard let self = self else { return }
            self.dismiss(panel: newPanel)
        }
    }

    private func refreshFloaterPanel(animatedItemIDs: Set<String> = [], shakingItemIDs: Set<String> = [], animated: Bool = false) {
        let items = currentStatusItemsByID.values.sorted(by: Self.sortPersistentItems(_:_:))
        guard !items.isEmpty else {
            removeFloaterPanel()
            return
        }

        let floaterItems = items.map { item in
            let style = statusStyle(for: item)
            return FloaterPanelItem(
                item: item,
                dismissController: floaterDismissController(for: item.id),
                playsEntryAnimation: animatedItemIDs.contains(item.id),
                shouldShake: shakingItemIDs.contains(item.id),
                effect: style.effect,
                avatar: style.avatar,
                effectPreset: style.effectPreset,
                floaterSize: floaterSize,
                renderMode: settings.floaterRenderMode
            )
        }

        let hostingView = makeFloaterPanelHostingView(items: floaterItems)
        let size = fittingPanelSize(for: hostingView)

        if let panel = floaterPanel {
            resizeFloaterPanel(panel, to: size, animated: animated)
            panel.orderFrontRegardless()
            return
        }

        let panel = makeBasePanel(size: size)

        panel.isPersistentStatusPanel = true
        panel.notificationCorner = .bottomRight
        panel.hidesOnDeactivate = false
        panel.contentView = hostingView
        panel.setFrameOrigin(restoredFloaterPanelOrigin(for: size))

        floaterPanel = panel
        installFloaterPanelMoveObserver(for: panel)
        panel.orderFrontRegardless()
    }

    private func makeFloaterPanelHostingView(items: [FloaterPanelItem]) -> NSHostingView<FloaterPanelView> {
        let rootView = FloaterPanelView(
            items: items,
            spacing: floaterPanelSpacing,
            isCollapsed: isFloaterPanelCollapsed,
            onToggleCollapsed: { [weak self] in
                self?.toggleFloaterPanelCollapsed()
            },
            onItemTap: { [weak self] item in
                self?.openProjectInVSCode(for: item)
            },
            onItemClose: { [weak self] item in
                self?.closePersistentStatusPanel(id: item.id)
            }
        )

        if let view = floaterHostingView {
            view.rootView = rootView
            return view
        }

        let view = NSHostingView(rootView: rootView)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.isOpaque = false
        floaterHostingView = view
        return view
    }

    private func toggleFloaterPanelCollapsed() {
        isFloaterPanelCollapsed.toggle()
        UserDefaults.standard.set(isFloaterPanelCollapsed, forKey: floaterPanelCollapsedKey)
        refreshFloaterPanel()
    }

    private func floaterDismissController(for id: String) -> DismissController {
        if let controller = floaterDismissControllers[id] {
            controller.shouldDismiss = false
            controller.onDismissComplete = nil
            return controller
        }

        let controller = DismissController()
        floaterDismissControllers[id] = controller
        return controller
    }

    private var floaterSize: FloaterSize {
        settings.floaterSize
    }

    private func observeSettings() {
        withObservationTracking {
            _ = settings.floaterSize
            _ = settings.floaterTheme
            _ = settings.floaterRenderMode
            _ = settings.selectedVisualPackID
            _ = settings.selectedAvatarID
            _ = settings.selectedEffectPresetID
        } onChange: {
            Task { @MainActor in
                let manager = FloatNotificationManager.shared
                manager.handleSettingsChange()
                manager.observeSettings()
            }
        }
    }

    private func observeVisualCatalog() {
        visualCatalogObserver = NotificationCenter.default.addObserver(
            forName: .floaterVisualCatalogDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }
    }

    private func handleSettingsChange() {
        settings.normalizeVisualSelection(catalog: visualCatalog)
        refreshFloaterPanel(animated: true)
        refreshTemporaryPanels()
    }

    private func statusStyle(for item: PersistentStatusItem) -> PersistentStatusStyle {
        let seed = stableSeed(for: item.id)
        let effect = statusEffects[seed % statusEffects.count]
        let avatarSeed = item.project.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? item.id : item.project
        let resolvedStyle = visualCatalog.resolveStyle(
            packID: settings.selectedVisualPackID,
            avatarID: settings.selectedAvatarID,
            effectPresetID: settings.selectedEffectPresetID,
            seedText: avatarSeed
        )

        return PersistentStatusStyle(
            effect: effect,
            avatar: settings.floaterRenderMode == .lame ? nil : resolvedStyle.avatar,
            effectPreset: resolvedStyle.effectPreset
        )
    }

    private func stableSeed(for text: String) -> Int {
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }

    private func openProjectInVSCode(for item: PersistentStatusItem) {
        NSLog("Floatify: openProjectInVSCode called for %@, projectPath: %@", item.id, item.projectPath ?? "nil")

        guard let projectPath = item.projectPath else {
            NSLog("Floatify: Cannot open project - projectPath is nil for %@", item.id)
            return
        }

        guard FileManager.default.fileExists(atPath: projectPath) else {
            NSLog("Floatify: Cannot open project - path does not exist: %@", projectPath)
            return
        }

        let projectURL = URL(fileURLWithPath: projectPath, isDirectory: true)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        guard let appURL = preferredVSCodeApplicationURL() else {
            NSLog("Floatify: No VS Code found, opening with default application")
            NSWorkspace.shared.open(projectURL)
            return
        }

        NSLog("Floatify: Opening %@ in VS Code (%@)", projectPath, appURL.path)
        NSWorkspace.shared.open([projectURL], withApplicationAt: appURL, configuration: configuration) { _, error in
            if let error {
                NSLog("Floatify: Failed to open project in VS Code for %@ - %@", item.id, error.localizedDescription)
            } else {
                NSLog("Floatify: Successfully opened %@ in VS Code", projectPath)
            }
        }
    }

    private func preferredVSCodeApplicationURL() -> URL? {
        let bundleIdentifiers = [
            "com.microsoft.VSCode",
            "com.microsoft.VSCodeInsiders",
            "com.vscodium"
        ]

        for bundleIdentifier in bundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                return appURL
            }
        }

        return nil
    }

    private func makeBasePanel(size: CGSize) -> FloatPanel {
        let panel = FloatPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        configureBasePanel(panel)
        return panel
    }

    private func configureBasePanel(_ panel: FloatPanel) {
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
    }

    private func makeTemporaryNotificationHostingView(
        message: String,
        project: String?,
        corner: Corner,
        dismissController: DismissController,
        playsEntryAnimation: Bool = true
    ) -> NSHostingView<FloatNotificationView> {
        let resolvedStyle = visualCatalog.resolveStyle(
            packID: settings.selectedVisualPackID,
            avatarID: settings.selectedAvatarID,
            effectPresetID: settings.selectedEffectPresetID,
            seedText: project ?? message
        )

        return NSHostingView(
            rootView: FloatNotificationView(
                message: message,
                project: project,
                corner: corner,
                avatar: resolvedStyle.avatar,
                playsEntryAnimation: playsEntryAnimation,
                renderMode: settings.floaterRenderMode,
                effectPreset: resolvedStyle.effectPreset,
                dismissController: dismissController
            )
        )
    }

    private func refreshTemporaryPanels() {
        for panel in panels {
            guard let message = panel.temporaryMessage,
                  let dismissController = panel.dismissController else {
                continue
            }

            panel.contentView = makeTemporaryNotificationHostingView(
                message: message,
                project: panel.temporaryProject,
                corner: panel.notificationCorner,
                dismissController: dismissController,
                playsEntryAnimation: false
            )
            panel.orderFrontRegardless()
        }
    }

    private func fittingPanelSize(for hostingView: NSView) -> CGSize {
        hostingView.layoutSubtreeIfNeeded()
        let size = hostingView.fittingSize
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

    private func installFloaterPanelMoveObserver(for panel: FloatPanel) {
        if let observer = floaterPanelMoveObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        floaterPanelMoveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self, weak panel] _ in
            guard let origin = panel?.frame.origin else { return }
            self?.saveFloaterPanelOrigin(origin)
        }
    }

    private func removeFloaterPanel() {
        if let observer = floaterPanelMoveObserver {
            NotificationCenter.default.removeObserver(observer)
            floaterPanelMoveObserver = nil
        }

        if let panel = floaterPanel {
            panel.orderOut(nil)
            floaterPanel = nil
        }
        floaterHostingView = nil

        isFloaterPanelCollapsed = false
        UserDefaults.standard.set(false, forKey: floaterPanelCollapsedKey)
    }

    private func closePersistentStatusPanel(id: String) {
        guard currentStatusItemsByID[id] != nil, !closingStatusPanelIDs.contains(id) else {
            return
        }

        hiddenStatusPanelIDs.insert(id)
        closingStatusPanelIDs.insert(id)

        if let controller = floaterDismissControllers[id] {
            controller.dismiss { [weak self] in
                self?.finalizeClosePersistentStatusPanel(id: id)
            }
        } else {
            finalizeClosePersistentStatusPanel(id: id)
        }
    }

    private func finalizeClosePersistentStatusPanel(id: String) {
        currentStatusItemsByID.removeValue(forKey: id)
        floaterDismissControllers.removeValue(forKey: id)
        closingStatusPanelIDs.remove(id)
        refreshFloaterPanel()
    }

    private func resizeFloaterPanel(_ panel: FloatPanel, to size: CGSize, animated: Bool = false) {
        let origin = clampedFloaterPanelOrigin(
            CGPoint(x: panel.frame.maxX - size.width, y: panel.frame.minY),
            size: size
        )
        let frame = NSRect(origin: origin, size: size)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = floaterPanelAnimationDuration
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 0.0, 0.30, 1.0)
                panel.animator().setFrame(frame, display: true)
            } completionHandler: {
                panel.setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }

        saveFloaterPanelOrigin(origin)
    }

    private func restoredFloaterPanelOrigin(for size: CGSize) -> CGPoint {
        let defaults = UserDefaults.standard
        let defaultOrigin = defaultFloaterPanelOrigin(for: size)
        guard let storedOrigin = defaults.dictionary(forKey: floaterPanelOriginKey) else {
            return defaultOrigin
        }

        guard let x = storedOrigin["x"] as? Double,
              let y = storedOrigin["y"] as? Double else {
            return defaultOrigin
        }

        return clampedFloaterPanelOrigin(CGPoint(x: x, y: y), size: size)
    }

    private func saveFloaterPanelOrigin(_ origin: CGPoint) {
        UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: floaterPanelOriginKey)
    }

    private func defaultFloaterPanelOrigin(for size: CGSize) -> CGPoint {
        let config = PositionConfigManager.shared.config(for: .bottomRight)
        return cornerOrigin(corner: .bottomRight, size: size, padding: config.margin)
    }

    private func clampedFloaterPanelOrigin(_ origin: CGPoint, size: CGSize) -> CGPoint {
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
        var lastOrigin = panel.frame.origin
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak panel] timer in
            guard let panel = panel, panel.isVisible else {
                timer.invalidate()
                return
            }
            let newOrigin = CursorTracker.shared.screenCornerPosition(for: .cursorFollow, panelSize: panel.frame.size)
            guard abs(newOrigin.x - lastOrigin.x) >= 0.5 || abs(newOrigin.y - lastOrigin.y) >= 0.5 else {
                return
            }
            panel.setFrameOrigin(newOrigin)
            lastOrigin = newOrigin
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
