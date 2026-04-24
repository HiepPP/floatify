import AppKit
import Observation
import SwiftUI

class FloatPanel: NSPanel {
    var dismissController: DismissController?
    var isPersistentStatusPanel = false

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}

enum ClaudeStatusState: Equatable {
    case running
    case idle
    case complete

    var isProgressState: Bool {
        switch self {
        case .running:
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
    let runningPanelCount: Int
    let runningPanelIndex: Int?

    var id: String { item.id }
}

private struct PersistentStatusStyle {
    let effect: String
    let avatar: FloaterAvatarDefinition?
    let effectPreset: FloaterEffectPreset
}

class FloaterPanelManager {
    static let shared = FloaterPanelManager()

    private let settings = FloatifySettings.shared
    private let visualCatalog = FloaterVisualCatalog.shared
    private var floaterPanel: FloatPanel?
    private var floaterHostingView: NSHostingView<FloaterPanelView>?
    private var floaterPanelMoveObserver: NSObjectProtocol?
    private var visualCatalogObserver: NSObjectProtocol?
    private var currentStatusItemsByID: [String: PersistentStatusItem] = [:]
    private var floaterDismissControllers: [String: DismissController] = [:]
    private var hiddenStatusPanelIDs: Set<String> = []
    private var closingStatusPanelIDs: Set<String> = []
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

    private func refreshFloaterPanel(animatedItemIDs: Set<String> = [], shakingItemIDs: Set<String> = [], animated: Bool = false) {
        let items = currentStatusItemsByID.values.sorted(by: Self.sortPersistentItems(_:_:))
        guard !items.isEmpty else {
            removeFloaterPanel()
            return
        }

        let runningIDs = items
            .filter { $0.state == .running }
            .map(\.id)
        let runningIndexByID = Dictionary(uniqueKeysWithValues: runningIDs.enumerated().map { ($0.element, $0.offset) })

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
                renderMode: settings.floaterRenderMode,
                runningPanelCount: runningIDs.count,
                runningPanelIndex: runningIndexByID[item.id]
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
            showsCPUInHeader: settings.floaterHeaderCPUDisplay == .on,
            onToggleCollapsed: { [weak self] in
                self?.toggleFloaterPanelCollapsed()
            },
            onOpenSettings: {
                FloatifySettingsWindowPresenter.shared.show()
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
            _ = settings.floaterHeaderCPUDisplay
            _ = settings.selectedVisualPackID
            _ = settings.selectedAvatarID
            _ = settings.selectedEffectPresetID
        } onChange: {
            Task { @MainActor in
                let manager = FloaterPanelManager.shared
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
    }

    private func statusStyle(for item: PersistentStatusItem) -> PersistentStatusStyle {
        let seed = stableSeed(for: item.id)
        let effect = statusEffects[seed % statusEffects.count]
        let resolvedStyle = visualCatalog.resolveStyle(
            packID: settings.selectedVisualPackID,
            avatarID: settings.selectedAvatarID,
            effectPresetID: settings.selectedEffectPresetID,
            seedText: item.id
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
        let origin = CGPoint(x: panel.frame.maxX - size.width, y: panel.frame.minY)
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

        return CGPoint(x: x, y: y)
    }

    private func saveFloaterPanelOrigin(_ origin: CGPoint) {
        UserDefaults.standard.set(["x": origin.x, "y": origin.y], forKey: floaterPanelOriginKey)
    }

    private func defaultFloaterPanelOrigin(for size: CGSize) -> CGPoint {
        let screen = NSScreen.main?.visibleFrame ?? NSScreen.main?.frame ?? .zero
        return CGPoint(
            x: screen.maxX - size.width - 10,
            y: screen.minY + 10
        )
    }

}
