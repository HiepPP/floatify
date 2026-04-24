import Foundation
import SwiftUI

enum FloaterStyleConstants {
    static let defaultStyleID = "default"
    static let bundledStylePresetNames = ["default", "terminal"]
}

struct FloaterStyleColorToken: Hashable, Decodable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    static let black = FloaterStyleColorToken(red: 0, green: 0, blue: 0)
    static let white = FloaterStyleColorToken(red: 1, green: 1, blue: 1)
    static let clear = FloaterStyleColorToken(red: 0, green: 0, blue: 0, alpha: 0)

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamped(red)
        self.green = Self.clamped(green)
        self.blue = Self.clamped(blue)
        self.alpha = Self.clamped(alpha)
    }

    init(hex: String, alpha: Double? = nil) {
        if let parsed = Self.parseHex(hex) {
            self.init(
                red: parsed.red,
                green: parsed.green,
                blue: parsed.blue,
                alpha: alpha ?? parsed.alpha
            )
        } else {
            self = .black
        }
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(String.self) {
            guard let parsed = Self.parseHex(value) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Invalid color hex value."
                )
            }
            self.init(red: parsed.red, green: parsed.green, blue: parsed.blue, alpha: parsed.alpha)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let explicitAlpha = (try? container.decode(Double.self, forKey: .alpha))
            ?? (try? container.decode(Double.self, forKey: .opacity))

        if let value = try? container.decode(String.self, forKey: .hex) {
            guard let parsed = Self.parseHex(value) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .hex,
                    in: container,
                    debugDescription: "Invalid color hex value."
                )
            }
            self.init(
                red: parsed.red,
                green: parsed.green,
                blue: parsed.blue,
                alpha: explicitAlpha ?? parsed.alpha
            )
            return
        }

        self.init(
            red: (try? container.decode(Double.self, forKey: .red)) ?? 0,
            green: (try? container.decode(Double.self, forKey: .green)) ?? 0,
            blue: (try? container.decode(Double.self, forKey: .blue)) ?? 0,
            alpha: explicitAlpha ?? 1
        )
    }

    var color: Color {
        Color(red: red, green: green, blue: blue).opacity(alpha)
    }

    func opacity(_ value: Double) -> Color {
        Color(red: red, green: green, blue: blue).opacity(value)
    }

    private enum CodingKeys: String, CodingKey {
        case red
        case green
        case blue
        case alpha
        case opacity
        case hex
    }

    private static func parseHex(_ rawValue: String) -> (red: Double, green: Double, blue: Double, alpha: Double)? {
        let value = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard value.count == 6 || value.count == 8,
              let integer = UInt64(value, radix: 16) else {
            return nil
        }

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        if value.count == 8 {
            red = (integer >> 24) & 0xff
            green = (integer >> 16) & 0xff
            blue = (integer >> 8) & 0xff
            alpha = integer & 0xff
        } else {
            red = (integer >> 16) & 0xff
            green = (integer >> 8) & 0xff
            blue = integer & 0xff
            alpha = 0xff
        }

        return (
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            alpha: Double(alpha) / 255
        )
    }

    private static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

struct FloaterStylePaletteTokens: Hashable {
    let panelTint: FloaterStyleColorToken
    let panelShadow: FloaterStyleColorToken
    let primaryText: FloaterStyleColorToken
    let secondaryText: FloaterStyleColorToken
    let strokeStrong: FloaterStyleColorToken
    let strokeSoft: FloaterStyleColorToken
    let highlight: FloaterStyleColorToken
    let running: FloaterStyleColorToken
    let idle: FloaterStyleColorToken
    let complete: FloaterStyleColorToken
    let warning: FloaterStyleColorToken
    let chipFill: FloaterStyleColorToken
    let closeHover: FloaterStyleColorToken

    static let darkDefault = FloaterStylePaletteTokens(
        panelTint: .init(red: 0.075, green: 0.082, blue: 0.118),
        panelShadow: .init(red: 0.020, green: 0.024, blue: 0.040),
        primaryText: .init(hex: "#FFFFFF", alpha: 0.98),
        secondaryText: .init(hex: "#FFFFFF", alpha: 0.74),
        strokeStrong: .init(red: 0.720, green: 0.790, blue: 0.930),
        strokeSoft: .init(red: 0.280, green: 0.330, blue: 0.430),
        highlight: .init(red: 0.980, green: 0.990, blue: 1.000),
        running: .init(red: 0.965, green: 0.470, blue: 0.410),
        idle: .init(red: 0.915, green: 0.705, blue: 0.320),
        complete: .init(red: 0.330, green: 0.845, blue: 0.645),
        warning: .init(red: 0.948, green: 0.598, blue: 0.360),
        chipFill: .init(red: 0.145, green: 0.165, blue: 0.230),
        closeHover: .init(red: 0.240, green: 0.280, blue: 0.390)
    )

    static let lightDefault = FloaterStylePaletteTokens(
        panelTint: .init(red: 0.969, green: 0.976, blue: 0.988),
        panelShadow: .init(red: 0.106, green: 0.133, blue: 0.188),
        primaryText: .init(red: 0.070, green: 0.086, blue: 0.124, alpha: 0.92),
        secondaryText: .init(red: 0.150, green: 0.188, blue: 0.282, alpha: 0.76),
        strokeStrong: .init(red: 0.722, green: 0.769, blue: 0.847),
        strokeSoft: .init(red: 0.835, green: 0.867, blue: 0.922),
        highlight: .init(red: 1.000, green: 1.000, blue: 1.000),
        running: .init(red: 0.847, green: 0.302, blue: 0.255),
        idle: .init(red: 0.773, green: 0.541, blue: 0.082),
        complete: .init(red: 0.133, green: 0.541, blue: 0.384),
        warning: .init(red: 0.851, green: 0.467, blue: 0.227),
        chipFill: .init(red: 0.914, green: 0.933, blue: 0.969),
        closeHover: .init(red: 0.863, green: 0.894, blue: 0.945)
    )
}

private struct FloaterStylePaletteManifest: Decodable {
    var panelTint: FloaterStyleColorToken?
    var panelShadow: FloaterStyleColorToken?
    var primaryText: FloaterStyleColorToken?
    var secondaryText: FloaterStyleColorToken?
    var strokeStrong: FloaterStyleColorToken?
    var strokeSoft: FloaterStyleColorToken?
    var highlight: FloaterStyleColorToken?
    var running: FloaterStyleColorToken?
    var idle: FloaterStyleColorToken?
    var complete: FloaterStyleColorToken?
    var warning: FloaterStyleColorToken?
    var chipFill: FloaterStyleColorToken?
    var closeHover: FloaterStyleColorToken?

    func resolved(default base: FloaterStylePaletteTokens) -> FloaterStylePaletteTokens {
        FloaterStylePaletteTokens(
            panelTint: panelTint ?? base.panelTint,
            panelShadow: panelShadow ?? base.panelShadow,
            primaryText: primaryText ?? base.primaryText,
            secondaryText: secondaryText ?? base.secondaryText,
            strokeStrong: strokeStrong ?? base.strokeStrong,
            strokeSoft: strokeSoft ?? base.strokeSoft,
            highlight: highlight ?? base.highlight,
            running: running ?? base.running,
            idle: idle ?? base.idle,
            complete: complete ?? base.complete,
            warning: warning ?? base.warning,
            chipFill: chipFill ?? base.chipFill,
            closeHover: closeHover ?? base.closeHover
        )
    }
}

struct FloaterStylePalette: Hashable, Decodable {
    let dark: FloaterStylePaletteTokens
    let light: FloaterStylePaletteTokens

    static let defaultPalette = FloaterStylePalette(
        dark: .darkDefault,
        light: .lightDefault
    )

    init(dark: FloaterStylePaletteTokens, light: FloaterStylePaletteTokens) {
        self.dark = dark
        self.light = light
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dark = ((try? container.decode(FloaterStylePaletteManifest.self, forKey: .dark)) ?? .init())
            .resolved(default: .darkDefault)
        light = ((try? container.decode(FloaterStylePaletteManifest.self, forKey: .light)) ?? .init())
            .resolved(default: .lightDefault)
    }

    func tokens(for theme: FloaterTheme) -> FloaterStylePaletteTokens {
        theme == .dark ? dark : light
    }

    private enum CodingKeys: String, CodingKey {
        case dark
        case light
    }
}

struct FloaterStyleShellTokens: Hashable {
    let top: FloaterStyleColorToken
    let bottom: FloaterStyleColorToken
    let stroke: FloaterStyleColorToken
    let innerGlow: FloaterStyleColorToken
    let shadow: FloaterStyleColorToken

    static let darkDefault = FloaterStyleShellTokens(
        top: .init(red: 0.082, green: 0.122, blue: 0.238),
        bottom: .init(red: 0.052, green: 0.082, blue: 0.168),
        stroke: .init(red: 0.236, green: 0.304, blue: 0.486),
        innerGlow: .init(hex: "#FFFFFF", alpha: 0.09),
        shadow: .init(red: 0.012, green: 0.018, blue: 0.036)
    )

    static let lightDefault = FloaterStyleShellTokens(
        top: .init(red: 0.965, green: 0.975, blue: 0.992),
        bottom: .init(red: 0.780, green: 0.835, blue: 0.922),
        stroke: .init(red: 0.620, green: 0.690, blue: 0.800),
        innerGlow: .init(hex: "#FFFFFF", alpha: 0.45),
        shadow: .init(red: 0.128, green: 0.160, blue: 0.227)
    )
}

private struct FloaterStyleShellManifest: Decodable {
    var top: FloaterStyleColorToken?
    var bottom: FloaterStyleColorToken?
    var stroke: FloaterStyleColorToken?
    var innerGlow: FloaterStyleColorToken?
    var shadow: FloaterStyleColorToken?

    func resolved(default base: FloaterStyleShellTokens) -> FloaterStyleShellTokens {
        FloaterStyleShellTokens(
            top: top ?? base.top,
            bottom: bottom ?? base.bottom,
            stroke: stroke ?? base.stroke,
            innerGlow: innerGlow ?? base.innerGlow,
            shadow: shadow ?? base.shadow
        )
    }
}

struct FloaterStyleShell: Hashable, Decodable {
    let dark: FloaterStyleShellTokens
    let light: FloaterStyleShellTokens

    static let defaultShell = FloaterStyleShell(dark: .darkDefault, light: .lightDefault)

    init(dark: FloaterStyleShellTokens, light: FloaterStyleShellTokens) {
        self.dark = dark
        self.light = light
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dark = ((try? container.decode(FloaterStyleShellManifest.self, forKey: .dark)) ?? .init())
            .resolved(default: .darkDefault)
        light = ((try? container.decode(FloaterStyleShellManifest.self, forKey: .light)) ?? .init())
            .resolved(default: .lightDefault)
    }

    func tokens(for theme: FloaterTheme) -> FloaterStyleShellTokens {
        theme == .dark ? dark : light
    }

    private enum CodingKeys: String, CodingKey {
        case dark
        case light
    }
}

struct FloaterStyleCardTokens: Hashable {
    let top: FloaterStyleColorToken
    let mid: FloaterStyleColorToken
    let bottom: FloaterStyleColorToken
    let border: FloaterStyleColorToken
    let stageTop: FloaterStyleColorToken
    let stageBottom: FloaterStyleColorToken
    let shadow: FloaterStyleColorToken

    static let darkDefault = FloaterStyleCardTokens(
        top: .init(red: 0.165, green: 0.236, blue: 0.496),
        mid: .init(red: 0.120, green: 0.186, blue: 0.420),
        bottom: .init(red: 0.094, green: 0.152, blue: 0.344),
        border: .init(red: 0.314, green: 0.424, blue: 0.704),
        stageTop: .init(red: 0.486, green: 0.676, blue: 0.976),
        stageBottom: .init(red: 0.214, green: 0.382, blue: 0.748),
        shadow: .init(red: 0.010, green: 0.016, blue: 0.032)
    )

    static let lightDefault = FloaterStyleCardTokens(
        top: .init(red: 0.996, green: 0.998, blue: 1.000),
        mid: .init(red: 0.922, green: 0.944, blue: 0.982),
        bottom: .init(red: 0.785, green: 0.835, blue: 0.915),
        border: .init(red: 0.622, green: 0.696, blue: 0.810),
        stageTop: .init(red: 0.975, green: 0.985, blue: 1.000),
        stageBottom: .init(red: 0.790, green: 0.842, blue: 0.928),
        shadow: .init(red: 0.118, green: 0.145, blue: 0.206)
    )
}

private struct FloaterStyleCardManifest: Decodable {
    var top: FloaterStyleColorToken?
    var mid: FloaterStyleColorToken?
    var bottom: FloaterStyleColorToken?
    var border: FloaterStyleColorToken?
    var stageTop: FloaterStyleColorToken?
    var stageBottom: FloaterStyleColorToken?
    var shadow: FloaterStyleColorToken?

    func resolved(default base: FloaterStyleCardTokens) -> FloaterStyleCardTokens {
        FloaterStyleCardTokens(
            top: top ?? base.top,
            mid: mid ?? base.mid,
            bottom: bottom ?? base.bottom,
            border: border ?? base.border,
            stageTop: stageTop ?? base.stageTop,
            stageBottom: stageBottom ?? base.stageBottom,
            shadow: shadow ?? base.shadow
        )
    }
}

struct FloaterStyleCard: Hashable, Decodable {
    let dark: FloaterStyleCardTokens
    let light: FloaterStyleCardTokens

    static let defaultCard = FloaterStyleCard(dark: .darkDefault, light: .lightDefault)

    init(dark: FloaterStyleCardTokens, light: FloaterStyleCardTokens) {
        self.dark = dark
        self.light = light
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dark = ((try? container.decode(FloaterStyleCardManifest.self, forKey: .dark)) ?? .init())
            .resolved(default: .darkDefault)
        light = ((try? container.decode(FloaterStyleCardManifest.self, forKey: .light)) ?? .init())
            .resolved(default: .lightDefault)
    }

    func tokens(for theme: FloaterTheme) -> FloaterStyleCardTokens {
        theme == .dark ? dark : light
    }

    private enum CodingKeys: String, CodingKey {
        case dark
        case light
    }
}

struct FloaterStyleSizeTokens: Hashable {
    let rowHeight: CGFloat
    let spriteSize: CGFloat
    let stageSize: CGFloat
    let dotSize: CGFloat
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let projectFontSize: CGFloat
    let metaFontSize: CGFloat
    let panelWidth: CGFloat
    let persistentPanelWidth: CGFloat
    let contentSpacing: CGFloat
    let statusRailWidth: CGFloat
    let closeButtonSize: CGFloat
    let cardShadowRadius: CGFloat
    let statusPillMinWidth: CGFloat
    let bodySpacing: CGFloat
    let persistentBodySpacing: CGFloat
    let persistentLineSpacing: CGFloat
    let persistentBodyVerticalInset: CGFloat

    static func defaultTokens(for size: FloaterSize) -> FloaterStyleSizeTokens {
        switch size {
        case .compact:
            return FloaterStyleSizeTokens(
                rowHeight: 38,
                spriteSize: 18,
                stageSize: 24,
                dotSize: 5,
                cornerRadius: 9,
                horizontalPadding: 7,
                projectFontSize: 11.5,
                metaFontSize: 9,
                panelWidth: 210,
                persistentPanelWidth: 236,
                contentSpacing: 6,
                statusRailWidth: 4,
                closeButtonSize: 12,
                cardShadowRadius: 9,
                statusPillMinWidth: 42,
                bodySpacing: 1,
                persistentBodySpacing: 1,
                persistentLineSpacing: 4,
                persistentBodyVerticalInset: 3
            )
        case .regular:
            return FloaterStyleSizeTokens(
                rowHeight: 44,
                spriteSize: 24,
                stageSize: 30,
                dotSize: 6,
                cornerRadius: 10,
                horizontalPadding: 8,
                projectFontSize: 12.5,
                metaFontSize: 9.5,
                panelWidth: 262,
                persistentPanelWidth: 236,
                contentSpacing: 7,
                statusRailWidth: 5,
                closeButtonSize: 13,
                cardShadowRadius: 11,
                statusPillMinWidth: 58,
                bodySpacing: 2,
                persistentBodySpacing: 2,
                persistentLineSpacing: 5,
                persistentBodyVerticalInset: 4
            )
        case .large:
            return FloaterStyleSizeTokens(
                rowHeight: 136,
                spriteSize: 72,
                stageSize: 78,
                dotSize: 12,
                cornerRadius: 24,
                horizontalPadding: 24,
                projectFontSize: 26,
                metaFontSize: 16,
                panelWidth: 352,
                persistentPanelWidth: 560,
                contentSpacing: 22,
                statusRailWidth: 6,
                closeButtonSize: 32,
                cardShadowRadius: 14,
                statusPillMinWidth: 66,
                bodySpacing: 6,
                persistentBodySpacing: 12,
                persistentLineSpacing: 11,
                persistentBodyVerticalInset: 20
            )
        case .larger:
            return FloaterStyleSizeTokens(
                rowHeight: 162,
                spriteSize: 86,
                stageSize: 94,
                dotSize: 14,
                cornerRadius: 28,
                horizontalPadding: 28,
                projectFontSize: 31,
                metaFontSize: 18,
                panelWidth: 420,
                persistentPanelWidth: 660,
                contentSpacing: 26,
                statusRailWidth: 7,
                closeButtonSize: 36,
                cardShadowRadius: 16,
                statusPillMinWidth: 78,
                bodySpacing: 7,
                persistentBodySpacing: 14,
                persistentLineSpacing: 13,
                persistentBodyVerticalInset: 22
            )
        case .superLarge:
            return FloaterStyleSizeTokens(
                rowHeight: 190,
                spriteSize: 102,
                stageSize: 110,
                dotSize: 16,
                cornerRadius: 32,
                horizontalPadding: 32,
                projectFontSize: 36,
                metaFontSize: 20,
                panelWidth: 492,
                persistentPanelWidth: 760,
                contentSpacing: 30,
                statusRailWidth: 8,
                closeButtonSize: 40,
                cardShadowRadius: 18,
                statusPillMinWidth: 90,
                bodySpacing: 8,
                persistentBodySpacing: 16,
                persistentLineSpacing: 15,
                persistentBodyVerticalInset: 24
            )
        }
    }
}

private extension KeyedDecodingContainer {
    func decodeStyleValue<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        default defaultValue: T
    ) -> T {
        (try? decode(type, forKey: key)) ?? defaultValue
    }
}

private struct FloaterStyleSizeManifest: Decodable {
    var rowHeight: CGFloat?
    var spriteSize: CGFloat?
    var stageSize: CGFloat?
    var dotSize: CGFloat?
    var cornerRadius: CGFloat?
    var horizontalPadding: CGFloat?
    var projectFontSize: CGFloat?
    var metaFontSize: CGFloat?
    var panelWidth: CGFloat?
    var persistentPanelWidth: CGFloat?
    var contentSpacing: CGFloat?
    var statusRailWidth: CGFloat?
    var closeButtonSize: CGFloat?
    var cardShadowRadius: CGFloat?
    var statusPillMinWidth: CGFloat?
    var bodySpacing: CGFloat?
    var persistentBodySpacing: CGFloat?
    var persistentLineSpacing: CGFloat?
    var persistentBodyVerticalInset: CGFloat?

    func resolved(default base: FloaterStyleSizeTokens) -> FloaterStyleSizeTokens {
        FloaterStyleSizeTokens(
            rowHeight: rowHeight ?? base.rowHeight,
            spriteSize: spriteSize ?? base.spriteSize,
            stageSize: stageSize ?? base.stageSize,
            dotSize: dotSize ?? base.dotSize,
            cornerRadius: cornerRadius ?? base.cornerRadius,
            horizontalPadding: horizontalPadding ?? base.horizontalPadding,
            projectFontSize: projectFontSize ?? base.projectFontSize,
            metaFontSize: metaFontSize ?? base.metaFontSize,
            panelWidth: panelWidth ?? base.panelWidth,
            persistentPanelWidth: persistentPanelWidth ?? base.persistentPanelWidth,
            contentSpacing: contentSpacing ?? base.contentSpacing,
            statusRailWidth: statusRailWidth ?? base.statusRailWidth,
            closeButtonSize: closeButtonSize ?? base.closeButtonSize,
            cardShadowRadius: cardShadowRadius ?? base.cardShadowRadius,
            statusPillMinWidth: statusPillMinWidth ?? base.statusPillMinWidth,
            bodySpacing: bodySpacing ?? base.bodySpacing,
            persistentBodySpacing: persistentBodySpacing ?? base.persistentBodySpacing,
            persistentLineSpacing: persistentLineSpacing ?? base.persistentLineSpacing,
            persistentBodyVerticalInset: persistentBodyVerticalInset ?? base.persistentBodyVerticalInset
        )
    }
}

struct FloaterStyleSizes: Hashable, Decodable {
    let compact: FloaterStyleSizeTokens
    let regular: FloaterStyleSizeTokens
    let large: FloaterStyleSizeTokens
    let larger: FloaterStyleSizeTokens
    let superLarge: FloaterStyleSizeTokens

    static let defaultSizes = FloaterStyleSizes(
        compact: .defaultTokens(for: .compact),
        regular: .defaultTokens(for: .regular),
        large: .defaultTokens(for: .large),
        larger: .defaultTokens(for: .larger),
        superLarge: .defaultTokens(for: .superLarge)
    )

    init(
        compact: FloaterStyleSizeTokens,
        regular: FloaterStyleSizeTokens,
        large: FloaterStyleSizeTokens,
        larger: FloaterStyleSizeTokens,
        superLarge: FloaterStyleSizeTokens
    ) {
        self.compact = compact
        self.regular = regular
        self.large = large
        self.larger = larger
        self.superLarge = superLarge
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        compact = ((try? container.decode(FloaterStyleSizeManifest.self, forKey: .compact)) ?? .init())
            .resolved(default: .defaultTokens(for: .compact))
        regular = ((try? container.decode(FloaterStyleSizeManifest.self, forKey: .regular)) ?? .init())
            .resolved(default: .defaultTokens(for: .regular))
        large = ((try? container.decode(FloaterStyleSizeManifest.self, forKey: .large)) ?? .init())
            .resolved(default: .defaultTokens(for: .large))
        larger = ((try? container.decode(FloaterStyleSizeManifest.self, forKey: .larger)) ?? .init())
            .resolved(default: .defaultTokens(for: .larger))
        superLarge = ((try? container.decode(FloaterStyleSizeManifest.self, forKey: .superLarge)) ?? .init())
            .resolved(default: .defaultTokens(for: .superLarge))
    }

    func tokens(for size: FloaterSize) -> FloaterStyleSizeTokens {
        switch size {
        case .compact: return compact
        case .regular: return regular
        case .large: return large
        case .larger: return larger
        case .superLarge: return superLarge
        }
    }

    private enum CodingKeys: String, CodingKey {
        case compact
        case regular
        case large
        case larger
        case superLarge
    }
}

enum FloaterFontWeightToken: String, Hashable, Decodable {
    case ultraLight
    case thin
    case light
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? Self.regular.rawValue
        switch value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "") {
        case "ultralight":
            self = .ultraLight
        case "thin":
            self = .thin
        case "light":
            self = .light
        case "medium":
            self = .medium
        case "semibold":
            self = .semibold
        case "bold":
            self = .bold
        case "heavy":
            self = .heavy
        case "black":
            self = .black
        default:
            self = .regular
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        }
    }
}

enum FloaterFontDesignToken: String, Hashable, Decodable {
    case `default`
    case rounded
    case serif
    case monospaced

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? Self.default.rawValue
        switch value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "") {
        case "rounded":
            self = .rounded
        case "serif":
            self = .serif
        case "monospaced", "mono":
            self = .monospaced
        default:
            self = .default
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .default:
            return .default
        case .rounded:
            return .rounded
        case .serif:
            return .serif
        case .monospaced:
            return .monospaced
        }
    }
}

struct FloaterFontStyleToken: Hashable, Decodable {
    var family: String?
    var size: CGFloat?
    var weight: FloaterFontWeightToken
    var design: FloaterFontDesignToken

    init(
        family: String? = nil,
        size: CGFloat? = nil,
        weight: FloaterFontWeightToken = .regular,
        design: FloaterFontDesignToken = .default
    ) {
        self.family = Self.normalizedFamily(family)
        self.size = size
        self.weight = weight
        self.design = design
    }

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedFamily = (try? container.decode(String.self, forKey: .family))
            ?? (try? container.decode(String.self, forKey: .fontFamily))
            ?? (try? container.decode(String.self, forKey: .name))
        family = Self.normalizedFamily(decodedFamily)
        size = (try? container.decode(CGFloat.self, forKey: .size)) ?? base.size
        weight = container.decodeStyleValue(FloaterFontWeightToken.self, forKey: .weight, default: base.weight)
        design = (try? container.decode(FloaterFontDesignToken.self, forKey: .design))
            ?? (try? container.decode(FloaterFontDesignToken.self, forKey: .style))
            ?? base.design
    }

    func font(defaultSize: CGFloat) -> Font {
        let resolvedSize = resolvedSize(defaultSize)
        if let family {
            return .custom(family, size: resolvedSize).weight(weight.fontWeight)
        }
        return systemFont(defaultSize: defaultSize)
    }

    func systemFont(defaultSize: CGFloat) -> Font {
        .system(size: resolvedSize(defaultSize), weight: weight.fontWeight, design: design.fontDesign)
    }

    private func resolvedSize(_ defaultSize: CGFloat) -> CGFloat {
        max(1, size ?? defaultSize)
    }

    private static func normalizedFamily(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "system" else { return nil }
        return trimmed
    }

    private enum CodingKeys: String, CodingKey {
        case family
        case fontFamily
        case name
        case size
        case weight
        case design
        case style
    }
}

struct FloaterTypographyTokens: Hashable, Decodable {
    var panelHeaderTitle = FloaterFontStyleToken(weight: .heavy, design: .rounded)
    var panelHeaderChip = FloaterFontStyleToken(weight: .bold, design: .rounded)
    var panelHeaderChipValue = FloaterFontStyleToken(weight: .black, design: .rounded)
    var rowTitle = FloaterFontStyleToken(weight: .heavy, design: .rounded)
    var rowMeta = FloaterFontStyleToken(weight: .bold, design: .rounded)
    var statusPill = FloaterFontStyleToken(weight: .bold, design: .rounded)

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        panelHeaderTitle = container.decodeStyleValue(FloaterFontStyleToken.self, forKey: .panelHeaderTitle, default: base.panelHeaderTitle)
        panelHeaderChip = container.decodeStyleValue(FloaterFontStyleToken.self, forKey: .panelHeaderChip, default: base.panelHeaderChip)
        panelHeaderChipValue = container.decodeStyleValue(FloaterFontStyleToken.self, forKey: .panelHeaderChipValue, default: base.panelHeaderChipValue)
        rowTitle = container.decodeStyleValue(FloaterFontStyleToken.self, forKey: .rowTitle, default: base.rowTitle)
        rowMeta = container.decodeStyleValue(FloaterFontStyleToken.self, forKey: .rowMeta, default: base.rowMeta)
        statusPill = container.decodeStyleValue(FloaterFontStyleToken.self, forKey: .statusPill, default: base.statusPill)
    }

    private enum CodingKeys: String, CodingKey {
        case panelHeaderTitle
        case panelHeaderChip
        case panelHeaderChipValue
        case rowTitle
        case rowMeta
        case statusPill
    }
}

struct FloaterHeaderStyleTokens: Hashable, Decodable {
    var darkText: FloaterStyleColorToken = .init(hex: "#FFFFFF", alpha: 0.98)
    var lightText: FloaterStyleColorToken = .init(red: 0.082, green: 0.106, blue: 0.165, alpha: 0.94)
    var buttonForeground: FloaterStyleColorToken = .init(hex: "#FFFFFF", alpha: 0.96)
    var buttonHoverFillOpacity: Double = 0.12
    var metricChipTop: FloaterStyleColorToken = .init(hex: "#FFFFFF", alpha: 0.09)
    var metricChipBottom: FloaterStyleColorToken = .init(red: 0.054, green: 0.122, blue: 0.286, alpha: 0.92)
    var metricChipStrokeOpacity: Double = 0.14
    var metricChipShadowOpacity: Double = 0.15
    var cpuTint: FloaterStyleColorToken = .init(red: 0.533, green: 0.945, blue: 0.514)
    var cloudTop: FloaterStyleColorToken = .init(red: 0.780, green: 0.950, blue: 1.000)
    var cloudBottom: FloaterStyleColorToken = .init(red: 0.330, green: 0.760, blue: 0.970)
    var cloudDetail: FloaterStyleColorToken = .init(red: 0.074, green: 0.200, blue: 0.300, alpha: 0.72)
    var cloudMouthOpacity: Double = 0.55
    var cloudShadowOpacity: Double = 0.26

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        darkText = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .darkText, default: base.darkText)
        lightText = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .lightText, default: base.lightText)
        buttonForeground = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .buttonForeground, default: base.buttonForeground)
        buttonHoverFillOpacity = container.decodeStyleValue(Double.self, forKey: .buttonHoverFillOpacity, default: base.buttonHoverFillOpacity)
        metricChipTop = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .metricChipTop, default: base.metricChipTop)
        metricChipBottom = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .metricChipBottom, default: base.metricChipBottom)
        metricChipStrokeOpacity = container.decodeStyleValue(Double.self, forKey: .metricChipStrokeOpacity, default: base.metricChipStrokeOpacity)
        metricChipShadowOpacity = container.decodeStyleValue(Double.self, forKey: .metricChipShadowOpacity, default: base.metricChipShadowOpacity)
        cpuTint = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .cpuTint, default: base.cpuTint)
        cloudTop = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .cloudTop, default: base.cloudTop)
        cloudBottom = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .cloudBottom, default: base.cloudBottom)
        cloudDetail = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .cloudDetail, default: base.cloudDetail)
        cloudMouthOpacity = container.decodeStyleValue(Double.self, forKey: .cloudMouthOpacity, default: base.cloudMouthOpacity)
        cloudShadowOpacity = container.decodeStyleValue(Double.self, forKey: .cloudShadowOpacity, default: base.cloudShadowOpacity)
    }

    private enum CodingKeys: String, CodingKey {
        case darkText
        case lightText
        case buttonForeground
        case buttonHoverFillOpacity
        case metricChipTop
        case metricChipBottom
        case metricChipStrokeOpacity
        case metricChipShadowOpacity
        case cpuTint
        case cloudTop
        case cloudBottom
        case cloudDetail
        case cloudMouthOpacity
        case cloudShadowOpacity
    }
}

struct FloaterRowStyleTokens: Hashable, Decodable {
    var hoverStrokeOpacity: Double = 0.24
    var restingStrokeOpacity: Double = 0.14
    var topHighlightOpacity: Double = 0.14
    var bottomShadowOpacity: Double = 0.12
    var radialHighlightOpacity: Double = 0.10
    var runningAccentOpacity: Double = 0.10
    var restingAccentOpacity: Double = 0.04
    var borderOpacity: Double = 0.90
    var borderWidth: CGFloat = 1.2
    var innerStrokeOpacity: Double = 0.12
    var innerStrokeWidth: CGFloat = 0.7

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hoverStrokeOpacity = container.decodeStyleValue(Double.self, forKey: .hoverStrokeOpacity, default: base.hoverStrokeOpacity)
        restingStrokeOpacity = container.decodeStyleValue(Double.self, forKey: .restingStrokeOpacity, default: base.restingStrokeOpacity)
        topHighlightOpacity = container.decodeStyleValue(Double.self, forKey: .topHighlightOpacity, default: base.topHighlightOpacity)
        bottomShadowOpacity = container.decodeStyleValue(Double.self, forKey: .bottomShadowOpacity, default: base.bottomShadowOpacity)
        radialHighlightOpacity = container.decodeStyleValue(Double.self, forKey: .radialHighlightOpacity, default: base.radialHighlightOpacity)
        runningAccentOpacity = container.decodeStyleValue(Double.self, forKey: .runningAccentOpacity, default: base.runningAccentOpacity)
        restingAccentOpacity = container.decodeStyleValue(Double.self, forKey: .restingAccentOpacity, default: base.restingAccentOpacity)
        borderOpacity = container.decodeStyleValue(Double.self, forKey: .borderOpacity, default: base.borderOpacity)
        borderWidth = container.decodeStyleValue(CGFloat.self, forKey: .borderWidth, default: base.borderWidth)
        innerStrokeOpacity = container.decodeStyleValue(Double.self, forKey: .innerStrokeOpacity, default: base.innerStrokeOpacity)
        innerStrokeWidth = container.decodeStyleValue(CGFloat.self, forKey: .innerStrokeWidth, default: base.innerStrokeWidth)
    }

    private enum CodingKeys: String, CodingKey {
        case hoverStrokeOpacity
        case restingStrokeOpacity
        case topHighlightOpacity
        case bottomShadowOpacity
        case radialHighlightOpacity
        case runningAccentOpacity
        case restingAccentOpacity
        case borderOpacity
        case borderWidth
        case innerStrokeOpacity
        case innerStrokeWidth
    }
}

struct FloaterAvatarStageStyleTokens: Hashable, Decodable {
    var topHighlightOpacity: Double = 0.22
    var bottomShadowOpacity: Double = 0.10
    var radialHighlightOpacity: Double = 0.16
    var borderOpacity: Double = 0.70
    var borderWidth: CGFloat = 1.1
    var innerStrokeOpacity: Double = 0.14
    var innerStrokeWidth: CGFloat = 0.7

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        topHighlightOpacity = container.decodeStyleValue(Double.self, forKey: .topHighlightOpacity, default: base.topHighlightOpacity)
        bottomShadowOpacity = container.decodeStyleValue(Double.self, forKey: .bottomShadowOpacity, default: base.bottomShadowOpacity)
        radialHighlightOpacity = container.decodeStyleValue(Double.self, forKey: .radialHighlightOpacity, default: base.radialHighlightOpacity)
        borderOpacity = container.decodeStyleValue(Double.self, forKey: .borderOpacity, default: base.borderOpacity)
        borderWidth = container.decodeStyleValue(CGFloat.self, forKey: .borderWidth, default: base.borderWidth)
        innerStrokeOpacity = container.decodeStyleValue(Double.self, forKey: .innerStrokeOpacity, default: base.innerStrokeOpacity)
        innerStrokeWidth = container.decodeStyleValue(CGFloat.self, forKey: .innerStrokeWidth, default: base.innerStrokeWidth)
    }

    private enum CodingKeys: String, CodingKey {
        case topHighlightOpacity
        case bottomShadowOpacity
        case radialHighlightOpacity
        case borderOpacity
        case borderWidth
        case innerStrokeOpacity
        case innerStrokeWidth
    }
}

struct FloaterStatusPillStyleTokens: Hashable, Decodable {
    var darkLabelOpacity: Double = 0.96
    var lightLabelOpacity: Double = 0.84
    var darkFillOpacity: Double = 0.16
    var lightFillOpacity: Double = 0.12
    var strokeOpacity: Double = 0.30

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        darkLabelOpacity = container.decodeStyleValue(Double.self, forKey: .darkLabelOpacity, default: base.darkLabelOpacity)
        lightLabelOpacity = container.decodeStyleValue(Double.self, forKey: .lightLabelOpacity, default: base.lightLabelOpacity)
        darkFillOpacity = container.decodeStyleValue(Double.self, forKey: .darkFillOpacity, default: base.darkFillOpacity)
        lightFillOpacity = container.decodeStyleValue(Double.self, forKey: .lightFillOpacity, default: base.lightFillOpacity)
        strokeOpacity = container.decodeStyleValue(Double.self, forKey: .strokeOpacity, default: base.strokeOpacity)
    }

    private enum CodingKeys: String, CodingKey {
        case darkLabelOpacity
        case lightLabelOpacity
        case darkFillOpacity
        case lightFillOpacity
        case strokeOpacity
    }
}

struct FloaterCloseButtonStyleTokens: Hashable, Decodable {
    var foreground: FloaterStyleColorToken = .init(hex: "#FFFFFF", alpha: 0.96)
    var fill: FloaterStyleColorToken = .init(red: 0.082, green: 0.118, blue: 0.242)
    var persistentHoverFillOpacity: Double = 0.18
    var persistentRestFillOpacity: Double = 0
    var floatingHoverFillOpacity: Double = 0.96
    var floatingRestFillOpacity: Double = 0.90
    var floatingStrokeHoverOpacity: Double = 0.56
    var floatingStrokeRestOpacity: Double = 0.34

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foreground = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .foreground, default: base.foreground)
        fill = container.decodeStyleValue(FloaterStyleColorToken.self, forKey: .fill, default: base.fill)
        persistentHoverFillOpacity = container.decodeStyleValue(Double.self, forKey: .persistentHoverFillOpacity, default: base.persistentHoverFillOpacity)
        persistentRestFillOpacity = container.decodeStyleValue(Double.self, forKey: .persistentRestFillOpacity, default: base.persistentRestFillOpacity)
        floatingHoverFillOpacity = container.decodeStyleValue(Double.self, forKey: .floatingHoverFillOpacity, default: base.floatingHoverFillOpacity)
        floatingRestFillOpacity = container.decodeStyleValue(Double.self, forKey: .floatingRestFillOpacity, default: base.floatingRestFillOpacity)
        floatingStrokeHoverOpacity = container.decodeStyleValue(Double.self, forKey: .floatingStrokeHoverOpacity, default: base.floatingStrokeHoverOpacity)
        floatingStrokeRestOpacity = container.decodeStyleValue(Double.self, forKey: .floatingStrokeRestOpacity, default: base.floatingStrokeRestOpacity)
    }

    private enum CodingKeys: String, CodingKey {
        case foreground
        case fill
        case persistentHoverFillOpacity
        case persistentRestFillOpacity
        case floatingHoverFillOpacity
        case floatingRestFillOpacity
        case floatingStrokeHoverOpacity
        case floatingStrokeRestOpacity
    }
}

struct FloaterComponentStyleTokens: Hashable, Decodable {
    var header = FloaterHeaderStyleTokens()
    var row = FloaterRowStyleTokens()
    var avatarStage = FloaterAvatarStageStyleTokens()
    var statusPill = FloaterStatusPillStyleTokens()
    var closeButton = FloaterCloseButtonStyleTokens()

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        header = container.decodeStyleValue(FloaterHeaderStyleTokens.self, forKey: .header, default: base.header)
        row = container.decodeStyleValue(FloaterRowStyleTokens.self, forKey: .row, default: base.row)
        avatarStage = container.decodeStyleValue(FloaterAvatarStageStyleTokens.self, forKey: .avatarStage, default: base.avatarStage)
        statusPill = container.decodeStyleValue(FloaterStatusPillStyleTokens.self, forKey: .statusPill, default: base.statusPill)
        closeButton = container.decodeStyleValue(FloaterCloseButtonStyleTokens.self, forKey: .closeButton, default: base.closeButton)
    }

    private enum CodingKeys: String, CodingKey {
        case header
        case row
        case avatarStage
        case statusPill
        case closeButton
    }
}

struct FloaterStyleEffectVariant: Hashable, Decodable {
    var entryEffects: [String] = ["slide", "fade", "dropdown", "marquee", "trail"]

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entryEffects = container.decodeStyleValue([String].self, forKey: .entryEffects, default: base.entryEffects)
    }

    private enum CodingKeys: String, CodingKey {
        case entryEffects
    }
}

struct FloaterStyleVariants: Hashable, Decodable {
    var panelShell = "gradientShell"
    var panelHeader = "cloudHeader"
    var floaterRow = "gradientRow"
    var avatarStage = "spriteStage"
    var statusPill = "roundedStatusPill"
    var closeButton = "circleCloseButton"
    var effects = FloaterStyleEffectVariant()

    init() {}

    init(from decoder: Decoder) throws {
        let base = Self()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        panelShell = container.decodeStyleValue(String.self, forKey: .panelShell, default: base.panelShell)
        panelHeader = container.decodeStyleValue(String.self, forKey: .panelHeader, default: base.panelHeader)
        floaterRow = container.decodeStyleValue(String.self, forKey: .floaterRow, default: base.floaterRow)
        avatarStage = container.decodeStyleValue(String.self, forKey: .avatarStage, default: base.avatarStage)
        statusPill = container.decodeStyleValue(String.self, forKey: .statusPill, default: base.statusPill)
        closeButton = container.decodeStyleValue(String.self, forKey: .closeButton, default: base.closeButton)
        effects = container.decodeStyleValue(FloaterStyleEffectVariant.self, forKey: .effects, default: base.effects)
    }

    private enum CodingKeys: String, CodingKey {
        case panelShell
        case panelHeader
        case floaterRow
        case avatarStage
        case statusPill
        case closeButton
        case effects
    }
}

struct FloaterStylePreset: Hashable, Decodable, Identifiable {
    let id: String
    let displayName: String
    let description: String
    let palette: FloaterStylePalette
    let shell: FloaterStyleShell
    let card: FloaterStyleCard
    let sizes: FloaterStyleSizes
    let typography: FloaterTypographyTokens
    let components: FloaterComponentStyleTokens
    let variants: FloaterStyleVariants

    static let defaultPreset = FloaterStylePreset(
        id: FloaterStyleConstants.defaultStyleID,
        displayName: "Default",
        description: "Current Floatify UI baseline.",
        palette: .defaultPalette,
        shell: .defaultShell,
        card: .defaultCard,
        sizes: .defaultSizes,
        typography: FloaterTypographyTokens(),
        components: FloaterComponentStyleTokens(),
        variants: FloaterStyleVariants()
    )

    init(
        id: String,
        displayName: String,
        description: String,
        palette: FloaterStylePalette,
        shell: FloaterStyleShell,
        card: FloaterStyleCard,
        sizes: FloaterStyleSizes,
        typography: FloaterTypographyTokens,
        components: FloaterComponentStyleTokens,
        variants: FloaterStyleVariants
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.palette = palette
        self.shell = shell
        self.card = card
        self.sizes = sizes
        self.typography = typography
        self.components = components
        self.variants = variants
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? FloaterStyleConstants.defaultStyleID
        displayName = (try? container.decode(String.self, forKey: .displayName))
            ?? (try? container.decode(String.self, forKey: .name))
            ?? id
        description = (try? container.decode(String.self, forKey: .description)) ?? ""
        palette = (try? container.decode(FloaterStylePalette.self, forKey: .palette)) ?? .defaultPalette
        shell = (try? container.decode(FloaterStyleShell.self, forKey: .shell)) ?? .defaultShell
        card = (try? container.decode(FloaterStyleCard.self, forKey: .card)) ?? .defaultCard
        sizes = (try? container.decode(FloaterStyleSizes.self, forKey: .sizes)) ?? .defaultSizes
        typography = (try? container.decode(FloaterTypographyTokens.self, forKey: .typography))
            ?? FloaterTypographyTokens()
        components = (try? container.decode(FloaterComponentStyleTokens.self, forKey: .components))
            ?? FloaterComponentStyleTokens()
        variants = (try? container.decode(FloaterStyleVariants.self, forKey: .variants))
            ?? FloaterStyleVariants()
    }

    func paletteTokens(for theme: FloaterTheme) -> FloaterStylePaletteTokens {
        palette.tokens(for: theme)
    }

    func shellTokens(for theme: FloaterTheme) -> FloaterStyleShellTokens {
        shell.tokens(for: theme)
    }

    func cardTokens(for theme: FloaterTheme) -> FloaterStyleCardTokens {
        card.tokens(for: theme)
    }

    func sizeTokens(for size: FloaterSize) -> FloaterStyleSizeTokens {
        sizes.tokens(for: size)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName
        case description
        case palette
        case shell
        case card
        case sizes
        case typography
        case components
        case variants
    }
}
