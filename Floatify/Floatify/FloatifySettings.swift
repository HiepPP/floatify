import Observation
import SwiftUI

enum FloaterTheme: String, CaseIterable {
    case dark
    case light

    var displayName: String {
        switch self {
        case .dark:
            return "Dark"
        case .light:
            return "Light"
        }
    }

    static var current: FloaterTheme {
        FloatifySettings.shared.floaterTheme
    }
}

enum FloaterSize: String, CaseIterable, Equatable {
    case compact
    case regular
    case large
    case larger
    case superLarge

    var displayName: String {
        switch self {
        case .compact:
            return "Compact"
        case .regular:
            return "Regular"
        case .large:
            return "Large"
        case .larger:
            return "Larger"
        case .superLarge:
            return "Super Large"
        }
    }

    var rowHeight: CGFloat {
        switch self {
        case .compact: return 38
        case .regular: return 44
        case .large: return 136
        case .larger: return 162
        case .superLarge: return 190
        }
    }

    var spriteSize: CGFloat {
        switch self {
        case .compact: return 18
        case .regular: return 24
        case .large: return 72
        case .larger: return 86
        case .superLarge: return 102
        }
    }

    var stageSize: CGFloat {
        switch self {
        case .compact: return 24
        case .regular: return 30
        case .large: return 78
        case .larger: return 94
        case .superLarge: return 110
        }
    }

    var dotSize: CGFloat {
        switch self {
        case .compact: return 5
        case .regular: return 6
        case .large: return 12
        case .larger: return 14
        case .superLarge: return 16
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 10
        case .large: return 24
        case .larger: return 28
        case .superLarge: return 32
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 7
        case .regular: return 8
        case .large: return 24
        case .larger: return 28
        case .superLarge: return 32
        }
    }

    var projectFontSize: CGFloat {
        switch self {
        case .compact: return 11.5
        case .regular: return 12.5
        case .large: return 26
        case .larger: return 31
        case .superLarge: return 36
        }
    }

    var metaFontSize: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 9.5
        case .large: return 16
        case .larger: return 18
        case .superLarge: return 20
        }
    }

    var panelWidth: CGFloat {
        switch self {
        case .compact: return 210
        case .regular: return 262
        case .large: return 352
        case .larger: return 420
        case .superLarge: return 492
        }
    }

    var persistentPanelWidth: CGFloat {
        switch self {
        case .compact: return 188
        case .regular: return 236
        case .large: return 560
        case .larger: return 660
        case .superLarge: return 760
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 7
        case .large: return 22
        case .larger: return 26
        case .superLarge: return 30
        }
    }

    var statusRailWidth: CGFloat {
        switch self {
        case .compact: return 4
        case .regular: return 5
        case .large: return 6
        case .larger: return 7
        case .superLarge: return 8
        }
    }

    var closeButtonSize: CGFloat {
        switch self {
        case .compact: return 12
        case .regular: return 13
        case .large: return 32
        case .larger: return 36
        case .superLarge: return 40
        }
    }

    var trailingInset: CGFloat {
        horizontalPadding + 6
    }

    var hoverTrailingInset: CGFloat {
        trailingInset + closeButtonSize + 8
    }

    var avatarHitSize: CGFloat {
        rowHeight
    }

    var persistentStageSize: CGFloat {
        rowHeight
    }

    var persistentSpriteSize: CGFloat {
        max(spriteSize, rowHeight - 8)
    }

    var cardShadowRadius: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 11
        case .large: return 14
        case .larger: return 16
        case .superLarge: return 18
        }
    }

    var statusPillMinWidth: CGFloat {
        switch self {
        case .compact: return 42
        case .regular: return 58
        case .large: return 66
        case .larger: return 78
        case .superLarge: return 90
        }
    }

    var bodySpacing: CGFloat {
        switch self {
        case .compact: return 1
        case .regular: return 2
        case .large: return 6
        case .larger: return 7
        case .superLarge: return 8
        }
    }
}

enum FloaterRenderMode: String, CaseIterable, Equatable {
    case superSlay
    case slay
    case lame

    var displayName: String {
        switch self {
        case .superSlay:
            return "Super Slay"
        case .slay:
            return "Slay"
        case .lame:
            return "Lame"
        }
    }
}

enum FloaterHeaderCPUDisplay: String, CaseIterable, Equatable {
    case off
    case on

    var displayName: String {
        switch self {
        case .off:
            return "Off"
        case .on:
            return "On"
        }
    }
}

@Observable
final class FloatifySettings {
    static let shared = FloatifySettings()
    static let cliSymlinkInstalledKey = "CLISymlinkInstalled"

    private enum Key {
        static let floaterSize = "FloaterSize"
        static let floaterTheme = "FloaterTheme"
        static let floaterRenderMode = "FloaterRenderMode"
        static let floaterHeaderCPUDisplay = "FloaterHeaderCPUDisplay"
        static let selectedVisualPackID = "SelectedVisualPackID"
        static let selectedAvatarID = "SelectedAvatarID"
        static let selectedEffectPresetID = "SelectedEffectPresetID"
        static let idleTimeout = "IdleTimeout"
        static let idleTimeoutMigration = "IdleTimeoutMigratedTo10"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var floaterTheme: FloaterTheme {
        didSet {
            defaults.set(floaterTheme.rawValue, forKey: Key.floaterTheme)
        }
    }

    var floaterSize: FloaterSize {
        didSet {
            defaults.set(floaterSize.rawValue, forKey: Key.floaterSize)
        }
    }

    var floaterRenderMode: FloaterRenderMode {
        didSet {
            defaults.set(floaterRenderMode.rawValue, forKey: Key.floaterRenderMode)
        }
    }

    var floaterHeaderCPUDisplay: FloaterHeaderCPUDisplay {
        didSet {
            defaults.set(floaterHeaderCPUDisplay.rawValue, forKey: Key.floaterHeaderCPUDisplay)
        }
    }

    var selectedVisualPackID: String {
        didSet {
            defaults.set(selectedVisualPackID, forKey: Key.selectedVisualPackID)
        }
    }

    var selectedAvatarID: String {
        didSet {
            defaults.set(selectedAvatarID, forKey: Key.selectedAvatarID)
        }
    }

    var selectedEffectPresetID: String {
        didSet {
            defaults.set(selectedEffectPresetID, forKey: Key.selectedEffectPresetID)
        }
    }

    var idleTimeout: Int {
        didSet {
            let sanitized = max(1, idleTimeout)
            if sanitized != idleTimeout {
                idleTimeout = sanitized
                return
            }
            defaults.set(sanitized, forKey: Key.idleTimeout)
        }
    }

    var idleTimeoutSeconds: TimeInterval {
        TimeInterval(idleTimeout)
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        Self.migrateLegacyIdleTimeoutIfNeeded(defaults: defaults)
        self.floaterTheme = FloaterTheme(rawValue: defaults.string(forKey: Key.floaterTheme) ?? FloaterTheme.dark.rawValue) ?? .dark
        self.floaterSize = FloaterSize(rawValue: defaults.string(forKey: Key.floaterSize) ?? FloaterSize.regular.rawValue) ?? .regular
        self.floaterRenderMode = FloaterRenderMode(rawValue: defaults.string(forKey: Key.floaterRenderMode) ?? FloaterRenderMode.slay.rawValue) ?? .slay
        self.floaterHeaderCPUDisplay = FloaterHeaderCPUDisplay(rawValue: defaults.string(forKey: Key.floaterHeaderCPUDisplay) ?? FloaterHeaderCPUDisplay.off.rawValue) ?? .off
        self.selectedVisualPackID = defaults.string(forKey: Key.selectedVisualPackID) ?? FloaterVisualConstants.builtInPackID
        self.selectedAvatarID = defaults.string(forKey: Key.selectedAvatarID) ?? FloaterVisualConstants.autoAvatarID
        self.selectedEffectPresetID = defaults.string(forKey: Key.selectedEffectPresetID) ?? FloaterVisualConstants.defaultEffectPresetID

        let storedIdleTimeout = defaults.integer(forKey: Key.idleTimeout)
        self.idleTimeout = storedIdleTimeout > 0 ? storedIdleTimeout : 10

        normalizeVisualSelection()
    }

    private static func migrateLegacyIdleTimeoutIfNeeded(defaults: UserDefaults) {
        guard !defaults.bool(forKey: Key.idleTimeoutMigration) else { return }

        if defaults.object(forKey: Key.idleTimeout) == nil || defaults.integer(forKey: Key.idleTimeout) == 15 {
            defaults.set(10, forKey: Key.idleTimeout)
        }

        defaults.set(true, forKey: Key.idleTimeoutMigration)
    }

    func normalizeVisualSelection(catalog: FloaterVisualCatalog = .shared) {
        let resolvedPack = catalog.resolvedPack(id: selectedVisualPackID)
        if selectedVisualPackID != resolvedPack.id {
            selectedVisualPackID = resolvedPack.id
        }

        if !resolvedPack.avatars.contains(where: { $0.id == selectedAvatarID }) {
            selectedAvatarID = resolvedPack.defaultAvatarID
        }

        if !resolvedPack.effectPresets.contains(where: { $0.id == selectedEffectPresetID }) {
            selectedEffectPresetID = resolvedPack.defaultEffectPresetID
        }
    }

    func selectVisualPack(_ packID: String, catalog: FloaterVisualCatalog = .shared) {
        selectedVisualPackID = packID
        normalizeVisualSelection(catalog: catalog)
    }
}
