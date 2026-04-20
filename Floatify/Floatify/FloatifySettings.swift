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
        case .large: return 56
        case .larger: return 68
        case .superLarge: return 80
        }
    }

    var spriteSize: CGFloat {
        switch self {
        case .compact: return 18
        case .regular: return 24
        case .large: return 36
        case .larger: return 44
        case .superLarge: return 52
        }
    }

    var stageSize: CGFloat {
        switch self {
        case .compact: return 24
        case .regular: return 30
        case .large: return 44
        case .larger: return 52
        case .superLarge: return 60
        }
    }

    var dotSize: CGFloat {
        switch self {
        case .compact: return 5
        case .regular: return 6
        case .large: return 9
        case .larger: return 10
        case .superLarge: return 12
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 10
        case .large: return 14
        case .larger: return 16
        case .superLarge: return 18
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 7
        case .regular: return 8
        case .large: return 12
        case .larger: return 14
        case .superLarge: return 16
        }
    }

    var projectFontSize: CGFloat {
        switch self {
        case .compact: return 11.5
        case .regular: return 12.5
        case .large: return 14.5
        case .larger: return 16
        case .superLarge: return 18
        }
    }

    var metaFontSize: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 9.5
        case .large: return 11.5
        case .larger: return 12.5
        case .superLarge: return 14
        }
    }

    var isSingleLine: Bool {
        false
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
        case .large: return 304
        case .larger: return 356
        case .superLarge: return 416
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 7
        case .large: return 8
        case .larger: return 10
        case .superLarge: return 11
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
        case .large: return 14
        case .larger: return 15
        case .superLarge: return 16
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
        case .large: return 3
        case .larger: return 4
        case .superLarge: return 5
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

@Observable
final class FloatifySettings {
    static let shared = FloatifySettings()
    static let cliSymlinkInstalledKey = "CLISymlinkInstalled"

    private enum Key {
        static let floaterSize = "FloaterSize"
        static let floaterTheme = "FloaterTheme"
        static let floaterRenderMode = "FloaterRenderMode"
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
