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

    // Lower value wins when merging sessions of the same project into one tab.
    var mergePriority: Int {
        switch self {
        case .running:
            return 0
        case .idle:
            return 1
        case .complete:
            return 2
        }
    }

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

struct PersistentStatusStateResolver {
    static func rawState(
        storedState: ClaudeStatusState?,
        storedActivity: Date? = nil,
        monitoredState: ClaudeStatusState,
        monitoredActivity: Date? = nil,
        isTaskStateKnown: Bool
    ) -> ClaudeStatusState {
        if isTaskStateKnown {
            if let storedState,
               let storedActivity,
               let monitoredActivity,
               (storedState == .running || monitoredState == .running) {
                return storedActivity >= monitoredActivity ? storedState : monitoredState
            }

            if monitoredState == .running {
                return .running
            }

            if storedState == .running {
                return .running
            }

            return monitoredState
        }

        return storedState ?? monitoredState
    }
}

struct CompletionAcknowledgementTracker {
    private var acknowledgedCompletionIDs: Set<String> = []

    mutating func markRunning(sessionID: String) {
        acknowledgedCompletionIDs.remove(sessionID)
    }

    mutating func markCompleted(sessionID: String) {
        acknowledgedCompletionIDs.remove(sessionID)
    }

    mutating func acknowledge(sessionID: String) {
        acknowledgedCompletionIDs.insert(sessionID)
    }

    mutating func prune(activeIDs: Set<String>) {
        acknowledgedCompletionIDs.formIntersection(activeIDs)
    }

    func visibleState(for state: ClaudeStatusState, sessionID: String) -> ClaudeStatusState {
        switch state {
        case .running:
            return .running
        case .idle, .complete:
            return acknowledgedCompletionIDs.contains(sessionID) ? .complete : .idle
        }
    }
}

struct FloaterPanelItem: Identifiable {
    let item: PersistentStatusItem
    let dismissController: DismissController
    let playsEntryAnimation: Bool
    let shouldShake: Bool
    let effect: String
    let avatar: FloaterAvatarDefinition?
    let effectPreset: FloaterEffectPreset
    let stylePreset: FloaterStylePreset
    let floaterSize: FloaterSize
    let renderMode: FloaterRenderMode
    let limitRunningRenderEffects: Bool
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
    private let styleCatalog = FloaterStyleCatalog.shared
    private var floaterPanel: FloatPanel?
    private var floaterHostingView: NSHostingView<FloaterPanelView>?
    private var floaterPanelMoveObserver: NSObjectProtocol?
    private var visualCatalogObserver: NSObjectProtocol?
    private var styleCatalogObserver: NSObjectProtocol?
    private var currentStatusItemsByID: [String: PersistentStatusItem] = [:]
    private var floaterDismissControllers: [String: DismissController] = [:]
    private var hiddenStatusPanelIDs: Set<String> = []
    private var closingStatusPanelIDs: Set<String> = []
    private var onItemAvatarTap: ((PersistentStatusItem) -> Void)?
    private let floaterPanelSpacing: CGFloat = 6
    private let floaterPanelOriginKey = "FloaterPanelOrigin"
    private let floaterPanelCollapsedKey = "FloaterPanelCollapsed"
    private let floaterPanelAnimationDuration: TimeInterval = 0.38
    private let floaterPanelSpringDamping: CGFloat = 0.82
    private let floaterPanelSpringVelocity: CGFloat = 0.45
    private var isFloaterPanelCollapsed: Bool

    private init() {
        isFloaterPanelCollapsed = UserDefaults.standard.bool(forKey: floaterPanelCollapsedKey)
        observeSettings()
        observeVisualCatalog()
        observeStyleCatalog()
    }

    deinit {
        if let visualCatalogObserver {
            NotificationCenter.default.removeObserver(visualCatalogObserver)
        }
        if let styleCatalogObserver {
            NotificationCenter.default.removeObserver(styleCatalogObserver)
        }
    }

    func showPersistentStatuses(
        _ items: [PersistentStatusItem],
        onItemAvatarTap: ((PersistentStatusItem) -> Void)? = nil
    ) {
        DispatchQueue.main.async {
            self.onItemAvatarTap = onItemAvatarTap
            let items = Self.mergedItemsByProject(items)
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

    // One tab per project name. The session with the worst state
    // (running > idle > complete) represents the project; ties pick the
    // latest activity. The representative keeps its own id so tap and
    // close-by-id still work.
    private static func mergedItemsByProject(_ items: [PersistentStatusItem]) -> [PersistentStatusItem] {
        var representativeByProject: [String: PersistentStatusItem] = [:]
        var maxModifiedFilesByProject: [String: Int] = [:]

        for item in items {
            let key = item.project.localizedLowercase
            maxModifiedFilesByProject[key] = max(maxModifiedFilesByProject[key] ?? 0, item.modifiedFilesCount)

            guard let current = representativeByProject[key] else {
                representativeByProject[key] = item
                continue
            }

            if item.state.mergePriority < current.state.mergePriority
                || (item.state.mergePriority == current.state.mergePriority
                    && item.lastActivity > current.lastActivity) {
                representativeByProject[key] = item
            }
        }

        return representativeByProject.map { key, item in
            PersistentStatusItem(
                id: item.id,
                project: item.project,
                projectPath: item.projectPath,
                state: item.state,
                lastActivity: item.lastActivity,
                modifiedFilesCount: maxModifiedFilesByProject[key] ?? item.modifiedFilesCount
            )
        }
    }

    private static func sortPersistentItems(_ lhs: PersistentStatusItem, _ rhs: PersistentStatusItem) -> Bool {
        if lhs.project.localizedCaseInsensitiveCompare(rhs.project) == .orderedSame {
            return lhs.id < rhs.id
        }
        return lhs.project.localizedCaseInsensitiveCompare(rhs.project) == .orderedAscending
    }

    private func refreshFloaterPanel(
        animatedItemIDs: Set<String> = [],
        shakingItemIDs: Set<String> = [],
        animated: Bool = false
    ) {
        let items = currentStatusItemsByID.values.sorted(by: Self.sortPersistentItems(_:_:))
        guard !items.isEmpty else {
            removeFloaterPanel()
            return
        }

        let runningIDs = items
            .filter { $0.state == .running }
            .map(\.id)
        let runningIndexByID = Dictionary(uniqueKeysWithValues: runningIDs.enumerated().map { ($0.element, $0.offset) })
        let stylePreset = styleCatalog.resolvedPreset(id: settings.selectedFloaterStyleID)

        let floaterItems = items.map { item in
            let style = statusStyle(for: item, stylePreset: stylePreset)
            return FloaterPanelItem(
                item: item,
                dismissController: floaterDismissController(for: item.id),
                playsEntryAnimation: animatedItemIDs.contains(item.id),
                shouldShake: shakingItemIDs.contains(item.id),
                effect: style.effect,
                avatar: style.avatar,
                effectPreset: style.effectPreset,
                stylePreset: stylePreset,
                floaterSize: floaterSize,
                renderMode: settings.floaterRenderMode,
                limitRunningRenderEffects: settings.limitRunningRenderEffects,
                runningPanelCount: runningIDs.count,
                runningPanelIndex: runningIndexByID[item.id]
            )
        }

        let hostingView = makeFloaterPanelHostingView(
            items: floaterItems,
            stylePreset: stylePreset
        )
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

    private func makeFloaterPanelHostingView(
        items: [FloaterPanelItem],
        stylePreset: FloaterStylePreset
    ) -> NSHostingView<FloaterPanelView> {
        let rootView = FloaterPanelView(
            items: items,
            spacing: floaterPanelSpacing,
            isCollapsed: isFloaterPanelCollapsed,
            showsCPUInHeader: settings.floaterHeaderCPUDisplay == .on,
            stylePreset: stylePreset,
            onToggleCollapsed: { [weak self] in
                self?.toggleFloaterPanelCollapsed()
            },
            onOpenSettings: {
                FloatifySettingsWindowPresenter.shared.show()
            },
            onItemTap: { [weak self] item in
                self?.onItemAvatarTap?(item)
                self?.openProjectInHostApp(for: item)
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
            _ = settings.limitRunningRenderEffects
            _ = settings.floaterHeaderCPUDisplay
            _ = settings.selectedFloaterStyleID
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

    private func observeStyleCatalog() {
        styleCatalogObserver = NotificationCenter.default.addObserver(
            forName: .floaterStyleCatalogDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSettingsChange()
        }
    }

    private func handleSettingsChange() {
        settings.normalizeVisualSelection(catalog: visualCatalog)
        settings.normalizeStyleSelection(catalog: styleCatalog)
        refreshFloaterPanel(animated: true)
    }

    private func statusStyle(
        for item: PersistentStatusItem,
        stylePreset: FloaterStylePreset
    ) -> PersistentStatusStyle {
        let seed = stableSeed(for: item.id)
        let statusEffects = stylePreset.variants.effects.entryEffects.isEmpty
            ? FloaterStyleVariants().effects.entryEffects
            : stylePreset.variants.effects.entryEffects
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

    /// Route a floater click to the app that hosts the session's terminal.
    /// Atelier gets a deep link, VS Code gets the folder, any other host app is
    /// activated. Unknown hosts fall back to the historical VS Code behavior.
    private func openProjectInHostApp(for item: PersistentStatusItem) {
        let hostApp = sessionHostApplication(for: item)
        let hostBundleID = hostApp?.bundleIdentifier

        if hostBundleID == "app.atelier.Atelier", let hostApp,
           openProjectInAtelier(for: item, runningInstance: hostApp) {
            return
        }

        let vsCodeBundleIDs = ["com.microsoft.VSCode", "com.microsoft.VSCodeInsiders", "com.vscodium"]
        if let hostBundleID, !vsCodeBundleIDs.contains(hostBundleID) {
            if let hostApp {
                NSLog("Floatify: Activating host app %@ for %@", hostBundleID, item.id)
                hostApp.activate()
                return
            }
        }

        openProjectInVSCode(for: item)
    }

    /// Walk the session's parent-process chain to the first GUI application.
    private func sessionHostApplication(for item: PersistentStatusItem) -> NSRunningApplication? {
        guard let pidText = item.id.split(separator: ":").last,
              let sessionPID = pid_t(pidText) else {
            return nil
        }
        var pid = sessionPID
        for _ in 0..<15 {
            guard let parent = Self.parentPID(of: pid), parent > 1 else { return nil }
            if let app = NSRunningApplication(processIdentifier: parent),
               let bundleID = app.bundleIdentifier,
               bundleID != Bundle.main.bundleIdentifier {
                return app
            }
            pid = parent
        }
        return nil
    }

    private static func parentPID(of pid: pid_t) -> pid_t? {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        let ppid = info.kp_eproc.e_ppid
        return ppid > 0 ? ppid : nil
    }

    /// Open the project via the atelier:// deep link, delivered to the bundle of
    /// the already-running instance. Letting Launch Services pick the handler can
    /// resolve to a different Atelier copy on disk and spawn a second instance.
    private func openProjectInAtelier(
        for item: PersistentStatusItem,
        runningInstance: NSRunningApplication
    ) -> Bool {
        guard let projectPath = item.projectPath,
              FileManager.default.fileExists(atPath: projectPath),
              let appURL = runningInstance.bundleURL,
              var components = URLComponents(string: "atelier://open") else {
            return false
        }
        components.queryItems = [URLQueryItem(name: "path", value: projectPath)]
        guard let url = components.url else { return false }
        NSLog("Floatify: Opening %@ in running Atelier at %@", projectPath, appURL.path)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
            if let error {
                NSLog("Floatify: Atelier deep link failed for %@ - %@", item.id, error.localizedDescription)
            }
        }
        return true
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
