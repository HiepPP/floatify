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

    private var styleTokens: FloaterStyleSizeTokens {
        FloaterStyleCatalog.shared.currentPreset.sizeTokens(for: self)
    }

    var rowHeight: CGFloat {
        styleTokens.rowHeight
    }

    var spriteSize: CGFloat {
        styleTokens.spriteSize
    }

    var stageSize: CGFloat {
        styleTokens.stageSize
    }

    var dotSize: CGFloat {
        styleTokens.dotSize
    }

    var cornerRadius: CGFloat {
        styleTokens.cornerRadius
    }

    var horizontalPadding: CGFloat {
        styleTokens.horizontalPadding
    }

    var projectFontSize: CGFloat {
        styleTokens.projectFontSize
    }

    var metaFontSize: CGFloat {
        styleTokens.metaFontSize
    }

    var panelWidth: CGFloat {
        styleTokens.panelWidth
    }

    var persistentPanelWidth: CGFloat {
        styleTokens.persistentPanelWidth
    }

    var contentSpacing: CGFloat {
        styleTokens.contentSpacing
    }

    var statusRailWidth: CGFloat {
        styleTokens.statusRailWidth
    }

    var closeButtonSize: CGFloat {
        styleTokens.closeButtonSize
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
        styleTokens.cardShadowRadius
    }

    var statusPillMinWidth: CGFloat {
        styleTokens.statusPillMinWidth
    }

    var bodySpacing: CGFloat {
        styleTokens.bodySpacing
    }

    var persistentBodySpacing: CGFloat {
        styleTokens.persistentBodySpacing
    }

    var persistentLineSpacing: CGFloat {
        styleTokens.persistentLineSpacing
    }

    var persistentBodyVerticalInset: CGFloat {
        styleTokens.persistentBodyVerticalInset
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

    enum Key {
        static let floaterSize = "FloaterSize"
        static let floaterTheme = "FloaterTheme"
        static let floaterRenderMode = "FloaterRenderMode"
        static let floaterHeaderCPUDisplay = "FloaterHeaderCPUDisplay"
        static let selectedFloaterStyleID = "SelectedFloaterStyleID"
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

    var selectedFloaterStyleID: String {
        didSet {
            defaults.set(selectedFloaterStyleID, forKey: Key.selectedFloaterStyleID)
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
        self.selectedFloaterStyleID = defaults.string(forKey: Key.selectedFloaterStyleID) ?? FloaterStyleConstants.defaultStyleID
        self.selectedVisualPackID = defaults.string(forKey: Key.selectedVisualPackID) ?? FloaterVisualConstants.builtInPackID
        self.selectedAvatarID = defaults.string(forKey: Key.selectedAvatarID) ?? FloaterVisualConstants.autoAvatarID
        self.selectedEffectPresetID = defaults.string(forKey: Key.selectedEffectPresetID) ?? FloaterVisualConstants.defaultEffectPresetID

        let storedIdleTimeout = defaults.integer(forKey: Key.idleTimeout)
        self.idleTimeout = storedIdleTimeout > 0 ? storedIdleTimeout : 10

        normalizeVisualSelection()
        normalizeStyleSelection()
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

    func normalizeStyleSelection(catalog: FloaterStyleCatalog = .shared) {
        let resolvedPreset = catalog.resolvedPreset(id: selectedFloaterStyleID)
        if selectedFloaterStyleID != resolvedPreset.id {
            selectedFloaterStyleID = resolvedPreset.id
        }
    }

    func selectFloaterStyle(_ styleID: String, catalog: FloaterStyleCatalog = .shared) {
        selectedFloaterStyleID = styleID
        normalizeStyleSelection(catalog: catalog)
    }
}
