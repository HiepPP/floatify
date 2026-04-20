import AppKit
import QuartzCore
import SwiftUI

private struct FloaterThemePalette {
    let panelTint: Color
    let panelShadow: Color
    let primaryText: Color
    let secondaryText: Color
    let strokeStrong: Color
    let strokeSoft: Color
    let highlight: Color
    let running: Color
    let committing: Color
    let pushing: Color
    let idle: Color
    let complete: Color
    let warning: Color
    let chipFill: Color
    let closeHover: Color
}

enum FloaterPalette {
    private static var palette: FloaterThemePalette {
        switch FloaterTheme.current {
        case .dark:
            return FloaterThemePalette(
                panelTint: Color(red: 0.075, green: 0.082, blue: 0.118),
                panelShadow: Color(red: 0.020, green: 0.024, blue: 0.040),
                primaryText: Color(red: 0.955, green: 0.970, blue: 1.000),
                secondaryText: Color(red: 0.645, green: 0.705, blue: 0.815),
                strokeStrong: Color(red: 0.720, green: 0.790, blue: 0.930),
                strokeSoft: Color(red: 0.280, green: 0.330, blue: 0.430),
                highlight: Color(red: 0.980, green: 0.990, blue: 1.000),
                running: Color(red: 0.965, green: 0.470, blue: 0.410),
                committing: Color(red: 0.357, green: 0.561, blue: 0.965),
                pushing: Color(red: 0.176, green: 0.745, blue: 0.671),
                idle: Color(red: 0.915, green: 0.705, blue: 0.320),
                complete: Color(red: 0.330, green: 0.845, blue: 0.645),
                warning: Color(red: 0.948, green: 0.598, blue: 0.360),
                chipFill: Color(red: 0.145, green: 0.165, blue: 0.230),
                closeHover: Color(red: 0.240, green: 0.280, blue: 0.390)
            )
        case .light:
            return FloaterThemePalette(
                panelTint: Color(red: 0.969, green: 0.976, blue: 0.988),
                panelShadow: Color(red: 0.106, green: 0.133, blue: 0.188),
                primaryText: Color(red: 0.094, green: 0.129, blue: 0.200),
                secondaryText: Color(red: 0.357, green: 0.404, blue: 0.490),
                strokeStrong: Color(red: 0.722, green: 0.769, blue: 0.847),
                strokeSoft: Color(red: 0.835, green: 0.867, blue: 0.922),
                highlight: Color(red: 1.000, green: 1.000, blue: 1.000),
                running: Color(red: 0.847, green: 0.302, blue: 0.255),
                committing: Color(red: 0.200, green: 0.435, blue: 0.890),
                pushing: Color(red: 0.082, green: 0.596, blue: 0.486),
                idle: Color(red: 0.773, green: 0.541, blue: 0.082),
                complete: Color(red: 0.133, green: 0.541, blue: 0.384),
                warning: Color(red: 0.851, green: 0.467, blue: 0.227),
                chipFill: Color(red: 0.914, green: 0.933, blue: 0.969),
                closeHover: Color(red: 0.863, green: 0.894, blue: 0.945)
            )
        }
    }

    static var panelTint: Color { palette.panelTint }
    static var panelShadow: Color { palette.panelShadow }
    static var primaryText: Color { palette.primaryText }
    static var secondaryText: Color { palette.secondaryText }
    static var strokeStrong: Color { palette.strokeStrong }
    static var strokeSoft: Color { palette.strokeSoft }
    static var highlight: Color { palette.highlight }
    static var running: Color { palette.running }
    static var committing: Color { palette.committing }
    static var pushing: Color { palette.pushing }
    static var idle: Color { palette.idle }
    static var complete: Color { palette.complete }
    static var warning: Color { palette.warning }
    static var chipFill: Color { palette.chipFill }
    static var closeHover: Color { palette.closeHover }
}

// MARK: - Sprite Sheet Infrastructure

struct SpriteSheetMetadata: Hashable {
    let frameRects: [CGRect]

    static let defaultSheetName = "avatar-sprite-sheet"

    static let defaultMetadata = SpriteSheetMetadata(frameRects: [
        CGRect(x: 0, y: 0, width: 121, height: 115),
        CGRect(x: 121, y: 0, width: 121, height: 115),
        CGRect(x: 242, y: 0, width: 121, height: 115),
        CGRect(x: 363, y: 0, width: 121, height: 115),
        CGRect(x: 484, y: 0, width: 121, height: 115),
        CGRect(x: 605, y: 0, width: 121, height: 115)
    ])

    static let bySheetName: [String: SpriteSheetMetadata] = [
        "Abra Alakazam Sprite": SpriteSheetMetadata(frameRects: [
            CGRect(x: 15, y: 15, width: 32, height: 32),
            CGRect(x: 50, y: 15, width: 32, height: 32),
            CGRect(x: 85, y: 15, width: 32, height: 32),
            CGRect(x: 120, y: 15, width: 32, height: 32),
            CGRect(x: 155, y: 15, width: 32, height: 32),
            CGRect(x: 190, y: 15, width: 32, height: 32)
        ])
    ]

    static var supportedSheetNames: [String] {
        [defaultSheetName] + bySheetName.keys.sorted().filter { $0 != defaultSheetName }
    }

    static func bundledSheetNames() -> [String] {
        supportedSheetNames.filter { Bundle.main.url(forResource: $0, withExtension: "png") != nil }
    }

    static func forSheet(_ name: String) -> SpriteSheetMetadata {
        bySheetName[name] ?? defaultMetadata
    }
}

private enum AvatarImageCache {
    static var spriteSheets: [String: CGImage] = [:]
    static var croppedFrames: [String: NSImage] = [:]
    static var staticImages: [String: NSImage] = [:]

    static func cgImage(for source: FloaterAvatarImageSource) -> CGImage? {
        let key = cacheKey(for: source)
        if let cached = spriteSheets[key] {
            return cached
        }

        guard let url = url(for: source),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        spriteSheets[key] = image
        return image
    }

    static func staticImage(for source: FloaterAvatarImageSource) -> NSImage? {
        let key = cacheKey(for: source)
        if let cached = staticImages[key] {
            return cached
        }

        guard let url = url(for: source),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        staticImages[key] = image
        return image
    }

    static func frameImage(for rect: CGRect, source: FloaterAvatarImageSource) -> NSImage? {
        let key = "\(cacheKey(for: source)):\(Int(rect.origin.x)):\(Int(rect.origin.y)):\(Int(rect.size.width)):\(Int(rect.size.height))"
        if let cached = croppedFrames[key] {
            return cached
        }

        guard let sheet = cgImage(for: source),
              let cropped = sheet.cropping(to: rect) else {
            return nil
        }

        let image = NSImage(cgImage: cropped, size: rect.size)
        croppedFrames[key] = image
        return image
    }

    private static func cacheKey(for source: FloaterAvatarImageSource) -> String {
        switch source {
        case let .bundledResource(name):
            return "bundle:\(name)"
        case let .file(path):
            return "file:\(path)"
        }
    }

    private static func url(for source: FloaterAvatarImageSource) -> URL? {
        switch source {
        case let .bundledResource(name):
            return Bundle.main.url(forResource: name, withExtension: "png")
        case let .file(path):
            return URL(fileURLWithPath: path)
        }
    }
}

private struct SpriteAnimationView: View {
    let avatar: FloaterAvatarDefinition
    let isAnimating: Bool
    var size: CGFloat = 34

    @State private var frameIndex = 0

    private var imageSource: FloaterAvatarImageSource? {
        switch avatar.source {
        case let .spriteSheet(imageSource, _, _):
            return imageSource
        case .automatic, .staticImage:
            return nil
        }
    }

    private var metadata: SpriteSheetMetadata {
        switch avatar.source {
        case let .spriteSheet(_, metadata, _):
            return metadata
        case .automatic, .staticImage:
            return SpriteSheetMetadata.defaultMetadata
        }
    }

    private var frameRects: [CGRect] {
        metadata.frameRects
    }

    private var frameDuration: UInt64 {
        let duration: TimeInterval
        switch avatar.source {
        case let .spriteSheet(_, _, frameDuration):
            duration = frameDuration
        case .automatic, .staticImage:
            duration = 0.16
        }

        return UInt64(max(duration, 0.04) * 1_000_000_000)
    }

    var body: some View {
        Group {
            if let imageSource,
               let image = AvatarImageCache.frameImage(for: frameRects[frameIndex], source: imageSource) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .task(id: "\(avatar.id)-\(isAnimating)") {
            frameIndex = 0
            guard isAnimating else { return }

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: frameDuration)
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    frameIndex = (frameIndex + 1) % frameRects.count
                }
            }
        }
    }
}

private struct StaticAvatarImageView: View {
    let avatar: FloaterAvatarDefinition
    var size: CGFloat

    private var imageSource: FloaterAvatarImageSource? {
        switch avatar.source {
        case let .staticImage(imageSource):
            return imageSource
        case .automatic, .spriteSheet:
            return nil
        }
    }

    var body: some View {
        Group {
            if let imageSource,
               let image = AvatarImageCache.staticImage(for: imageSource) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }
}

private struct AvatarArtView: View {
    let avatar: FloaterAvatarDefinition?
    let isAnimating: Bool
    var size: CGFloat

    var body: some View {
        Group {
            if let avatar {
                switch avatar.source {
                case .automatic:
                    EmptyView()
                case .spriteSheet:
                    SpriteAnimationView(avatar: avatar, isAnimating: isAnimating, size: size)
                case .staticImage:
                    StaticAvatarImageView(avatar: avatar, size: size)
                }
            }
        }
    }
}

@MainActor
private final class FloaterLowFrequencyTicker: ObservableObject {
    static let shared = FloaterLowFrequencyTicker()

    @Published private(set) var now = Date()
    @Published private(set) var tick = 0

    private var timer: Timer?

    private init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.now = Date()
                self.tick += 1
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    deinit {
        timer?.invalidate()
    }
}

private struct RunningDurationBadge: View {
    let lastActivity: Date
    let floaterSize: FloaterSize
    let accentColor: Color

    @ObservedObject private var ticker = FloaterLowFrequencyTicker.shared

    private var durationText: String {
        let elapsed = max(Int(ticker.now.timeIntervalSince(lastActivity)), 0)
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "timer")
                .font(.system(size: floaterSize.metaFontSize - 1, weight: .bold))
            Text(durationText)
                .font(.system(size: floaterSize.metaFontSize, weight: .semibold))
                .monospacedDigit()
        }
        .foregroundStyle(accentColor.opacity(0.96))
        .padding(.horizontal, floaterSize == .compact ? 4 : 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(accentColor.opacity(floaterSize == .compact ? 0.12 : 0.15))
        )
        .fixedSize()
    }
}

// MARK: - Typing Dots

private struct TypingDots: View {
    let color: Color
    let fontSize: CGFloat

    @ObservedObject private var ticker = FloaterLowFrequencyTicker.shared

    private var phase: Int {
        ticker.tick % 3
    }

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(phase == i ? 1.0 : 0.35))
                    .frame(width: fontSize * 0.32, height: fontSize * 0.32)
                    .scaleEffect(phase == i ? 1.3 : 0.85)
                    .animation(.easeInOut(duration: 0.25), value: phase)
            }
        }
    }
}

private struct LiteTypingDots: View {
    let color: Color
    let fontSize: CGFloat

    @ObservedObject private var ticker = FloaterLowFrequencyTicker.shared

    private var phase: Int {
        ticker.tick % 3
    }

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color.opacity(phase == i ? 0.92 : 0.28))
                    .frame(width: fontSize * 0.28, height: fontSize * 0.28)
            }
        }
    }
}

// MARK: - Sparkle Burst

private struct SparkleBurst: View {
    let trigger: UUID?

    @State private var particles: [SparkleParticle] = []

    private struct SparkleParticle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let delay: Double
        let symbol: String
        let scale: CGFloat
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.symbol)
                    .font(.system(size: 11 * p.scale))
                    .modifier(SparkleParticleAnimation(angle: p.angle, distance: p.distance, delay: p.delay))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if trigger != nil { spawnParticles() }
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != nil else { return }
            spawnParticles()
        }
    }

    private func spawnParticles() {
        let symbols = ["\u{2728}", "\u{2B50}", "\u{1F389}"] // ✨ ⭐ 🎉
        particles = (0..<5).map { i in
            SparkleParticle(
                angle: .pi * 2 * Double(i) / 5 + Double.random(in: -0.4...0.4),
                distance: CGFloat.random(in: 18...28),
                delay: Double(i) * 0.04,
                symbol: symbols.randomElement() ?? "\u{2728}",
                scale: CGFloat.random(in: 0.8...1.3)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            particles = []
        }
    }
}

private struct IdleSparkleBurst: View {
    let trigger: UUID?

    @State private var particles: [IdleSparkleParticle] = []

    private struct IdleSparkleParticle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let delay: Double
        let symbol: String
        let scale: CGFloat
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(particle.symbol)
                    .font(.system(size: 8.5 * particle.scale))
                    .modifier(SparkleParticleAnimation(angle: particle.angle, distance: particle.distance, delay: particle.delay))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if trigger != nil { spawnParticles() }
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != nil else { return }
            spawnParticles()
        }
    }

    private func spawnParticles() {
        let symbols = ["\u{2728}", "\u{2736}"]
        particles = (0..<3).map { i in
            IdleSparkleParticle(
                angle: .pi * 2 * Double(i) / 3 + Double.random(in: -0.35...0.35),
                distance: CGFloat.random(in: 11...16),
                delay: Double(i) * 0.03,
                symbol: symbols.randomElement() ?? "\u{2728}",
                scale: CGFloat.random(in: 0.75...1.05)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            particles = []
        }
    }
}

private struct DoneSparkleSweep: View {
    let color: Color
    let stageSize: CGFloat
    let trigger: UUID?

    @State private var sweepOffset: CGFloat = -1.25
    @State private var sweepOpacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(color.opacity(sweepOpacity * 0.22), lineWidth: 0.9)
                .blur(radius: 1.4)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(sweepOpacity * 0.52),
                            color.opacity(sweepOpacity * 0.26),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.38
                    )
                )
                .scaleEffect(0.72 + sweepOpacity * 0.20)
                .opacity(sweepOpacity * 0.62)

            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.08),
                    .white.opacity(0.96),
                    color.opacity(0.74),
                    .white.opacity(0.84),
                    .clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: stageSize * 0.34, height: stageSize * 1.15)
            .blur(radius: 4)
            .rotationEffect(.degrees(-28))
            .offset(x: stageSize * 0.62 * sweepOffset)
            .opacity(sweepOpacity)
            .blendMode(.screen)
        }
        .frame(width: stageSize * 0.92, height: stageSize * 0.92)
        .clipShape(Circle())
        .allowsHitTesting(false)
        .onAppear {
            if trigger != nil { animateSweep() }
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != nil else { return }
            animateSweep()
        }
    }

    private func animateSweep() {
        sweepOffset = -1.25
        sweepOpacity = 0

        withAnimation(.easeOut(duration: 0.14)) {
            sweepOpacity = 0.96
        }
        withAnimation(.linear(duration: 0.94)) {
            sweepOffset = 1.25
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.easeIn(duration: 0.42)) {
                sweepOpacity = 0
            }
        }
    }
}

private struct SparkleParticleAnimation: ViewModifier {
    let angle: Double
    let distance: CGFloat
    let delay: Double

    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: cos(angle) * distance * progress, y: sin(angle) * distance * progress - 6 * progress)
            .scaleEffect(0.4 + progress * 0.9)
            .opacity(Double(1 - progress))
            .rotationEffect(.degrees(progress * 180))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 0.9)) {
                        progress = 1
                    }
                }
            }
    }
}

private struct RunningSheenSweep: View {
    let color: Color
    let cornerRadius: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning

    @State private var sweepProgress: CGFloat = 0
    @State private var didStartAnimating = false

    private var isSuperSlay: Bool {
        renderMode == .superSlay
    }

    private func scaledOpacity(_ value: Double) -> Double {
        min(value * effectTuning.glowMultiplier, 1.0)
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let sweepWidth = max(size.width * 0.22, 58)
            let travel = size.width + sweepWidth + size.height * 0.95
            let offset = travel * sweepProgress - sweepWidth - size.height * 0.46

            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: color.opacity(scaledOpacity(isSuperSlay ? 0.10 : 0.05)), location: 0.22),
                                .init(color: .white.opacity(scaledOpacity(isSuperSlay ? 0.30 : 0.17)), location: 0.50),
                                .init(color: color.opacity(scaledOpacity(isSuperSlay ? 0.16 : 0.08)), location: 0.78),
                                .init(color: .clear, location: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sweepWidth, height: size.height * 1.92)
                    .blur(radius: (isSuperSlay ? 5 : 4) * effectTuning.glowMultiplier)
                    .offset(x: offset)
                    .rotationEffect(.degrees(-16))
                    .blendMode(.screen)

                if isSuperSlay {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.00),
                                    .init(color: .white.opacity(scaledOpacity(0.10)), location: 0.36),
                                    .init(color: .white.opacity(scaledOpacity(0.44)), location: 0.52),
                                    .init(color: color.opacity(scaledOpacity(0.18)), location: 0.72),
                                    .init(color: .clear, location: 1.00)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: sweepWidth * 0.55, height: size.height * 1.70)
                        .blur(radius: 2.8)
                        .offset(x: offset - sweepWidth * 0.18)
                        .rotationEffect(.degrees(-12))
                        .blendMode(.screen)
                }

                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color.opacity(scaledOpacity(isSuperSlay ? 0.09 : 0.055)), lineWidth: isSuperSlay ? 0.9 : 0.7)
            }
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius)
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .allowsHitTesting(false)
        .onAppear {
            guard !didStartAnimating else { return }
            didStartAnimating = true
            sweepProgress = 0

            withAnimation(.linear(duration: (isSuperSlay ? 3.1 : 11.8) * effectTuning.sheenDurationMultiplier).repeatForever(autoreverses: false)) {
                sweepProgress = 1
            }
        }
        .onDisappear {
            didStartAnimating = false
            sweepProgress = 0
        }
    }
}

private enum SlayStageState: Hashable {
    case running
    case idle
    case complete
}

private struct SlayStageCacheKey: Hashable {
    let size: Int
    let state: SlayStageState
    let renderMode: FloaterRenderMode
    let colorKey: String
    let glowBucket: Int
    let showsCounterArc: Bool
    let showsSecondaryOrbit: Bool
    let flashBucket: Int
    let extraCompletionRays: Int
    let extraCompletionOrbs: Int
}

private struct SlaySheenCacheKey: Hashable {
    let width: Int
    let height: Int
    let cornerRadius: Int
    let renderMode: FloaterRenderMode
    let colorKey: String
    let glowBucket: Int
}

private extension NSColor {
    var floaterCacheKey: String {
        let converted = usingColorSpace(.deviceRGB) ?? self
        return String(
            format: "%03d-%03d-%03d-%03d",
            Int(converted.redComponent * 255),
            Int(converted.greenComponent * 255),
            Int(converted.blueComponent * 255),
            Int(converted.alphaComponent * 255)
        )
    }
}

@MainActor
private enum SlaySnapshotCache {
    private static var stageFrameCache: [SlayStageCacheKey: [NSImage]] = [:]
    private static var sheenFrameCache: [SlaySheenCacheKey: [NSImage]] = [:]

    static func stageFrames(
        state: SlayStageState,
        renderMode: FloaterRenderMode,
        statusColor: Color,
        stageSize: CGFloat,
        effectTuning: FloaterEffectTuning
    ) -> [NSImage] {
        let showsCounterArc = effectTuning.showsCounterArc ?? (renderMode == .superSlay)
        let showsSecondaryOrbit = effectTuning.showsSecondaryOrbit ?? (renderMode == .superSlay)
        let cacheKey = SlayStageCacheKey(
            size: Int(stageSize.rounded(.toNearestOrAwayFromZero)),
            state: state,
            renderMode: renderMode,
            colorKey: NSColor(statusColor).floaterCacheKey,
            glowBucket: Int((max(effectTuning.glowMultiplier, 0.2) * 100).rounded()),
            showsCounterArc: showsCounterArc,
            showsSecondaryOrbit: showsSecondaryOrbit,
            flashBucket: Int((effectTuning.flashIntensityMultiplier * 100).rounded()),
            extraCompletionRays: effectTuning.extraCompletionRays,
            extraCompletionOrbs: effectTuning.extraCompletionOrbs
        )

        if let cached = stageFrameCache[cacheKey] {
            return cached
        }

        let frameCount: Int
        switch (renderMode, state) {
        case (.superSlay, .running):
            frameCount = 96
        case (.slay, .running):
            frameCount = 18
        case (_, .running):
            frameCount = 12
        default:
            frameCount = 1
        }
        let frames = (0..<frameCount).map { index in
            let progress = frameCount == 1 ? 0.26 : CGFloat(index) / CGFloat(max(frameCount - 1, 1))
            return renderImage(size: CGSize(width: stageSize, height: stageSize)) {
                SlayStageSnapshotContent(
                    color: statusColor,
                    stageSize: stageSize,
                    effectTuning: effectTuning,
                    state: state,
                    renderMode: renderMode,
                    progress: progress
                )
            }
        }

        stageFrameCache[cacheKey] = frames
        return frames
    }

    static func sheenFrames(
        renderMode: FloaterRenderMode,
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize,
        effectTuning: FloaterEffectTuning
    ) -> [NSImage] {
        let cacheKey = SlaySheenCacheKey(
            width: Int(size.width.rounded(.toNearestOrAwayFromZero)),
            height: Int(size.height.rounded(.toNearestOrAwayFromZero)),
            cornerRadius: Int(cornerRadius.rounded(.toNearestOrAwayFromZero)),
            renderMode: renderMode,
            colorKey: NSColor(color).floaterCacheKey,
            glowBucket: Int((max(effectTuning.glowMultiplier, 0.2) * 100).rounded())
        )

        if let cached = sheenFrameCache[cacheKey] {
            return cached
        }

        let frameCount = renderMode == .superSlay ? 60 : 10
        let frames = (0..<frameCount).map { index in
            let progress = CGFloat(index) / CGFloat(max(frameCount - 1, 1))
            return renderImage(size: size) {
                SlaySheenSnapshotContent(
                    color: color,
                    cornerRadius: cornerRadius,
                    size: size,
                    effectTuning: effectTuning,
                    renderMode: renderMode,
                    progress: progress
                )
            }
        }

        sheenFrameCache[cacheKey] = frames
        return frames
    }

    private static func renderImage<Content: View>(size: CGSize, @ViewBuilder content: () -> Content) -> NSImage {
        let renderer = ImageRenderer(content: content().frame(width: size.width, height: size.height))
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        renderer.isOpaque = false
        return renderer.nsImage ?? NSImage(size: size)
    }
}

private struct SlayStageSnapshotContent: View {
    let color: Color
    let stageSize: CGFloat
    let effectTuning: FloaterEffectTuning
    let state: SlayStageState
    let renderMode: FloaterRenderMode
    let progress: CGFloat

    private var glowMultiplier: Double {
        max(effectTuning.glowMultiplier, 0.2)
    }

    private var isSuperSlay: Bool {
        renderMode == .superSlay
    }

    private var showsCounterArc: Bool {
        effectTuning.showsCounterArc ?? false
    }

    private var showsSecondaryOrbit: Bool {
        effectTuning.showsSecondaryOrbit ?? false
    }

    private var completionRayCount: Int {
        max(6 + effectTuning.extraCompletionRays, 1)
    }

    private var completionOrbitCount: Int {
        max(3 + effectTuning.extraCompletionOrbs, 1)
    }

    private func scaledOpacity(_ value: Double) -> Double {
        min(value * glowMultiplier, 1.0)
    }

    private func scaledRadius(_ value: CGFloat) -> CGFloat {
        value * CGFloat(glowMultiplier)
    }

    private var pulse: CGFloat {
        0.5 - 0.5 * cos(progress * .pi * 2)
    }

    private var runningGlowScale: CGFloat {
        1.0 + (isSuperSlay ? 0.18 : 0.12) * pulse
    }

    private var runningAuraOpacity: Double {
        (isSuperSlay ? 0.78 : 0.70) + (isSuperSlay ? 0.24 : 0.18) * pulse
    }

    private var runningRingScale: CGFloat {
        0.86 + (showsCounterArc ? (isSuperSlay ? 0.26 : 0.20) * pulse : 0)
    }

    private var runningRingOpacity: Double {
        showsCounterArc ? (isSuperSlay ? 0.30 : 0.22) + (isSuperSlay ? 0.24 : 0.18) * Double(pulse) : 0
    }

    private var runningOrbitAngle: Double {
        -90 + Double(progress) * 360
    }

    private var runningArcRotation: Double {
        -24 + Double(progress) * 360
    }

    private var runningCounterArcRotation: Double {
        132 - Double(progress) * 324
    }

    private var runningArcOpacity: Double {
        (isSuperSlay ? 0.62 : 0.52) + (isSuperSlay ? 0.24 : 0.20) * Double(pulse)
    }

    private var completionFlashOpacity: Double {
        scaledOpacity(0.26)
    }

    private var completionCoreOpacity: Double {
        scaledOpacity(0.18)
    }

    private var completionRayOpacity: Double {
        scaledOpacity(0.42)
    }

    private var completionOrbitOpacity: Double {
        scaledOpacity(0.32)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(state == .running ? 0.42 : 0.34),
                            FloaterPalette.panelShadow.opacity(scaledOpacity(state == .running ? 0.66 : 0.54)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.52
                    )
                )
                .frame(width: stageSize * 0.96, height: stageSize * 0.96)

            switch state {
            case .running:
                runningContent
            case .idle:
                idleContent
            case .complete:
                completeContent
            }
        }
        .frame(width: stageSize, height: stageSize)
    }

    private var runningContent: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(scaledOpacity((isSuperSlay ? 0.40 : 0.34) * runningAuraOpacity)),
                            color.opacity(scaledOpacity((isSuperSlay ? 0.18 : 0.14) * runningAuraOpacity)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize / 2 + 2
                    )
                )
                .frame(width: stageSize * (isSuperSlay ? 1.44 : 1.34) * runningGlowScale, height: stageSize * (isSuperSlay ? 1.44 : 1.34) * runningGlowScale)
                .blur(radius: scaledRadius(isSuperSlay ? 4.8 : 3.0))

            Circle()
                .trim(from: 0.08, to: 0.40)
                .stroke(color.opacity(scaledOpacity((isSuperSlay ? 0.92 : 0.76) * runningArcOpacity)), style: StrokeStyle(lineWidth: isSuperSlay ? 2.4 : 2.0, lineCap: .round))
                .frame(width: stageSize * 1.16, height: stageSize * 1.16)
                .rotationEffect(.degrees(runningArcRotation))
                .shadow(color: color.opacity(scaledOpacity((isSuperSlay ? 0.30 : 0.18) * runningArcOpacity)), radius: scaledRadius(isSuperSlay ? 2.6 : 1.6), x: 0, y: 0)

            if showsCounterArc {
                Circle()
                    .trim(from: 0.56, to: 0.82)
                    .stroke(color.opacity(scaledOpacity(0.46 * runningArcOpacity)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: stageSize * 0.96, height: stageSize * 0.96)
                    .rotationEffect(.degrees(runningCounterArcRotation))
                    .shadow(color: color.opacity(scaledOpacity((isSuperSlay ? 0.20 : 0.16) * runningArcOpacity)), radius: scaledRadius(isSuperSlay ? 2.2 : 1.6), x: 0, y: 0)

                Circle()
                    .strokeBorder(color.opacity(scaledOpacity(runningRingOpacity)), lineWidth: 1.1)
                    .frame(width: stageSize * runningRingScale, height: stageSize * runningRingScale)
                    .blur(radius: 0.4)
            }

            ZStack {
                Circle()
                    .fill(color.opacity(0.86))
                Circle()
                    .fill(.white.opacity(0.86))
                    .frame(width: stageSize * 0.08, height: stageSize * 0.08)
            }
            .frame(width: stageSize * 0.20, height: stageSize * 0.20)
            .shadow(color: color.opacity(scaledOpacity(isSuperSlay ? 0.52 : 0.34)), radius: scaledRadius(isSuperSlay ? 4.2 : 3), x: 0, y: 0)
            .offset(y: -stageSize * 0.43)
            .rotationEffect(.degrees(runningOrbitAngle))

            if showsSecondaryOrbit {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.62))
                    Circle()
                        .fill(.white.opacity(0.64))
                        .frame(width: stageSize * 0.05, height: stageSize * 0.05)
                }
                .frame(width: stageSize * 0.14, height: stageSize * 0.14)
                .shadow(color: color.opacity(scaledOpacity(isSuperSlay ? 0.30 : 0.22)), radius: scaledRadius(isSuperSlay ? 3.2 : 2.6), x: 0, y: 0)
                .offset(y: -stageSize * 0.34)
                .rotationEffect(.degrees(-runningOrbitAngle * 0.78 + 118))
            }
        }
    }

    private var idleContent: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(scaledOpacity(0.22)),
                            color.opacity(scaledOpacity(0.08)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.54
                    )
                )
                .frame(width: stageSize * 1.08, height: stageSize * 1.08)
                .blur(radius: scaledRadius(2.2))

            Circle()
                .trim(from: 0.12, to: 0.34)
                .stroke(color.opacity(scaledOpacity(0.42)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: stageSize * 1.02, height: stageSize * 1.02)
                .rotationEffect(.degrees(-28))

            Circle()
                .fill(color.opacity(0.82))
                .frame(width: stageSize * 0.13, height: stageSize * 0.13)
                .shadow(color: color.opacity(scaledOpacity(0.20)), radius: scaledRadius(2.2), x: 0, y: 0)
                .offset(x: stageSize * 0.22, y: -stageSize * 0.18)
        }
    }

    private var completeContent: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(completionFlashOpacity * 0.92),
                            color.opacity(completionFlashOpacity * 0.78),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.52
                    )
                )
                .frame(width: stageSize * 1.08, height: stageSize * 1.08)
                .blur(radius: 6)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(completionCoreOpacity * 0.98),
                            color.opacity(completionCoreOpacity * 0.82),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.34
                    )
                )
                .frame(width: stageSize * 0.94, height: stageSize * 0.94)
                .blur(radius: 2)

            ForEach(0..<completionRayCount, id: \.self) { index in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(completionRayOpacity * 0.98),
                                color.opacity(completionRayOpacity * 0.84),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(
                        width: index.isMultiple(of: 3) ? 3.2 : 2.4,
                        height: stageSize * (0.16 + (index.isMultiple(of: 2) ? 0.24 : 0.18))
                    )
                    .offset(y: -stageSize * 0.32)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(completionRayCount)) + 34))
                    .opacity(completionRayOpacity)
                    .blur(radius: index.isMultiple(of: 4) ? 0.4 : 0.1)
                    .blendMode(.screen)
            }

            ForEach(0..<completionOrbitCount, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(completionOrbitOpacity),
                                color.opacity(completionOrbitOpacity * 0.82),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: stageSize * 0.10
                        )
                    )
                    .frame(
                        width: stageSize * (index.isMultiple(of: 2) ? 0.13 : 0.10),
                        height: stageSize * (index.isMultiple(of: 2) ? 0.13 : 0.10)
                    )
                    .offset(y: -stageSize * 0.40)
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(completionOrbitCount)) + 112))
                    .opacity(completionOrbitOpacity)
                    .shadow(color: color.opacity(scaledOpacity(completionOrbitOpacity * 0.34)), radius: scaledRadius(3), x: 0, y: 0)
                    .blendMode(.screen)
            }

            Circle()
                .strokeBorder(color.opacity(0.76), lineWidth: 1.4)
                .frame(width: stageSize * 0.94, height: stageSize * 0.94)
                .opacity(0.22)
                .blur(radius: 0.4)
        }
    }
}

private struct SlaySheenSnapshotContent: View {
    let color: Color
    let cornerRadius: CGFloat
    let size: CGSize
    let effectTuning: FloaterEffectTuning
    let renderMode: FloaterRenderMode
    let progress: CGFloat

    private var isSuperSlay: Bool {
        renderMode == .superSlay
    }

    private func scaledOpacity(_ value: Double) -> Double {
        min(value * effectTuning.glowMultiplier, 1.0)
    }

    var body: some View {
        let sweepWidth = max(size.width * 0.20, 54)
        let travel = size.width + sweepWidth + size.height * 0.95
        let offset = travel * progress - sweepWidth - size.height * 0.46

        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: color.opacity(scaledOpacity(0.05)), location: 0.22),
                            .init(color: .white.opacity(scaledOpacity(0.17)), location: 0.50),
                            .init(color: color.opacity(scaledOpacity(0.08)), location: 0.78),
                            .init(color: .clear, location: 1.00)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: sweepWidth, height: size.height * 1.92)
                .blur(radius: (isSuperSlay ? 4.8 : 3.2) * effectTuning.glowMultiplier)
                .offset(x: offset)
                .rotationEffect(.degrees(-16))
                .blendMode(.screen)

            if isSuperSlay {
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: .white.opacity(scaledOpacity(0.10)), location: 0.36),
                                .init(color: .white.opacity(scaledOpacity(0.44)), location: 0.52),
                                .init(color: color.opacity(scaledOpacity(0.18)), location: 0.72),
                                .init(color: .clear, location: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sweepWidth * 0.55, height: size.height * 1.70)
                    .blur(radius: 2.8)
                    .offset(x: offset - sweepWidth * 0.18)
                    .rotationEffect(.degrees(-12))
                    .blendMode(.screen)
            }

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(color.opacity(scaledOpacity(isSuperSlay ? 0.09 : 0.05)), lineWidth: isSuperSlay ? 0.9 : 0.7)
        }
        .frame(width: size.width, height: size.height)
        .mask(
            RoundedRectangle(cornerRadius: cornerRadius)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .allowsHitTesting(false)
    }
}

private extension NSImage {
    func floaterCGImage() -> CGImage? {
        cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}

private func avatarSequenceImages(for avatar: FloaterAvatarDefinition?) -> [NSImage] {
    guard let avatar else { return [] }

    switch avatar.source {
    case .automatic:
        return []
    case let .spriteSheet(imageSource, metadata, _):
        return metadata.frameRects.compactMap { AvatarImageCache.frameImage(for: $0, source: imageSource) }
    case let .staticImage(imageSource):
        guard let image = AvatarImageCache.staticImage(for: imageSource) else { return [] }
        return [image]
    }
}

private func avatarFrameDuration(for avatar: FloaterAvatarDefinition?) -> CFTimeInterval {
    guard let avatar else { return 0.16 }
    switch avatar.source {
    case let .spriteSheet(_, _, frameDuration):
        return max(frameDuration, 0.05)
    case .automatic, .staticImage:
        return 0.16
    }
}

@MainActor
private final class SlayImageSequenceRendererView: NSView {
    private let sequenceLayer = CALayer()
    private var currentSignature = ""

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.masksToBounds = true
        layer?.addSublayer(sequenceLayer)
        sequenceLayer.contentsGravity = .resize
        sequenceLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        sequenceLayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        layer?.frame = bounds
        sequenceLayer.frame = bounds
    }

    func update(
        frames: [NSImage],
        frameDuration: CFTimeInterval,
        signature: String,
        cornerRadius: CGFloat
    ) {
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
        sequenceLayer.cornerRadius = cornerRadius
        sequenceLayer.masksToBounds = true

        guard !frames.isEmpty else {
            sequenceLayer.removeAnimation(forKey: "sequence")
            sequenceLayer.contents = nil
            currentSignature = signature
            return
        }

        guard currentSignature != signature else { return }
        currentSignature = signature

        let cgFrames = frames.compactMap { $0.floaterCGImage() }
        sequenceLayer.removeAnimation(forKey: "sequence")
        sequenceLayer.contents = cgFrames.first

        guard cgFrames.count > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = cgFrames
        animation.keyTimes = (0..<cgFrames.count).map { NSNumber(value: Double($0) / Double(max(cgFrames.count - 1, 1))) }
        animation.duration = frameDuration * Double(cgFrames.count)
        animation.repeatCount = .infinity
        animation.calculationMode = .discrete
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        sequenceLayer.add(animation, forKey: "sequence")
    }
}

@MainActor
private final class SlayStageRendererView: NSView {
    private let stageLayer = CALayer()
    private let avatarLayer = CALayer()
    private var currentStageSignature = ""
    private var currentAvatarSignature = ""
    private var currentAvatarSize: CGFloat = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.masksToBounds = false
        layer?.addSublayer(stageLayer)
        layer?.addSublayer(avatarLayer)
        stageLayer.contentsGravity = .resize
        stageLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        stageLayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
        avatarLayer.contentsGravity = .resizeAspect
        avatarLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        avatarLayer.actions = ["contents": NSNull(), "bounds": NSNull(), "position": NSNull()]
        avatarLayer.magnificationFilter = .nearest
        avatarLayer.minificationFilter = .nearest
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        layer?.frame = bounds
        stageLayer.frame = bounds
        let side = min(currentAvatarSize, min(bounds.width, bounds.height))
        avatarLayer.frame = CGRect(
            x: (bounds.width - side) / 2,
            y: (bounds.height - side) / 2,
            width: side,
            height: side
        )
    }

    func update(
        stageFrames: [NSImage],
        stageFrameDuration: CFTimeInterval,
        stageSignature: String,
        avatarFrames: [NSImage],
        avatarFrameDuration: CFTimeInterval,
        avatarSignature: String,
        avatarSize: CGFloat
    ) {
        currentAvatarSize = avatarSize
        needsLayout = true

        updateStageSequence(frames: stageFrames, frameDuration: stageFrameDuration, signature: stageSignature)
        updateAvatarSequence(frames: avatarFrames, frameDuration: avatarFrameDuration, signature: avatarSignature)
    }

    private func updateStageSequence(
        frames: [NSImage],
        frameDuration: CFTimeInterval,
        signature: String
    ) {
        guard !frames.isEmpty else {
            stageLayer.removeAnimation(forKey: "sequence")
            stageLayer.contents = nil
            currentStageSignature = signature
            return
        }

        guard currentStageSignature != signature else { return }
        currentStageSignature = signature

        let cgFrames = frames.compactMap { $0.floaterCGImage() }
        stageLayer.removeAnimation(forKey: "sequence")
        stageLayer.contents = cgFrames.first

        guard cgFrames.count > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = cgFrames
        animation.keyTimes = (0..<cgFrames.count).map { NSNumber(value: Double($0) / Double(max(cgFrames.count - 1, 1))) }
        animation.duration = frameDuration * Double(cgFrames.count)
        animation.repeatCount = .infinity
        animation.calculationMode = .discrete
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        stageLayer.add(animation, forKey: "sequence")
    }

    private func updateAvatarSequence(
        frames: [NSImage],
        frameDuration: CFTimeInterval,
        signature: String
    ) {
        guard !frames.isEmpty else {
            avatarLayer.removeAnimation(forKey: "sequence")
            avatarLayer.contents = nil
            currentAvatarSignature = signature
            return
        }

        guard currentAvatarSignature != signature else { return }
        currentAvatarSignature = signature

        let cgFrames = frames.compactMap { $0.floaterCGImage() }
        avatarLayer.removeAnimation(forKey: "sequence")
        avatarLayer.contents = cgFrames.first

        guard cgFrames.count > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.values = cgFrames
        animation.keyTimes = (0..<cgFrames.count).map { NSNumber(value: Double($0) / Double(max(cgFrames.count - 1, 1))) }
        animation.duration = frameDuration * Double(cgFrames.count)
        animation.repeatCount = .infinity
        animation.calculationMode = .discrete
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        avatarLayer.add(animation, forKey: "sequence")
    }
}

private struct SlaySheenRendererRepresentable: NSViewRepresentable {
    let size: CGSize
    let color: Color
    let cornerRadius: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning

    func makeNSView(context: Context) -> SlayImageSequenceRendererView {
        SlayImageSequenceRendererView(frame: CGRect(origin: .zero, size: size))
    }

    func updateNSView(_ nsView: SlayImageSequenceRendererView, context: Context) {
        let frames = SlaySnapshotCache.sheenFrames(
            renderMode: renderMode,
            color: color,
            cornerRadius: cornerRadius,
            size: size,
            effectTuning: effectTuning
        )
        let signature = [
            renderMode.rawValue,
            "\(Int(size.width.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(size.height.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(cornerRadius.rounded(.toNearestOrAwayFromZero)))",
            NSColor(color).floaterCacheKey,
            "\(Int((max(effectTuning.glowMultiplier, 0.2) * 100).rounded()))"
        ].joined(separator: ":")
        let frameDuration = renderMode == .superSlay
            ? min(max(0.020, 0.020 * effectTuning.sheenDurationMultiplier), 0.025)
            : max(0.12, 0.18 * effectTuning.sheenDurationMultiplier)
        nsView.update(
            frames: frames,
            frameDuration: frameDuration,
            signature: signature,
            cornerRadius: cornerRadius
        )
    }
}

private struct SlayStageRendererRepresentable: NSViewRepresentable {
    let avatar: FloaterAvatarDefinition?
    let statusColor: Color
    let stageSize: CGFloat
    let spriteSize: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning
    let isAnimating: Bool
    let isRunning: Bool
    let isIdle: Bool
    let isComplete: Bool

    func makeNSView(context: Context) -> SlayStageRendererView {
        SlayStageRendererView(frame: CGRect(x: 0, y: 0, width: stageSize, height: stageSize))
    }

    func updateNSView(_ nsView: SlayStageRendererView, context: Context) {
        let state: SlayStageState
        if isRunning {
            state = .running
        } else if isComplete {
            state = .complete
        } else {
            state = .idle
        }

        let stageFrames = SlaySnapshotCache.stageFrames(
            state: state,
            renderMode: renderMode,
            statusColor: statusColor,
            stageSize: stageSize,
            effectTuning: effectTuning
        )
        let avatarFrames = avatarSequenceImages(for: avatar)
        let shouldAnimateAvatar = isRunning && isAnimating
        let stageFrameDuration = renderMode == .superSlay
            ? min(max(0.020, 0.020 * max(effectTuning.orbitDurationMultiplier, effectTuning.arcDurationMultiplier)), 0.025)
            : max(0.10, 0.22 * max(effectTuning.orbitDurationMultiplier, effectTuning.arcDurationMultiplier))
        let showsCounterArc = effectTuning.showsCounterArc ?? (renderMode == .superSlay)
        let showsSecondaryOrbit = effectTuning.showsSecondaryOrbit ?? (renderMode == .superSlay)
        let stageSignature = [
            renderMode.rawValue,
            state == .running ? "running" : (state == .complete ? "complete" : "idle"),
            "\(Int(stageSize.rounded(.toNearestOrAwayFromZero)))",
            NSColor(statusColor).floaterCacheKey,
            "\(Int((max(effectTuning.glowMultiplier, 0.2) * 100).rounded()))",
            "\(showsCounterArc)",
            "\(showsSecondaryOrbit)",
            "\(effectTuning.extraCompletionRays)",
            "\(effectTuning.extraCompletionOrbs)"
        ].joined(separator: ":")
        let avatarSignature = [
            avatar?.id ?? "none",
            shouldAnimateAvatar ? "animated" : "static",
            "\(Int(spriteSize.rounded(.toNearestOrAwayFromZero)))"
        ].joined(separator: ":")
        let avatarPayload = shouldAnimateAvatar ? avatarFrames : Array(avatarFrames.prefix(1))

        nsView.update(
            stageFrames: stageFrames,
            stageFrameDuration: stageFrameDuration,
            stageSignature: stageSignature,
            avatarFrames: avatarPayload,
            avatarFrameDuration: avatarFrameDuration(for: avatar),
            avatarSignature: avatarSignature,
            avatarSize: spriteSize
        )
    }
}

private struct SlayRunningSheenView: View {
    let color: Color
    let cornerRadius: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning

    var body: some View {
        GeometryReader { geometry in
            SlaySheenRendererRepresentable(
                size: geometry.size,
                color: color,
                cornerRadius: cornerRadius,
                renderMode: renderMode,
                effectTuning: effectTuning
            )
        }
        .allowsHitTesting(false)
    }
}

private struct SlaySpriteStageView: View {
    let avatar: FloaterAvatarDefinition?
    let statusColor: Color
    let stageSize: CGFloat
    let spriteSize: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning
    let isAnimating: Bool
    let isRunning: Bool
    let isIdle: Bool
    let isComplete: Bool
    let completeTrigger: UUID?

    @ObservedObject private var ticker = FloaterLowFrequencyTicker.shared
    @State private var idleSparkleTrigger: UUID?
    @State private var doneSparkleTrigger: UUID?

    private var idleSparkleInterval: Int {
        renderMode == .superSlay ? 3 : 8
    }

    private var completeSparkleInterval: Int {
        renderMode == .superSlay ? 6 : 20
    }

    var body: some View {
        ZStack {
            SlayStageRendererRepresentable(
                avatar: avatar,
                statusColor: statusColor,
                stageSize: stageSize,
                spriteSize: spriteSize,
                renderMode: renderMode,
                effectTuning: effectTuning,
                isAnimating: isAnimating,
                isRunning: isRunning,
                isIdle: isIdle,
                isComplete: isComplete
            )

            if isIdle {
                IdleSparkleBurst(trigger: idleSparkleTrigger)
            }

            if isComplete {
                DoneSparkleSweep(color: statusColor, stageSize: stageSize, trigger: doneSparkleTrigger)
                SparkleBurst(trigger: doneSparkleTrigger)
            }
        }
        .frame(width: stageSize, height: stageSize)
        .onAppear {
            if isIdle {
                idleSparkleTrigger = UUID()
            }
            if isComplete {
                doneSparkleTrigger = UUID()
            }
        }
        .onChange(of: ticker.tick) { _, tick in
            if isIdle, tick.isMultiple(of: idleSparkleInterval) {
                idleSparkleTrigger = UUID()
            }
            if isComplete, tick.isMultiple(of: completeSparkleInterval) {
                doneSparkleTrigger = UUID()
            }
        }
        .onChange(of: completeTrigger) { _, newValue in
            guard newValue != nil, isComplete else { return }
            doneSparkleTrigger = UUID()
        }
    }
}

private struct DonePanelVictoryFlash: View {
    let color: Color
    let cornerRadius: CGFloat
    let sweepOffset: CGFloat
    let flashOpacity: Double
    let glowScale: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let sweepWidth = max(size.width * 0.34, 74)
            let travel = size.width + sweepWidth + size.height * 0.92

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(flashOpacity * 0.18),
                                color.opacity(flashOpacity * 0.16),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(size.width, size.height) * 0.82
                        )
                    )
                    .scaleEffect(glowScale)
                    .blur(radius: 12)

                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: color.opacity(flashOpacity * 0.12), location: 0.22),
                                .init(color: .white.opacity(flashOpacity * 0.84), location: 0.50),
                                .init(color: color.opacity(flashOpacity * 0.24), location: 0.78),
                                .init(color: .clear, location: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sweepWidth, height: size.height * 2.1)
                    .blur(radius: 10)
                    .offset(x: travel * sweepOffset - sweepWidth)
                    .rotationEffect(.degrees(-16))
                    .blendMode(.screen)
            }
            .frame(width: size.width, height: size.height)
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Wiggle Effect

private struct WiggleModifier: ViewModifier {
    let isEnabled: Bool

    @State private var angle: Double = 0
    private let timer = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .onReceive(timer) { _ in
                guard isEnabled else { return }
                let target = Double.random(in: -8...8)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.4)) {
                    angle = target
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        angle = 0
                    }
                }
            }
    }
}

// MARK: - Sprite Stage

private struct SpriteStageView: View {
    let avatar: FloaterAvatarDefinition?
    let statusColor: Color
    let stageSize: CGFloat
    let spriteSize: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning
    let isAnimating: Bool
    let isRunning: Bool
    let isIdle: Bool
    let isComplete: Bool
    let completeTrigger: UUID?

    @State private var glowPulse: CGFloat = 1.0
    @State private var runningAuraOpacity: Double = 0.78
    @State private var runningRingScale: CGFloat = 0.84
    @State private var runningRingOpacity: Double = 0
    @State private var runningOrbitAngle: Double = -90
    @State private var runningSpriteScale: CGFloat = 1.0
    @State private var runningArcRotation: Double = -24
    @State private var runningCounterArcRotation: Double = 132
    @State private var runningArcOpacity: Double = 0.46
    @State private var runningSpriteTilt: Double = 0
    @State private var celebrateScale: CGFloat = 1.0
    @State private var celebrateRotation: Double = 0
    @State private var celebrateRingScale: CGFloat = 0.76
    @State private var celebrateRingOpacity: Double = 0
    @State private var doneFlashScale: CGFloat = 0.56
    @State private var doneFlashOpacity: Double = 0
    @State private var doneCoreScale: CGFloat = 0.34
    @State private var doneCoreOpacity: Double = 0
    @State private var doneRayExpansion: CGFloat = 0.18
    @State private var doneRayOpacity: Double = 0
    @State private var doneRayRotation: Double = -26
    @State private var doneOrbitScale: CGFloat = 0.72
    @State private var doneOrbitOpacity: Double = 0
    @State private var doneOrbitRotation: Double = -90
    @State private var doneSpriteLift: CGFloat = 0
    @State private var idleSparkleTrigger: UUID?
    @State private var doneSparkleTrigger: UUID?

    private var isSuperSlay: Bool {
        renderMode == .superSlay
    }

    private var showsCounterArc: Bool {
        effectTuning.showsCounterArc ?? isSuperSlay
    }

    private var showsSecondaryOrbit: Bool {
        effectTuning.showsSecondaryOrbit ?? isSuperSlay
    }

    private var glowMultiplier: Double {
        max(effectTuning.glowMultiplier, 0.2)
    }

    private var completionRayCount: Int {
        max((isSuperSlay ? 10 : 6) + effectTuning.extraCompletionRays, 1)
    }

    private var completionOrbitCount: Int {
        max((isSuperSlay ? 6 : 3) + effectTuning.extraCompletionOrbs, 1)
    }

    private func scaledOpacity(_ value: Double) -> Double {
        min(value * glowMultiplier, 1.0)
    }

    private func scaledRadius(_ value: CGFloat) -> CGFloat {
        value * CGFloat(glowMultiplier)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(isRunning ? 0.42 : 0.34),
                            FloaterPalette.panelShadow.opacity(scaledOpacity(isRunning ? 0.66 : 0.54)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.52
                    )
                )
                .frame(width: stageSize * 0.96, height: stageSize * 0.96)

            // Single soft status-tinted halo. No glass disc.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            statusColor.opacity(scaledOpacity(isRunning ? 0.38 * runningAuraOpacity : 0.20)),
                            statusColor.opacity(scaledOpacity(isRunning ? 0.16 * runningAuraOpacity : 0.06)),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize / 2 + 2
                    )
                )
                .frame(width: stageSize * 1.35 * glowPulse, height: stageSize * 1.35 * glowPulse)
                .blur(radius: scaledRadius(isSuperSlay ? 5 : 3))

            if isRunning {
                Circle()
                    .trim(from: 0.08, to: 0.40)
                    .stroke(statusColor.opacity(scaledOpacity((isSuperSlay ? 0.92 : 0.76) * runningArcOpacity)), style: StrokeStyle(lineWidth: isSuperSlay ? 2.4 : 2.0, lineCap: .round))
                    .frame(width: stageSize * 1.16, height: stageSize * 1.16)
                    .rotationEffect(.degrees(runningArcRotation))
                    .shadow(color: .white.opacity(scaledOpacity(isSuperSlay ? 0.10 * runningArcOpacity : 0)), radius: scaledRadius(isSuperSlay ? 1.2 : 0), x: 0, y: 0)
                    .shadow(color: statusColor.opacity(scaledOpacity((isSuperSlay ? 0.30 : 0.18) * runningArcOpacity)), radius: scaledRadius(isSuperSlay ? 2.6 : 1.6), x: 0, y: 0)

                if showsCounterArc {
                    Circle()
                        .trim(from: 0.56, to: 0.82)
                        .stroke(statusColor.opacity(scaledOpacity(0.52 * runningArcOpacity)), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                        .frame(width: stageSize * 0.96, height: stageSize * 0.96)
                        .rotationEffect(.degrees(runningCounterArcRotation))
                        .shadow(color: statusColor.opacity(scaledOpacity(0.20 * runningArcOpacity)), radius: scaledRadius(1.8), x: 0, y: 0)

                    Circle()
                        .strokeBorder(statusColor.opacity(scaledOpacity(runningRingOpacity)), lineWidth: 1.2)
                        .frame(width: stageSize * runningRingScale, height: stageSize * runningRingScale)
                        .blur(radius: 0.5)
                }

                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.86))
                    Circle()
                        .fill(.white.opacity(0.86))
                        .frame(width: stageSize * 0.08, height: stageSize * 0.08)
                }
                    .frame(width: stageSize * 0.20, height: stageSize * 0.20)
                    .shadow(color: statusColor.opacity(scaledOpacity(isSuperSlay ? 0.54 : 0.38)), radius: scaledRadius(isSuperSlay ? 4 : 3), x: 0, y: 0)
                    .offset(y: -stageSize * 0.43)
                    .rotationEffect(.degrees(runningOrbitAngle))

                if showsSecondaryOrbit {
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.62))
                        Circle()
                            .fill(.white.opacity(0.66))
                            .frame(width: stageSize * 0.05, height: stageSize * 0.05)
                    }
                    .frame(width: stageSize * 0.14, height: stageSize * 0.14)
                    .shadow(color: statusColor.opacity(scaledOpacity(0.28)), radius: scaledRadius(3), x: 0, y: 0)
                    .offset(y: -stageSize * 0.34)
                    .rotationEffect(.degrees(-runningOrbitAngle * 0.78 + 118))
                }
            }

            if isIdle {
                DoneSparkleSweep(color: statusColor, stageSize: stageSize, trigger: idleSparkleTrigger)
            }

            if isComplete {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(doneFlashOpacity * 0.92),
                                statusColor.opacity(doneFlashOpacity * 0.72),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: stageSize * 0.54
                        )
                    )
                    .frame(width: stageSize * doneFlashScale, height: stageSize * doneFlashScale)
                    .blur(radius: 7)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(doneCoreOpacity * 0.96),
                                statusColor.opacity(doneCoreOpacity * 0.82),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: stageSize * 0.40
                        )
                    )
                    .frame(width: stageSize * doneCoreScale, height: stageSize * doneCoreScale)
                    .blur(radius: 2.5)

                ForEach(0..<completionRayCount, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(doneRayOpacity * 0.98),
                                    statusColor.opacity(scaledOpacity(doneRayOpacity * 0.82)),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: index.isMultiple(of: 3) ? (isSuperSlay ? 4.0 : 3.2) : (isSuperSlay ? 2.6 : 2.4),
                            height: stageSize * ((isSuperSlay ? 0.18 : 0.16) + doneRayExpansion * (index.isMultiple(of: 2) ? (isSuperSlay ? 0.50 : 0.42) : (isSuperSlay ? 0.40 : 0.34)))
                        )
                        .offset(y: -stageSize * ((isSuperSlay ? 0.18 : 0.17) + doneRayExpansion * (isSuperSlay ? 0.30 : 0.28)))
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(completionRayCount)) + doneRayRotation))
                        .opacity(doneRayOpacity)
                        .blur(radius: index.isMultiple(of: 4) ? (isSuperSlay ? 0.8 : 0.5) : (isSuperSlay ? 0.2 : 0.1))
                        .blendMode(.screen)
                }

                ForEach(0..<completionOrbitCount, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(doneOrbitOpacity),
                                    statusColor.opacity(doneOrbitOpacity * 0.84),
                                    .clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: stageSize * 0.12
                            )
                        )
                        .frame(
                            width: stageSize * (index.isMultiple(of: 2) ? (isSuperSlay ? 0.14 : 0.13) : (isSuperSlay ? 0.11 : 0.10)),
                            height: stageSize * (index.isMultiple(of: 2) ? (isSuperSlay ? 0.14 : 0.13) : (isSuperSlay ? 0.11 : 0.10))
                        )
                        .offset(y: -stageSize * (isSuperSlay ? 0.48 : 0.44) * doneOrbitScale)
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(completionOrbitCount)) + doneOrbitRotation))
                        .opacity(doneOrbitOpacity)
                        .shadow(color: statusColor.opacity(scaledOpacity(doneOrbitOpacity * (isSuperSlay ? 0.52 : 0.36))), radius: scaledRadius(isSuperSlay ? 5 : 3), x: 0, y: 0)
                        .blendMode(.screen)
                }

                DoneSparkleSweep(color: statusColor, stageSize: stageSize, trigger: doneSparkleTrigger)

                Circle()
                    .strokeBorder(statusColor.opacity(0.85), lineWidth: 1.6)
                    .frame(width: stageSize * celebrateRingScale, height: stageSize * celebrateRingScale)
                    .opacity(celebrateRingOpacity)
                    .blur(radius: 0.5)
            }

            // Sprite - motion gated on state
            Group {
                if let avatar {
                    AvatarArtView(
                        avatar: avatar,
                        isAnimating: isRunning && isAnimating,
                        size: spriteSize
                    )
                } else {
                    Text("\u{1F986}")
                        .font(.system(size: spriteSize - 4))
                }
            }
            .bobbing(isEnabled: isRunning && isAnimating)
            .scaleEffect(celebrateScale * (isRunning ? runningSpriteScale : 1.0))
            .rotationEffect(.degrees(celebrateRotation + (isRunning ? runningSpriteTilt : 0)))
            .offset(y: doneSpriteLift)

            if isIdle {
                IdleSparkleBurst(trigger: idleSparkleTrigger)
            }

            if isComplete {
                SparkleBurst(trigger: doneSparkleTrigger)
            }

        }
        .frame(width: stageSize, height: stageSize)
        .task(id: isRunning) {
            guard isRunning && isAnimating else {
                await MainActor.run {
                    resetRunningAura()
                }
                return
            }

            await MainActor.run {
                glowPulse = 1.0
                runningAuraOpacity = 0.72
                runningRingScale = 0.84
                runningRingOpacity = isSuperSlay ? 0.08 : 0
                runningOrbitAngle = -90
                runningSpriteScale = isSuperSlay ? 0.97 : 0.98
                runningArcRotation = -24
                runningCounterArcRotation = 132
                runningArcOpacity = isSuperSlay ? 0.48 : 0.54
                runningSpriteTilt = isSuperSlay ? -1.4 : -0.8

                withAnimation(.easeInOut(duration: (isSuperSlay ? 1.55 : 3.0) * effectTuning.pulseDurationMultiplier).repeatForever(autoreverses: true)) {
                    glowPulse = isSuperSlay ? 1.18 : 1.12
                    runningAuraOpacity = isSuperSlay ? 1.0 : 0.90
                    runningRingScale = showsCounterArc ? (isSuperSlay ? 1.20 : 1.08) : 0.84
                    runningRingOpacity = isSuperSlay ? 0.42 : 0
                    runningSpriteScale = isSuperSlay ? 1.055 : 1.03
                    runningArcOpacity = isSuperSlay ? 0.94 : 0.78
                    runningSpriteTilt = isSuperSlay ? 2.2 : 1.0
                }

                withAnimation(.linear(duration: (isSuperSlay ? 3.6 : 6.8) * effectTuning.orbitDurationMultiplier).repeatForever(autoreverses: false)) {
                    runningOrbitAngle = 270
                }

                withAnimation(.linear(duration: (isSuperSlay ? 2.15 : 5.8) * effectTuning.arcDurationMultiplier).repeatForever(autoreverses: false)) {
                    runningArcRotation = 336
                }

                if showsCounterArc {
                    withAnimation(.linear(duration: 3.25 * effectTuning.arcDurationMultiplier).repeatForever(autoreverses: false)) {
                        runningCounterArcRotation = -228
                    }
                }
            }
        }
        .onChange(of: completeTrigger) { _, newValue in
            guard newValue != nil, isComplete else { return }
            triggerDoneSparkle(celebrateAvatar: true)
        }
        .task(id: isIdle) {
            guard isIdle else { return }
            triggerIdleSparkle()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((isSuperSlay ? 700_000_000.0 : 1_800_000_000.0) * effectTuning.pulseDurationMultiplier))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    triggerIdleSparkle()
                }
            }
        }
        .task(id: isComplete) {
            guard isComplete else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((isSuperSlay ? 10_000_000_000.0 : 18_000_000_000.0) * effectTuning.completionDurationMultiplier))
                guard !Task.isCancelled, isComplete else { break }
                await MainActor.run {
                    triggerDonePulse()
                }
            }
        }
    }

    private func resetRunningAura() {
        glowPulse = 1.0
        runningAuraOpacity = 0.78
        runningRingScale = 0.84
        runningRingOpacity = 0
        runningOrbitAngle = -90
        runningSpriteScale = 1.0
        runningArcRotation = -24
        runningCounterArcRotation = 132
        runningArcOpacity = 0.54
        runningSpriteTilt = 0
    }

    private func triggerIdleSparkle() {
        idleSparkleTrigger = UUID()
    }

    private func triggerDoneSparkle(celebrateAvatar: Bool) {
        doneSparkleTrigger = UUID()
        pulseCelebrateRing()
        primeDoneSupernova(isMajorBlast: celebrateAvatar)
        guard celebrateAvatar else { return }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            celebrateScale = 1.20
            celebrateRotation = -8
            doneSpriteLift = -4
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                celebrateRotation = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.58)) {
                celebrateScale = 1.0
                doneSpriteLift = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                celebrateRotation = 0
            }
        }
    }

    private func pulseCelebrateRing() {
        celebrateRingScale = 0.76
        celebrateRingOpacity = scaledOpacity(0.84)

        withAnimation(.easeOut(duration: (isSuperSlay ? 0.58 : 0.92) * effectTuning.completionDurationMultiplier)) {
            celebrateRingScale = (isSuperSlay ? 1.38 : 1.24) * CGFloat(effectTuning.flashIntensityMultiplier)
            celebrateRingOpacity = 0
        }
    }

    private func triggerDonePulse() {
        doneSparkleTrigger = UUID()
        pulseCelebrateRing()
    }

    private func primeDoneSupernova(isMajorBlast: Bool) {
        doneFlashScale = isMajorBlast ? 0.48 : 0.62
        doneFlashOpacity = scaledOpacity(isMajorBlast ? 0.96 : 0.60)
        doneCoreScale = 0.32
        doneCoreOpacity = scaledOpacity(isMajorBlast ? 0.98 : 0.72)
        doneRayExpansion = isMajorBlast ? 0.10 : 0.18
        doneRayOpacity = scaledOpacity(isMajorBlast ? 0.94 : 0.58)
        doneRayRotation = isMajorBlast ? -42 : -18
        doneOrbitScale = isMajorBlast ? 0.70 : 0.76
        doneOrbitOpacity = scaledOpacity(isMajorBlast ? 0.88 : 0.38)
        doneOrbitRotation = -90

        withAnimation(.easeOut(duration: (isMajorBlast ? 0.18 : 0.24) * effectTuning.completionDurationMultiplier)) {
            doneFlashScale = (isMajorBlast ? 1.72 : 1.18) * CGFloat(effectTuning.flashIntensityMultiplier)
            doneFlashOpacity = 0
        }

        withAnimation(.spring(response: (isMajorBlast ? 0.34 : 0.44) * effectTuning.completionDurationMultiplier, dampingFraction: isMajorBlast ? 0.56 : 0.70)) {
            doneCoreScale = (isMajorBlast ? 1.26 : 0.94) * CGFloat(effectTuning.flashIntensityMultiplier)
            doneCoreOpacity = 0
            doneRayExpansion = isMajorBlast ? 0.92 : 0.58
            doneOrbitScale = isMajorBlast ? 1.06 : 0.92
            doneOrbitOpacity = scaledOpacity(isMajorBlast ? 0.54 : 0.22)
            doneRayRotation += isMajorBlast ? 126 : 72
        }

        withAnimation(.linear(duration: (isMajorBlast ? 1.15 : 0.90) * effectTuning.completionDurationMultiplier)) {
            doneOrbitRotation = isMajorBlast ? 264 : 170
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ((isMajorBlast ? 0.34 : 0.24) * effectTuning.completionDurationMultiplier)) {
            withAnimation(.easeOut(duration: (isMajorBlast ? 0.62 : 0.48) * effectTuning.completionDurationMultiplier)) {
                doneRayOpacity = 0
                doneOrbitOpacity = 0
            }
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    let color: Color
    let label: String
    let dotSize: CGFloat
    let fontSize: CGFloat
    let renderMode: FloaterRenderMode
    let effectTuning: FloaterEffectTuning
    let isPulsing: Bool
    let showsTypingDots: Bool

    @ObservedObject private var ticker = FloaterLowFrequencyTicker.shared

    private var isSuperSlay: Bool {
        renderMode == .superSlay
    }

    private var pulsePhaseActive: Bool {
        ticker.tick.isMultiple(of: 2)
    }

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if isPulsing {
                    if isSuperSlay {
                        Circle()
                            .fill(color.opacity(pulsePhaseActive ? 0.42 : 0.18))
                            .frame(
                                width: dotSize * (pulsePhaseActive ? 2.2 : 1.55),
                                height: dotSize * (pulsePhaseActive ? 2.2 : 1.55)
                            )
                            .opacity(pulsePhaseActive ? 0.42 : 0.18)
                    } else {
                        Circle()
                            .fill(color.opacity(pulsePhaseActive ? 0.24 : 0.12))
                            .frame(
                                width: dotSize * (pulsePhaseActive ? 2.0 : 1.5),
                                height: dotSize * (pulsePhaseActive ? 2.0 : 1.5)
                            )
                            .opacity(pulsePhaseActive ? 0.24 : 0.12)
                    }
                }
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: color.opacity(0.6), radius: isPulsing ? 3 : 1.5, x: 0, y: 0)
            }
            .frame(width: dotSize + 4, height: dotSize + 4)

            Text(label)
                .font(.system(size: fontSize, weight: .semibold))
                .tracking(-0.1)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()

            if showsTypingDots {
                Group {
                    if isSuperSlay {
                        TypingDots(color: color, fontSize: fontSize)
                    } else {
                        LiteTypingDots(color: color, fontSize: fontSize)
                    }
                }
                .padding(.leading, 2)
            }
        }
        .padding(.leading, 5)
        .padding(.trailing, 7)
        .padding(.vertical, 2)
        .background(
            Capsule().fill(color.opacity(0.12))
        )
        .overlay(
            Capsule().strokeBorder(color.opacity(0.24), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.35 * effectTuning.statusPulseDurationMultiplier), value: pulsePhaseActive)
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat = 0

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 6) * 10 * (1 - animatableData)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

private struct CompletionShakeModifier: ViewModifier {
    let shakeTrigger: UUID?

    @State private var shakeOffsetX: CGFloat = 0
    @State private var shakeRotation: Double = 0
    @State private var shakeScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffsetX)
            .rotationEffect(.degrees(shakeRotation))
            .scaleEffect(shakeScale)
            .onChange(of: shakeTrigger) { _, newValue in
                guard newValue != nil else { return }
                performShake()
            }
    }

    private func performShake() {
        shakeOffsetX = 0
        shakeRotation = 0
        shakeScale = 1.0

        withAnimation(.easeOut(duration: 0.06)) {
            shakeOffsetX = -11
            shakeRotation = -1.2
            shakeScale = 1.012
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.easeInOut(duration: 0.08)) {
                shakeOffsetX = 10
                shakeRotation = 1.1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeInOut(duration: 0.08)) {
                shakeOffsetX = -7
                shakeRotation = -0.8
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.easeInOut(duration: 0.07)) {
                shakeOffsetX = 5
                shakeRotation = 0.5
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.29) {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.72)) {
                shakeOffsetX = 0
                shakeRotation = 0
                shakeScale = 1.0
            }
        }
    }
}

// MARK: - Drag Region

private final class WindowDragRegionView: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? { self }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

private struct WindowDragRegion: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragRegionView {
        let view = WindowDragRegionView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }

    func updateNSView(_ nsView: WindowDragRegionView, context: Context) {}
}

// MARK: - Floater Panel Header

private struct FloaterPanelHeaderView: View {
    let itemCount: Int
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void

    @State private var isHoveringCollapse = false

    private let animation = Animation.interpolatingSpring(
        mass: 1.0, stiffness: 160, damping: 18, initialVelocity: 0.0
    )

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                WindowDragRegion()

                HStack(spacing: 7) {
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 2) {
                                Circle().fill(.white.opacity(0.22)).frame(width: 2.5, height: 2.5)
                                Circle().fill(.white.opacity(0.22)).frame(width: 2.5, height: 2.5)
                            }
                        }
                    }

                    Text("Floaters")
                        .font(.system(size: 11.5, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundStyle(FloaterPalette.primaryText)

                    Text("\(itemCount)")
                        .font(.system(size: 10, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(FloaterPalette.secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(FloaterPalette.chipFill.opacity(0.85)))

                    Spacer(minLength: 0)
                }
                .padding(.leading, 8)
                .padding(.trailing, 3)
                .padding(.vertical, 5)
                .allowsHitTesting(false)
            }

            Capsule()
                .fill(FloaterPalette.strokeSoft.opacity(0.55))
                .frame(width: 1, height: 14)

            Button(action: onToggleCollapsed) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isHoveringCollapse ? FloaterPalette.primaryText : FloaterPalette.secondaryText)
                    .rotationEffect(.degrees(isCollapsed ? 180 : 0))
                    .animation(animation, value: isCollapsed)
                    .frame(width: 26, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHoveringCollapse = $0 }
        }
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(FloaterPalette.panelTint.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(.thinMaterial.opacity(0.14))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(FloaterPalette.highlight.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: FloaterPalette.panelShadow.opacity(0.18), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Floater Panel

struct FloaterPanelView: View {
    let items: [FloaterPanelItem]
    let spacing: CGFloat
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void
    let onItemTap: (PersistentStatusItem) -> Void
    let onItemClose: (PersistentStatusItem) -> Void

    private let animation = Animation.interpolatingSpring(
        mass: 1.0, stiffness: 160, damping: 18, initialVelocity: 0.0
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FloaterPanelHeaderView(
                itemCount: items.count,
                isCollapsed: isCollapsed,
                onToggleCollapsed: {
                    withAnimation(animation) { onToggleCollapsed() }
                }
            )

            if !isCollapsed {
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(items) { item in
                        FloatNotificationView(
                            message: item.item.state.message,
                            project: item.item.project,
                            corner: .bottomRight,
                            effect: item.effect,
                            onTap: { onItemTap(item.item) },
                            onClose: { onItemClose(item.item) },
                            statusIndicatorColor: item.item.state.indicatorColor,
                            statusState: item.item.state,
                            avatar: item.avatar,
                            animatesStatus: item.item.state.animatesIndicator,
                            isDraggablePanel: true,
                            playsEntryAnimation: item.playsEntryAnimation,
                            floaterSize: item.floaterSize,
                            renderMode: item.renderMode,
                            effectPreset: item.effectPreset,
                            lastActivity: item.item.lastActivity,
                            modifiedFilesCount: item.item.modifiedFilesCount,
                            shouldShake: item.shouldShake,
                            dismissController: item.dismissController
                        )
                    }
                }
                .padding(.top, spacing)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top)
                            .combined(with: .opacity)
                            .animation(.interpolatingSpring(mass: 1, stiffness: 140, damping: 16)),
                        removal: .scale(scale: 0.95, anchor: .top)
                            .combined(with: .opacity)
                            .animation(.easeOut(duration: 0.22))
                    )
                )
            }
        }
        .padding(6)
        .fixedSize()
        .background(.clear)
        .animation(animation, value: isCollapsed)
    }
}

// MARK: - FloatNotificationView

struct FloatNotificationView: View {
    let message: String
    var project: String?
    var corner: Corner = .bottomRight
    var effect: String?
    var sound: String?
    var onTap: (() -> Void)?
    var onClose: (() -> Void)?
    var statusIndicatorColor: Color?
    var statusState: ClaudeStatusState?
    var avatar: FloaterAvatarDefinition?
    var animatesStatus = true
    var isDraggablePanel = false
    var playsEntryAnimation = true
    var floaterSize: FloaterSize = .regular
    var renderMode: FloaterRenderMode = .slay
    var effectPreset: FloaterEffectPreset = FloaterEffectPreset.builtInPresets[0]
    var isCompact: Bool = false
    var lastActivity: Date?
    var modifiedFilesCount: Int = 0
    var shouldShake: Bool = false
    @ObservedObject var dismissController: DismissController

    @State private var isHovering = false
    @State private var isCloseHovering = false
    @State private var isAvatarHovering = false
    @State private var panelScale: CGFloat
    @State private var panelOpacity: CGFloat
    @State private var shakeTrigger: UUID?
    @State private var completionTrigger: UUID?
    @State private var lastObservedStatusState: ClaudeStatusState?
    @State private var panelVictoryFlashOffset: CGFloat
    @State private var panelVictoryFlashOpacity: Double
    @State private var panelVictoryFlashScale: CGFloat
    @StateObject private var particleSystem = ParticleSystem()

    init(
        message: String,
        project: String? = nil,
        corner: Corner = .bottomRight,
        effect: String? = nil,
        sound: String? = nil,
        onTap: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        statusIndicatorColor: Color? = nil,
        statusState: ClaudeStatusState? = nil,
        avatar: FloaterAvatarDefinition? = nil,
        animatesStatus: Bool = true,
        isDraggablePanel: Bool = false,
        playsEntryAnimation: Bool = true,
        floaterSize: FloaterSize = .regular,
        renderMode: FloaterRenderMode = .slay,
        effectPreset: FloaterEffectPreset = FloaterEffectPreset.builtInPresets[0],
        isCompact: Bool = false,
        lastActivity: Date? = nil,
        modifiedFilesCount: Int = 0,
        shouldShake: Bool = false,
        dismissController: DismissController
    ) {
        self.message = message
        self.project = project
        self.corner = corner
        self.effect = effect
        self.sound = sound
        self.onTap = onTap
        self.onClose = onClose
        self.statusIndicatorColor = statusIndicatorColor
        self.statusState = statusState
        self.avatar = avatar
        self.animatesStatus = animatesStatus
        self.isDraggablePanel = isDraggablePanel
        self.playsEntryAnimation = playsEntryAnimation
        self.floaterSize = floaterSize
        self.renderMode = renderMode
        self.effectPreset = effectPreset
        self.isCompact = isCompact || floaterSize == .compact
        self.lastActivity = lastActivity
        self.modifiedFilesCount = modifiedFilesCount
        self.shouldShake = shouldShake
        self.dismissController = dismissController
        _panelScale = State(initialValue: playsEntryAnimation ? 0.92 : 1.0)
        _panelOpacity = State(initialValue: playsEntryAnimation ? 0 : 1.0)
        _shakeTrigger = State(initialValue: shouldShake ? UUID() : nil)
        _completionTrigger = State(initialValue: nil)
        _lastObservedStatusState = State(initialValue: statusState)
        _panelVictoryFlashOffset = State(initialValue: -1.2)
        _panelVictoryFlashOpacity = State(initialValue: 0)
        _panelVictoryFlashScale = State(initialValue: 0.94)
    }

    private var effectiveSound: String? {
        sound ?? corner.defaultSound
    }

    private var isRunning: Bool {
        statusState?.isProgressState == true
    }

    private var accentColor: Color {
        statusIndicatorColor ?? .blue
    }

    private var effectTuning: FloaterEffectTuning {
        effectPreset.tuning
    }

    private var effectGlowMultiplier: Double {
        max(effectTuning.glowMultiplier, 0.2)
    }

    private var usesMinimalRenderMode: Bool {
        isPersistent && renderMode == .lame
    }

    private var isSuperSlayRenderMode: Bool {
        renderMode == .superSlay
    }

    private var showsFancyFloaterEffects: Bool {
        isPersistent && renderMode != .lame
    }

    private var showsParticleTrail: Bool {
        corner == .cursorFollow && renderMode != .lame && (effectTuning.showsParticleTrail ?? true)
    }

    private func scaledGlow(_ value: Double) -> Double {
        min(value * effectGlowMultiplier, 1.0)
    }

    private var animatesPersistentStatus: Bool {
        renderMode != .lame && animatesStatus
    }

    private var avatarBackgroundPrimaryOpacity: Double {
        guard let statusState else { return 0.18 }
        switch statusState {
        case .running, .committing, .pushing: return 0.42
        case .idle: return 0.34
        case .complete: return 0.30
        }
    }

    private var avatarBackgroundSecondaryOpacity: Double {
        guard let statusState else { return 0.08 }
        switch statusState {
        case .running, .committing, .pushing: return 0.24
        case .idle: return 0.20
        case .complete: return 0.18
        }
    }

    private var avatarBackgroundBorderOpacity: Double {
        guard let statusState else { return 0.08 }
        switch statusState {
        case .running, .committing, .pushing: return 0.18
        case .idle: return 0.16
        case .complete: return 0.14
        }
    }

    private var stateLabel: String? {
        guard let state = statusState else { return nil }
        switch state {
        case .running: return "Running"
        case .committing: return "Commit"
        case .pushing: return "Push"
        case .idle: return "Idle"
        case .complete: return "Done"
        }
    }

    private var completeTrigger: UUID? {
        completionTrigger
    }

    private var showsRunningDuration: Bool {
        !usesMinimalRenderMode && isRunning && lastActivity != nil
    }

    private var showsActivitySection: Bool {
        showsRunningDuration
    }

    private func runningDurationText(referenceDate: Date) -> String? {
        guard let lastActivity else { return nil }
        let elapsed = max(Int(referenceDate.timeIntervalSince(lastActivity)), 0)
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var projectName: String {
        project ?? "Claude Code"
    }

    private var isPersistent: Bool {
        isDraggablePanel && statusIndicatorColor != nil
    }

    private var trailingContentInset: CGFloat {
        guard isPersistent else { return floaterSize.trailingInset }
        guard onClose != nil else { return floaterSize.trailingInset }
        return floaterSize.hoverTrailingInset
    }

    var body: some View {
        ZStack {
            if showsParticleTrail {
                ParticleTrailView(system: particleSystem, color: FloaterPalette.idle)
                    .frame(width: 300, height: 100)
            }

            panelBackground

            if isPersistent {
                persistentContent
            } else {
                temporaryContent
            }
        }
        .frame(
            width: isPersistent ? floaterSize.persistentPanelWidth : floaterSize.panelWidth,
            height: floaterSize.rowHeight
        )
        .clipShape(RoundedRectangle(cornerRadius: floaterSize.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                .strokeBorder(FloaterPalette.highlight.opacity(isHovering ? 0.14 : 0.08), lineWidth: 1)
        )
        .overlay {
            if showsFancyFloaterEffects {
                ZStack {
                    if isRunning, effectTuning.showsSheen ?? true {
                        SlayRunningSheenView(
                            color: accentColor,
                            cornerRadius: floaterSize.cornerRadius,
                            renderMode: renderMode,
                            effectTuning: effectTuning
                        )
                    }

                    DonePanelVictoryFlash(
                        color: accentColor,
                        cornerRadius: floaterSize.cornerRadius,
                        sweepOffset: panelVictoryFlashOffset,
                        flashOpacity: panelVictoryFlashOpacity,
                        glowScale: panelVictoryFlashScale
                    )
                    .opacity(panelVictoryFlashOpacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .compositingGroup()
                .clipShape(RoundedRectangle(cornerRadius: floaterSize.cornerRadius))
            }
        }
        .overlay(alignment: .topTrailing) {
            if isPersistent, onClose != nil {
                closeButton
                    .padding(.top, 5)
                    .padding(.trailing, 5)
                    .opacity(isHovering ? 1 : 0.72)
                    .scaleEffect(isHovering ? 1 : 0.96)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
        }
        .shadow(color: FloaterPalette.panelShadow.opacity(isHovering ? 0.22 : 0.16), radius: isHovering ? floaterSize.cardShadowRadius : max(floaterSize.cardShadowRadius - 2, 6), x: 0, y: isHovering ? 5 : 3)
        .shadow(color: accentColor.opacity(scaledGlow(isRunning ? 0.08 : 0.03)), radius: isHovering ? 10 : 7, x: 0, y: 2)
        .animation(.easeInOut(duration: 0.18), value: isHovering)
        .animation(.easeInOut(duration: 0.22), value: accentColor)
        .scaleEffect(panelScale)
        .opacity(panelOpacity)
        .onHover { isHovering = $0 }
        .onAppear {
            if playsEntryAnimation {
                triggerEntry()
            }
            syncCompletionAnimation(for: statusState, animateInitialComplete: statusState == .complete)
            if shouldShake {
                shakeTrigger = UUID()
            }
        }
        .onChange(of: statusState) { _, newValue in
            syncCompletionAnimation(for: newValue)
        }
        .onChange(of: shouldShake) { _, newValue in
            if newValue { shakeTrigger = UUID() }
        }
        .onChange(of: dismissController.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss { triggerExit() }
        }
        .modifier(CompletionShakeModifier(shakeTrigger: shakeTrigger))
    }

    private var panelBackground: some View {
        ZStack {
            if usesMinimalRenderMode {
                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .fill(FloaterPalette.panelTint.opacity(isHovering ? 0.94 : 0.90))

                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .fill(accentColor.opacity(isRunning ? 0.10 : 0.06))
            } else {
                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .fill(FloaterPalette.panelTint.opacity(isHovering ? 0.94 : 0.90))
                    .overlay(
                        RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                            .fill(.thinMaterial.opacity(0.16))
                    )

                if isPersistent {
                    RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(isRunning ? (isSuperSlayRenderMode ? 0.20 : 0.14) : (isSuperSlayRenderMode ? 0.12 : 0.08)),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                FloaterPalette.highlight.opacity(0.08),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                if isSuperSlayRenderMode {
                    RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                        .strokeBorder(.white.opacity(isRunning ? 0.12 : 0.08), lineWidth: 0.8)
                }
            }
        }
    }

    @ViewBuilder
    private var persistentContent: some View {
        HStack(spacing: 0) {
            Button(action: {
                NSLog("Floatify: Avatar tapped, invoking onTap")
                onTap?()
            }) {
                ZStack {
                    persistentAvatarBackground
                    avatarStage
                        .scaleEffect(usesMinimalRenderMode ? 1.0 : (isAvatarHovering ? 1.06 : 1.0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAvatarHovering)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .frame(width: floaterSize.avatarHitSize, height: floaterSize.avatarHitSize)
            .onHover { isAvatarHovering = $0 }
            .help("Open project in editor")

            persistentBody
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, floaterSize.contentSpacing)
                .padding(.trailing, trailingContentInset)
        }
    }

    @ViewBuilder
    private var persistentBody: some View {
        VStack(alignment: .leading, spacing: floaterSize.bodySpacing) {
            Text(projectName)
                .font(.system(size: floaterSize.projectFontSize, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(FloaterPalette.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)
                .help(projectName)

            persistentMetaLine
        }
    }

    @ViewBuilder
    private var persistentMetaLine: some View {
        HStack(spacing: 5) {
            if let stateLabel {
                StatusPill(
                    color: accentColor,
                    label: stateLabel,
                    dotSize: floaterSize.dotSize,
                    fontSize: floaterSize.metaFontSize,
                    renderMode: renderMode,
                    effectTuning: effectTuning,
                    isPulsing: isRunning && animatesPersistentStatus,
                    showsTypingDots: isRunning && animatesPersistentStatus
                )
                .fixedSize(horizontal: true, vertical: false)
            }

            if showsRunningDuration {
                if let lastActivity {
                    RunningDurationBadge(
                        lastActivity: lastActivity,
                        floaterSize: floaterSize,
                        accentColor: accentColor
                    )
                }
            }

            if showsActivitySection, modifiedFilesCount > 0 {
                Circle()
                    .fill(FloaterPalette.secondaryText.opacity(0.45))
                    .frame(width: 2, height: 2)
            }

            if modifiedFilesCount > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "pencil")
                        .font(.system(size: floaterSize.metaFontSize - 1, weight: .semibold))
                    Text("\(modifiedFilesCount)")
                        .font(.system(size: floaterSize.metaFontSize, weight: .semibold))
                        .monospacedDigit()
                }
                .foregroundStyle(FloaterPalette.warning)
                .fixedSize()
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var avatarStage: some View {
        if usesMinimalRenderMode {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.18))
                    .frame(
                        width: floaterSize.persistentStageSize * 0.58,
                        height: floaterSize.persistentStageSize * 0.58
                    )

                Circle()
                    .fill(accentColor.opacity(0.94))
                    .frame(
                        width: max(floaterSize.dotSize * 1.8, floaterSize.persistentStageSize * 0.22),
                        height: max(floaterSize.dotSize * 1.8, floaterSize.persistentStageSize * 0.22)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            SlaySpriteStageView(
                avatar: avatar,
                statusColor: accentColor,
                stageSize: floaterSize.persistentStageSize,
                spriteSize: floaterSize.persistentSpriteSize,
                renderMode: renderMode,
                effectTuning: effectTuning,
                isAnimating: animatesStatus,
                isRunning: isRunning,
                isIdle: statusState == .idle,
                isComplete: statusState == .complete,
                completeTrigger: completeTrigger
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var persistentAvatarBackground: some View {
        Rectangle()
            .fill(avatarBackgroundFill)
            .overlay {
                if !usesMinimalRenderMode {
                    LinearGradient(
                        colors: [
                            FloaterPalette.highlight.opacity(isSuperSlayRenderMode ? 0.18 : 0.10),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .overlay(
                Rectangle()
                    .strokeBorder(accentColor.opacity(avatarBackgroundBorderOpacity), lineWidth: 0.8)
            )
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(accentColor.opacity(avatarBackgroundBorderOpacity))
                    .frame(width: 1)
                    .padding(.vertical, 4)
            }
    }

    private var avatarBackgroundFill: AnyShapeStyle {
        if usesMinimalRenderMode {
            return AnyShapeStyle(accentColor.opacity(0.20))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    accentColor.opacity(scaledGlow(avatarBackgroundPrimaryOpacity)),
                    accentColor.opacity(scaledGlow(avatarBackgroundSecondaryOpacity)),
                    FloaterPalette.panelShadow.opacity(0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    @ViewBuilder
    private var temporaryContent: some View {
        HStack(spacing: 10) {
            // Sprite avatar (or duck fallback) for personality
            AvatarArtView(
                avatar: avatar,
                isAnimating: animatesStatus,
                size: floaterSize.spriteSize - 4
            )
            .bobbing(isEnabled: animatesStatus)
            .floatDrift(isEnabled: animatesStatus)

            Text(message)
                .font(.system(size: floaterSize.projectFontSize + 0.5, weight: .medium))
                .tracking(-0.1)
                .foregroundStyle(FloaterPalette.primaryText)
                .lineLimit(2)

            Spacer(minLength: 4)

            if let project {
                Text(project)
                    .font(.system(size: floaterSize.metaFontSize, weight: .semibold))
                    .tracking(-0.1)
                    .foregroundStyle(FloaterPalette.secondaryText)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(FloaterPalette.chipFill.opacity(0.88)))
                    .overlay(Capsule().strokeBorder(FloaterPalette.strokeSoft.opacity(0.42), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, floaterSize.horizontalPadding)
    }

    private var closeButton: some View {
        Button(action: { onClose?() }) {
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(isCloseHovering ? FloaterPalette.primaryText : FloaterPalette.secondaryText)
                .frame(width: floaterSize.closeButtonSize, height: floaterSize.closeButtonSize)
                .background(
                    Circle()
                        .fill(isCloseHovering ? FloaterPalette.closeHover.opacity(0.92) : FloaterPalette.chipFill.opacity(0.46))
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isCloseHovering ? 1.06 : 1.0)
        .onHover { isCloseHovering = $0 }
    }

    private func triggerEntry() {
        SoundManager.shared.play(effectiveSound)
        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
            panelScale = 1.0
            panelOpacity = 1.0
        }
    }

    private func triggerExit() {
        withAnimation(.easeOut(duration: 0.20)) {
            panelScale = 0.93
            panelOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            dismissController.onDismissComplete?()
        }
    }

    private func syncCompletionAnimation(for newState: ClaudeStatusState?, animateInitialComplete: Bool = false) {
        let shouldAnimate = newState == .complete && (animateInitialComplete || lastObservedStatusState != .complete)
        lastObservedStatusState = newState
        guard shouldAnimate else { return }
        let trigger = UUID()
        completionTrigger = trigger
        shakeTrigger = trigger
        triggerPanelVictoryFlash()
    }

    private func triggerPanelVictoryFlash() {
        panelVictoryFlashOffset = -1.2
        panelVictoryFlashOpacity = 0
        panelVictoryFlashScale = (isSuperSlayRenderMode ? 0.84 : 0.92) * CGFloat(effectTuning.flashIntensityMultiplier)

        withAnimation(.easeOut(duration: (isSuperSlayRenderMode ? 0.10 : 0.12) * effectTuning.completionDurationMultiplier)) {
            panelVictoryFlashOpacity = scaledGlow(isSuperSlayRenderMode ? 1.0 : 0.96)
            panelVictoryFlashScale = (isSuperSlayRenderMode ? 1.08 : 1.03) * CGFloat(effectTuning.flashIntensityMultiplier)
        }

        withAnimation(.linear(duration: (isSuperSlayRenderMode ? 0.54 : 0.64) * effectTuning.completionDurationMultiplier)) {
            panelVictoryFlashOffset = 1.18
        }

        withAnimation(.spring(response: (isSuperSlayRenderMode ? 0.20 : 0.26) * effectTuning.completionDurationMultiplier, dampingFraction: isSuperSlayRenderMode ? 0.50 : 0.58)) {
            panelScale = (isSuperSlayRenderMode ? 1.055 : 1.035) * CGFloat(min(effectTuning.flashIntensityMultiplier, 1.08))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (0.20 * effectTuning.completionDurationMultiplier)) {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.74)) {
                panelScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (0.18 * effectTuning.completionDurationMultiplier)) {
            withAnimation(.easeIn(duration: (isSuperSlayRenderMode ? 0.42 : 0.36) * effectTuning.completionDurationMultiplier)) {
                panelVictoryFlashOpacity = 0
                panelVictoryFlashScale = (isSuperSlayRenderMode ? 1.18 : 1.12) * CGFloat(effectTuning.flashIntensityMultiplier)
            }
        }
    }
}
