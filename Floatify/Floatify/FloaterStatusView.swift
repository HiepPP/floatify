import AppKit
import Darwin
import ImageIO
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
    let idle: Color
    let complete: Color
    let warning: Color
    let chipFill: Color
    let closeHover: Color
}

enum FloaterPalette {
    private static func palette(for theme: FloaterTheme) -> FloaterThemePalette {
        switch theme {
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
                idle: Color(red: 0.773, green: 0.541, blue: 0.082),
                complete: Color(red: 0.133, green: 0.541, blue: 0.384),
                warning: Color(red: 0.851, green: 0.467, blue: 0.227),
                chipFill: Color(red: 0.914, green: 0.933, blue: 0.969),
                closeHover: Color(red: 0.863, green: 0.894, blue: 0.945)
            )
        }
    }

    private static var palette: FloaterThemePalette {
        palette(for: FloaterTheme.current)
    }

    static var panelTint: Color { palette.panelTint }
    static var panelShadow: Color { palette.panelShadow }
    static var primaryText: Color { palette.primaryText }
    static var secondaryText: Color { palette.secondaryText }
    static var strokeStrong: Color { palette.strokeStrong }
    static var strokeSoft: Color { palette.strokeSoft }
    static var highlight: Color { palette.highlight }
    static var running: Color { palette.running }
    static var idle: Color { palette.idle }
    static var complete: Color { palette.complete }
    static var warning: Color { palette.warning }
    static var chipFill: Color { palette.chipFill }
    static var closeHover: Color { palette.closeHover }

    static func statusColor(for state: ClaudeStatusState, theme: FloaterTheme) -> Color {
        let palette = palette(for: theme)
        switch state {
        case .running:
            return palette.running
        case .idle:
            return palette.idle
        case .complete:
            return palette.complete
        }
    }
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

private final class CachedCGImageBox: NSObject {
    let image: CGImage

    init(_ image: CGImage) {
        self.image = image
    }
}

private enum AvatarImageCache {
    private static let spriteSheets: NSCache<NSString, CachedCGImageBox> = {
        let cache = NSCache<NSString, CachedCGImageBox>()
        cache.countLimit = 12
        return cache
    }()

    private static let croppedFrames: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 96
        return cache
    }()

    private static let staticImages: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 24
        return cache
    }()

    static func cgImage(for source: FloaterAvatarImageSource) -> CGImage? {
        let key = cacheKey(for: source)
        let cacheKey = key as NSString
        if let cached = spriteSheets.object(forKey: cacheKey) {
            return cached.image
        }

        guard let url = url(for: source),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        spriteSheets.setObject(CachedCGImageBox(image), forKey: cacheKey)
        return image
    }

    static func staticImage(for source: FloaterAvatarImageSource) -> NSImage? {
        let key = cacheKey(for: source)
        let cacheKey = key as NSString
        if let cached = staticImages.object(forKey: cacheKey) {
            return cached
        }

        guard let url = url(for: source),
              let image = NSImage(contentsOf: url) else {
            return nil
        }

        staticImages.setObject(image, forKey: cacheKey)
        return image
    }

    static func frameImage(for rect: CGRect, source: FloaterAvatarImageSource) -> NSImage? {
        let key = "\(cacheKey(for: source)):\(Int(rect.origin.x)):\(Int(rect.origin.y)):\(Int(rect.size.width)):\(Int(rect.size.height))"
        let cacheKey = key as NSString
        if let cached = croppedFrames.object(forKey: cacheKey) {
            return cached
        }

        guard let sheet = cgImage(for: source),
              let cropped = sheet.cropping(to: rect) else {
            return nil
        }

        let image = NSImage(cgImage: cropped, size: rect.size)
        croppedFrames.setObject(image, forKey: cacheKey)
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
    private var subscriberCount = 0

    private init() {}

    func activate() {
        subscriberCount += 1
        guard timer == nil else { return }

        now = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.now = Date()
                self.tick += 1
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func deactivate() {
        subscriberCount = max(subscriberCount - 1, 0)
        guard subscriberCount == 0 else { return }
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}

@MainActor
private final class FloatifyCPUUsageMonitor: ObservableObject {
    static let shared = FloatifyCPUUsageMonitor()

    @Published private(set) var cpuPercent: Double = 0

    private struct Sample {
        let cpuTime: TimeInterval
        let timestamp: CFTimeInterval
    }

    private var timer: Timer?
    private var lastSample: Sample?
    private var subscriberCount = 0

    private init() {}

    func activate() {
        subscriberCount += 1
        guard timer == nil else { return }

        lastSample = makeSample()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            MainActor.assumeIsolated {
                self.refresh()
            }
        }

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func deactivate() {
        subscriberCount = max(subscriberCount - 1, 0)
        guard subscriberCount == 0 else { return }
        timer?.invalidate()
        timer = nil
        lastSample = nil
        cpuPercent = 0
    }

    private func refresh() {
        guard let currentSample = makeSample() else { return }
        defer { lastSample = currentSample }
        guard let lastSample else { return }

        let cpuDelta = currentSample.cpuTime - lastSample.cpuTime
        let timeDelta = currentSample.timestamp - lastSample.timestamp
        guard timeDelta > 0 else { return }

        cpuPercent = max(0, (cpuDelta / timeDelta) * 100)
    }

    private func makeSample() -> Sample? {
        var info = task_thread_times_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_thread_times_info_data_t>.stride / MemoryLayout<natural_t>.stride)

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(TASK_THREAD_TIMES_INFO),
                    reboundPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let userTime = TimeInterval(info.user_time.seconds) + TimeInterval(info.user_time.microseconds) / 1_000_000
        let systemTime = TimeInterval(info.system_time.seconds) + TimeInterval(info.system_time.microseconds) / 1_000_000
        return Sample(cpuTime: userTime + systemTime, timestamp: CACurrentMediaTime())
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
        .onAppear {
            FloaterLowFrequencyTicker.shared.activate()
        }
        .onDisappear {
            FloaterLowFrequencyTicker.shared.deactivate()
        }
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
        .onAppear {
            FloaterLowFrequencyTicker.shared.activate()
        }
        .onDisappear {
            FloaterLowFrequencyTicker.shared.deactivate()
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
        .onAppear {
            FloaterLowFrequencyTicker.shared.activate()
        }
        .onDisappear {
            FloaterLowFrequencyTicker.shared.deactivate()
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
        let symbols = ["\u{2728}", "\u{2B50}", "\u{1F31F}", "\u{1F4AB}", "\u{26A1}", "\u{1F389}"] // ✨ ⭐ 🌟 💫 ⚡ 🎉
        particles = (0..<7).map { i in
            SparkleParticle(
                angle: .pi * 2 * Double(i) / 7 + Double.random(in: -0.4...0.4),
                distance: CGFloat.random(in: 20...32),
                delay: Double(i) * 0.035,
                symbol: symbols.randomElement() ?? "\u{2728}",
                scale: CGFloat.random(in: 0.85...1.45)
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
        let symbols = ["\u{2728}", "\u{2736}", "\u{2B50}", "\u{1F4AB}"] // ✨ ✶ ⭐ 💫
        particles = (0..<4).map { i in
            IdleSparkleParticle(
                angle: .pi * 2 * Double(i) / 4 + Double.random(in: -0.35...0.35),
                distance: CGFloat.random(in: 12...18),
                delay: Double(i) * 0.03,
                symbol: symbols.randomElement() ?? "\u{2728}",
                scale: CGFloat.random(in: 0.80...1.15)
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

private struct CelebrateRingBurst: View {
    let color: Color
    let stageSize: CGFloat
    let trigger: UUID?

    @State private var ringScale: CGFloat = 0.76
    @State private var ringOpacity: Double = 0
    @State private var ring2Scale: CGFloat = 0.6
    @State private var ring2Opacity: Double = 0
    @State private var ring3Scale: CGFloat = 0.5
    @State private var ring3Opacity: Double = 0

    var body: some View {
        ZStack {
            // Primary thick ring (Nintendo power-up)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(ringOpacity * 0.9), color.opacity(ringOpacity)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2.2
                )
                .frame(width: stageSize * ringScale, height: stageSize * ringScale)
                .shadow(color: color.opacity(ringOpacity * 0.6), radius: 4)
                .blur(radius: 0.3)

            // Second shockwave ring (staggered)
            Circle()
                .strokeBorder(color.opacity(ring2Opacity * 0.7), lineWidth: 1.4)
                .frame(width: stageSize * ring2Scale, height: stageSize * ring2Scale)
                .blur(radius: 0.5)

            // Third faint outer ring
            Circle()
                .strokeBorder(color.opacity(ring3Opacity * 0.5), lineWidth: 1.0)
                .frame(width: stageSize * ring3Scale, height: stageSize * ring3Scale)
                .blur(radius: 0.6)
        }
        .allowsHitTesting(false)
        .onAppear {
            if trigger != nil { animateRings() }
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != nil else { return }
            animateRings()
        }
    }

    private func animateRings() {
        ringScale = 0.76
        ringOpacity = 0.92
        ring2Scale = 0.6
        ring2Opacity = 0
        ring3Scale = 0.5
        ring3Opacity = 0

        withAnimation(.easeOut(duration: 0.55)) {
            ringScale = 1.42
            ringOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            ring2Opacity = 0.82
            withAnimation(.easeOut(duration: 0.62)) {
                ring2Scale = 1.58
                ring2Opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            ring3Opacity = 0.68
            withAnimation(.easeOut(duration: 0.70)) {
                ring3Scale = 1.76
                ring3Opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            ringScale = 0.76
            ringOpacity = 0
            ring2Scale = 0.6
            ring2Opacity = 0
            ring3Scale = 0.5
            ring3Opacity = 0
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
                                .init(color: color.opacity(scaledOpacity(isSuperSlay ? 0.16 : 0.09)), location: 0.22),
                                .init(color: .white.opacity(scaledOpacity(isSuperSlay ? 0.42 : 0.26)), location: 0.50),
                                .init(color: color.opacity(scaledOpacity(isSuperSlay ? 0.22 : 0.12)), location: 0.78),
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

private struct SlayLEDStripCacheKey: Hashable {
    let width: Int
    let height: Int
    let cornerRadius: Int
    let colorKey: String
}

private struct SlayScanSweepCacheKey: Hashable {
    let width: Int
    let height: Int
    let colorKey: String
}

private struct SlayRainbowBorderCacheKey: Hashable {
    let width: Int
    let height: Int
    let cornerRadius: Int
    let intensityBucket: Int
}

private enum SlayPrebuiltSequenceKind: String {
    case stage = "stage"
    case sheen = "sheen"
    case ledStrip = "led-strip"
    case scanSweep = "scan-sweep"
    case rainbowBorder = "rainbow-border"
}

struct SlayPrebuildSummary {
    let sequenceCount: Int
    let frameCount: Int
}

private struct SlayRasterSequence {
    let atlas: CGImage
    let frameCount: Int
    let columns: Int
    let rows: Int
}

private struct SlayRasterSequenceMetadata: Codable {
    let frameCount: Int
    let columns: Int
    let rows: Int
}

private extension SlayStageState {
    var cacheIdentifier: String {
        switch self {
        case .running:
            return "running"
        case .idle:
            return "idle"
        case .complete:
            return "complete"
        }
    }
}

private extension SlayStageCacheKey {
    var cacheIdentifier: String {
        [
            "size\(size)",
            "state\(state.cacheIdentifier)",
            "mode\(renderMode.rawValue)",
            "color\(colorKey)",
            "glow\(glowBucket)",
            "counter\(showsCounterArc ? 1 : 0)",
            "secondary\(showsSecondaryOrbit ? 1 : 0)",
            "flash\(flashBucket)",
            "rays\(extraCompletionRays)",
            "orbs\(extraCompletionOrbs)"
        ].joined(separator: "_")
    }
}

private extension SlaySheenCacheKey {
    var cacheIdentifier: String {
        [
            "w\(width)",
            "h\(height)",
            "corner\(cornerRadius)",
            "mode\(renderMode.rawValue)",
            "color\(colorKey)",
            "glow\(glowBucket)"
        ].joined(separator: "_")
    }
}

private extension SlayLEDStripCacheKey {
    var cacheIdentifier: String {
        [
            "w\(width)",
            "h\(height)",
            "corner\(cornerRadius)",
            "color\(colorKey)"
        ].joined(separator: "_")
    }
}

private extension SlayScanSweepCacheKey {
    var cacheIdentifier: String {
        [
            "w\(width)",
            "h\(height)",
            "color\(colorKey)"
        ].joined(separator: "_")
    }
}

private extension SlayRainbowBorderCacheKey {
    var cacheIdentifier: String {
        [
            "w\(width)",
            "h\(height)",
            "corner\(cornerRadius)",
            "intensity\(intensityBucket)"
        ].joined(separator: "_")
    }
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
enum SlaySnapshotCache {
    private static let prebuiltDirectoryName = "FloaterEffectFrames-v1"
    private static var stageFrameCache: [SlayStageCacheKey: SlayRasterSequence] = [:]
    private static var sheenFrameCache: [SlaySheenCacheKey: SlayRasterSequence] = [:]
    private static var ledStripFrameCache: [SlayLEDStripCacheKey: SlayRasterSequence] = [:]
    private static var scanSweepFrameCache: [SlayScanSweepCacheKey: SlayRasterSequence] = [:]
    private static var rainbowBorderFrameCache: [SlayRainbowBorderCacheKey: SlayRasterSequence] = [:]
    private static var missingPrebuiltSequences: Set<String> = []

    fileprivate static func stageFrames(
        state: SlayStageState,
        renderMode: FloaterRenderMode,
        statusColor: Color,
        stageSize: CGFloat,
        effectTuning: FloaterEffectTuning
    ) -> SlayRasterSequence? {
        let cacheKey = stageCacheKey(
            state: state,
            renderMode: renderMode,
            statusColor: statusColor,
            stageSize: stageSize,
            effectTuning: effectTuning
        )

        if let cached = stageFrameCache[cacheKey] {
            return cached
        }

        if let prebuilt = loadPrebuiltSequence(kind: .stage, identifier: cacheKey.cacheIdentifier) {
            stageFrameCache[cacheKey] = prebuilt
            return prebuilt
        }

        guard let frames = makeSequence(from: makeStageFrames(
            state: state,
            renderMode: renderMode,
            statusColor: statusColor,
            stageSize: stageSize,
            effectTuning: effectTuning
        )) else {
            return nil
        }
        stageFrameCache[cacheKey] = frames
        return frames
    }

    fileprivate static func sheenFrames(
        renderMode: FloaterRenderMode,
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize,
        effectTuning: FloaterEffectTuning
    ) -> SlayRasterSequence? {
        let cacheKey = sheenCacheKey(
            renderMode: renderMode,
            color: color,
            cornerRadius: cornerRadius,
            size: size,
            effectTuning: effectTuning
        )

        if let cached = sheenFrameCache[cacheKey] {
            return cached
        }

        if let prebuilt = loadPrebuiltSequence(kind: .sheen, identifier: cacheKey.cacheIdentifier) {
            sheenFrameCache[cacheKey] = prebuilt
            return prebuilt
        }

        guard let frames = makeSequence(from: makeSheenFrames(
            renderMode: renderMode,
            color: color,
            cornerRadius: cornerRadius,
            size: size,
            effectTuning: effectTuning
        )) else {
            return nil
        }
        sheenFrameCache[cacheKey] = frames
        return frames
    }

    fileprivate static func ledStripFrames(
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize
    ) -> SlayRasterSequence? {
        let cacheKey = ledStripCacheKey(color: color, cornerRadius: cornerRadius, size: size)

        if let cached = ledStripFrameCache[cacheKey] {
            return cached
        }

        if let prebuilt = loadPrebuiltSequence(kind: .ledStrip, identifier: cacheKey.cacheIdentifier) {
            ledStripFrameCache[cacheKey] = prebuilt
            return prebuilt
        }

        guard let frames = makeSequence(from: makeLEDStripFrames(color: color, cornerRadius: cornerRadius, size: size)) else {
            return nil
        }
        ledStripFrameCache[cacheKey] = frames
        return frames
    }

    fileprivate static func avatarScanSweepFrames(
        color: Color,
        size: CGSize
    ) -> SlayRasterSequence? {
        let cacheKey = scanSweepCacheKey(color: color, size: size)

        if let cached = scanSweepFrameCache[cacheKey] {
            return cached
        }

        if let prebuilt = loadPrebuiltSequence(kind: .scanSweep, identifier: cacheKey.cacheIdentifier) {
            scanSweepFrameCache[cacheKey] = prebuilt
            return prebuilt
        }

        guard let frames = makeSequence(from: makeScanSweepFrames(color: color, size: size)) else {
            return nil
        }
        scanSweepFrameCache[cacheKey] = frames
        return frames
    }

    fileprivate static func rainbowBorderFrames(
        cornerRadius: CGFloat,
        intensity: Double,
        size: CGSize
    ) -> SlayRasterSequence? {
        let cacheKey = rainbowBorderCacheKey(cornerRadius: cornerRadius, intensity: intensity, size: size)

        if let cached = rainbowBorderFrameCache[cacheKey] {
            return cached
        }

        if let prebuilt = loadPrebuiltSequence(kind: .rainbowBorder, identifier: cacheKey.cacheIdentifier) {
            rainbowBorderFrameCache[cacheKey] = prebuilt
            return prebuilt
        }

        guard let frames = makeSequence(from: makeRainbowBorderFrames(cornerRadius: cornerRadius, intensity: intensity, size: size)) else {
            return nil
        }
        rainbowBorderFrameCache[cacheKey] = frames
        return frames
    }

    static func prebuildBundledAssets(
        settings: FloatifySettings = .shared,
        catalog: FloaterVisualCatalog = .shared
    ) throws -> SlayPrebuildSummary {
        settings.normalizeVisualSelection(catalog: catalog)

        let outputRoot = try prebuildOutputRootURL()
        try FileManager.default.createDirectory(at: outputRoot, withIntermediateDirectories: true)

        let presets = effectPresetsToPrebuild(settings: settings, catalog: catalog)
        let themes = FloaterTheme.allCases
        let stageStates: [SlayStageState] = [.running, .idle, .complete]
        var sequenceCount = 0
        var frameCount = 0

        for floaterSize in FloaterSize.allCases {
            let panelSize = CGSize(width: floaterSize.persistentPanelWidth, height: floaterSize.rowHeight)
            let stageSize = floaterSize.persistentStageSize
            let avatarBackgroundSize = CGSize(width: floaterSize.avatarHitSize, height: floaterSize.avatarHitSize)

            for preset in presets {
                for renderMode in FloaterRenderMode.allCases {
                    for theme in themes {
                        for stageState in stageStates {
                            let statusState = statusState(for: stageState)
                            let color = FloaterPalette.statusColor(for: statusState, theme: theme)
                            let cacheKey = stageCacheKey(
                                state: stageState,
                                renderMode: renderMode,
                                statusColor: color,
                                stageSize: stageSize,
                                effectTuning: preset.tuning
                            )
                            let frames = makeStageFrames(
                                state: stageState,
                                renderMode: renderMode,
                                statusColor: color,
                                stageSize: stageSize,
                                effectTuning: preset.tuning
                            )
                            guard let sequence = makeSequence(from: frames) else { continue }
                            try writePrebuiltSequence(sequence, kind: .stage, identifier: cacheKey.cacheIdentifier, rootURL: outputRoot)
                            sequenceCount += 1
                            frameCount += sequence.frameCount
                        }

                        let runningColor = FloaterPalette.statusColor(for: .running, theme: theme)
                        let sheenKey = sheenCacheKey(
                            renderMode: renderMode,
                            color: runningColor,
                            cornerRadius: floaterSize.cornerRadius,
                            size: panelSize,
                            effectTuning: preset.tuning
                        )
                        let sheenFrames = makeSheenFrames(
                            renderMode: renderMode,
                            color: runningColor,
                            cornerRadius: floaterSize.cornerRadius,
                            size: panelSize,
                            effectTuning: preset.tuning
                        )
                        guard let sheenSequence = makeSequence(from: sheenFrames) else { continue }
                        try writePrebuiltSequence(sheenSequence, kind: .sheen, identifier: sheenKey.cacheIdentifier, rootURL: outputRoot)
                        sequenceCount += 1
                        frameCount += sheenSequence.frameCount
                    }
                }
            }

            for theme in themes {
                let runningColor = FloaterPalette.statusColor(for: .running, theme: theme)
                let ledKey = ledStripCacheKey(color: runningColor, cornerRadius: floaterSize.cornerRadius, size: panelSize)
                let ledFrames = makeLEDStripFrames(color: runningColor, cornerRadius: floaterSize.cornerRadius, size: panelSize)
                guard let ledSequence = makeSequence(from: ledFrames) else { continue }
                try writePrebuiltSequence(ledSequence, kind: .ledStrip, identifier: ledKey.cacheIdentifier, rootURL: outputRoot)
                sequenceCount += 1
                frameCount += ledSequence.frameCount

                let scanKey = scanSweepCacheKey(color: runningColor, size: avatarBackgroundSize)
                let scanFrames = makeScanSweepFrames(color: runningColor, size: avatarBackgroundSize)
                guard let scanSequence = makeSequence(from: scanFrames) else { continue }
                try writePrebuiltSequence(scanSequence, kind: .scanSweep, identifier: scanKey.cacheIdentifier, rootURL: outputRoot)
                sequenceCount += 1
                frameCount += scanSequence.frameCount
            }

            let rainbowKey = rainbowBorderCacheKey(
                cornerRadius: floaterSize.cornerRadius,
                intensity: 0.55,
                size: panelSize
            )
            let rainbowFrames = makeRainbowBorderFrames(
                cornerRadius: floaterSize.cornerRadius,
                intensity: 0.55,
                size: panelSize
            )
            guard let rainbowSequence = makeSequence(from: rainbowFrames) else { continue }
            try writePrebuiltSequence(rainbowSequence, kind: .rainbowBorder, identifier: rainbowKey.cacheIdentifier, rootURL: outputRoot)
            sequenceCount += 1
            frameCount += rainbowSequence.frameCount
        }

        return SlayPrebuildSummary(sequenceCount: sequenceCount, frameCount: frameCount)
    }

    static func prewarmCurrentConfiguration(
        settings: FloatifySettings = .shared,
        catalog: FloaterVisualCatalog = .shared
    ) {
        settings.normalizeVisualSelection(catalog: catalog)

        let preset = catalog.resolvedEffectPreset(
            in: settings.selectedVisualPackID,
            effectPresetID: settings.selectedEffectPresetID
        )
        let floaterSize = settings.floaterSize
        let renderMode = settings.floaterRenderMode
        let panelSize = CGSize(width: floaterSize.persistentPanelWidth, height: floaterSize.rowHeight)
        let avatarBackgroundSize = CGSize(width: floaterSize.avatarHitSize, height: floaterSize.avatarHitSize)
        let theme = settings.floaterTheme

        for state in [ClaudeStatusState.running, .idle, .complete] {
            _ = stageFrames(
                state: stageState(for: state),
                renderMode: renderMode,
                statusColor: FloaterPalette.statusColor(for: state, theme: theme),
                stageSize: floaterSize.persistentStageSize,
                effectTuning: preset.tuning
            )
        }

        let runningColor = FloaterPalette.statusColor(for: .running, theme: theme)
        _ = sheenFrames(
            renderMode: renderMode,
            color: runningColor,
            cornerRadius: floaterSize.cornerRadius,
            size: panelSize,
            effectTuning: preset.tuning
        )
        _ = ledStripFrames(color: runningColor, cornerRadius: floaterSize.cornerRadius, size: panelSize)
        _ = avatarScanSweepFrames(color: runningColor, size: avatarBackgroundSize)

        if renderMode == .superSlay {
            _ = rainbowBorderFrames(cornerRadius: floaterSize.cornerRadius, intensity: 0.55, size: panelSize)
        }
    }

    private static func stageCacheKey(
        state: SlayStageState,
        renderMode: FloaterRenderMode,
        statusColor: Color,
        stageSize: CGFloat,
        effectTuning: FloaterEffectTuning
    ) -> SlayStageCacheKey {
        let showsCounterArc = effectTuning.showsCounterArc ?? (renderMode == .superSlay)
        let showsSecondaryOrbit = effectTuning.showsSecondaryOrbit ?? (renderMode == .superSlay)
        return SlayStageCacheKey(
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
    }

    private static func sheenCacheKey(
        renderMode: FloaterRenderMode,
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize,
        effectTuning: FloaterEffectTuning
    ) -> SlaySheenCacheKey {
        SlaySheenCacheKey(
            width: Int(size.width.rounded(.toNearestOrAwayFromZero)),
            height: Int(size.height.rounded(.toNearestOrAwayFromZero)),
            cornerRadius: Int(cornerRadius.rounded(.toNearestOrAwayFromZero)),
            renderMode: renderMode,
            colorKey: NSColor(color).floaterCacheKey,
            glowBucket: Int((max(effectTuning.glowMultiplier, 0.2) * 100).rounded())
        )
    }

    private static func ledStripCacheKey(
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize
    ) -> SlayLEDStripCacheKey {
        SlayLEDStripCacheKey(
            width: Int(size.width.rounded(.toNearestOrAwayFromZero)),
            height: Int(size.height.rounded(.toNearestOrAwayFromZero)),
            cornerRadius: Int(cornerRadius.rounded(.toNearestOrAwayFromZero)),
            colorKey: NSColor(color).floaterCacheKey
        )
    }

    private static func scanSweepCacheKey(
        color: Color,
        size: CGSize
    ) -> SlayScanSweepCacheKey {
        SlayScanSweepCacheKey(
            width: Int(size.width.rounded(.toNearestOrAwayFromZero)),
            height: Int(size.height.rounded(.toNearestOrAwayFromZero)),
            colorKey: NSColor(color).floaterCacheKey
        )
    }

    private static func rainbowBorderCacheKey(
        cornerRadius: CGFloat,
        intensity: Double,
        size: CGSize
    ) -> SlayRainbowBorderCacheKey {
        SlayRainbowBorderCacheKey(
            width: Int(size.width.rounded(.toNearestOrAwayFromZero)),
            height: Int(size.height.rounded(.toNearestOrAwayFromZero)),
            cornerRadius: Int(cornerRadius.rounded(.toNearestOrAwayFromZero)),
            intensityBucket: Int((intensity * 100).rounded())
        )
    }

    private static func makeStageFrames(
        state: SlayStageState,
        renderMode: FloaterRenderMode,
        statusColor: Color,
        stageSize: CGFloat,
        effectTuning: FloaterEffectTuning
    ) -> [CGImage] {
        let frameCount: Int
        switch (renderMode, state) {
        case (.superSlay, .running):
            frameCount = 16
        case (.superSlay, .idle):
            frameCount = 8
        case (.superSlay, .complete):
            frameCount = 12
        case (.slay, .running):
            frameCount = 8
        case (.slay, .idle):
            frameCount = 6
        case (.slay, .complete):
            frameCount = 10
        case (_, .running):
            frameCount = 6
        case (_, .idle):
            frameCount = 4
        case (_, .complete):
            frameCount = 8
        }

        return (0..<frameCount).compactMap { index in
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
    }

    private static func makeSheenFrames(
        renderMode: FloaterRenderMode,
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize,
        effectTuning: FloaterEffectTuning
    ) -> [CGImage] {
        let frameCount = renderMode == .superSlay ? 16 : 6
        return (0..<frameCount).compactMap { index in
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
    }

    private static func makeLEDStripFrames(
        color: Color,
        cornerRadius: CGFloat,
        size: CGSize
    ) -> [CGImage] {
        let frameCount = 8
        return (0..<frameCount).compactMap { index in
            let progress = CGFloat(index) / CGFloat(max(frameCount - 1, 1))
            return renderImage(size: size) {
                SlayLEDStripSnapshotContent(
                    color: color,
                    cornerRadius: cornerRadius,
                    size: size,
                    progress: progress
                )
            }
        }
    }

    private static func makeScanSweepFrames(
        color: Color,
        size: CGSize
    ) -> [CGImage] {
        let frameCount = 8
        return (0..<frameCount).compactMap { index in
            let progress = CGFloat(index) / CGFloat(max(frameCount - 1, 1))
            return renderImage(size: size) {
                SlayAvatarScanSweepSnapshotContent(
                    color: color,
                    size: size,
                    progress: progress
                )
            }
        }
    }

    private static func makeRainbowBorderFrames(
        cornerRadius: CGFloat,
        intensity: Double,
        size: CGSize
    ) -> [CGImage] {
        let frameCount = 12
        return (0..<frameCount).compactMap { index in
            let progress = CGFloat(index) / CGFloat(max(frameCount - 1, 1))
            return renderImage(size: size) {
                SlayRainbowBorderSnapshotContent(
                    cornerRadius: cornerRadius,
                    intensity: intensity,
                    size: size,
                    progress: progress
                )
            }
        }
    }

    private static func statusState(for stageState: SlayStageState) -> ClaudeStatusState {
        switch stageState {
        case .running:
            return .running
        case .idle:
            return .idle
        case .complete:
            return .complete
        }
    }

    private static func stageState(for statusState: ClaudeStatusState) -> SlayStageState {
        switch statusState {
        case .running:
            return .running
        case .idle:
            return .idle
        case .complete:
            return .complete
        }
    }

    private static func effectPresetsToPrebuild(
        settings: FloatifySettings,
        catalog: FloaterVisualCatalog
    ) -> [FloaterEffectPreset] {
        let selectedPreset = catalog.resolvedEffectPreset(
            in: settings.selectedVisualPackID,
            effectPresetID: settings.selectedEffectPresetID
        )

        var results: [FloaterEffectPreset] = []
        var seen: Set<String> = []

        for preset in FloaterEffectPreset.builtInPresets + [selectedPreset] {
            let signature = effectPresetSignature(preset)
            if seen.insert(signature).inserted {
                results.append(preset)
            }
        }

        return results
    }

    private static func effectPresetSignature(_ preset: FloaterEffectPreset) -> String {
        let tuning = preset.tuning
        return [
            preset.id,
            "sheen\(tuning.showsSheen.map { $0 ? 1 : 0 } ?? -1)",
            "trail\(tuning.showsParticleTrail.map { $0 ? 1 : 0 } ?? -1)",
            "counter\(tuning.showsCounterArc.map { $0 ? 1 : 0 } ?? -1)",
            "secondary\(tuning.showsSecondaryOrbit.map { $0 ? 1 : 0 } ?? -1)",
            "glow\(Int((tuning.glowMultiplier * 100).rounded()))",
            "sheenDur\(Int((tuning.sheenDurationMultiplier * 100).rounded()))",
            "orbitDur\(Int((tuning.orbitDurationMultiplier * 100).rounded()))",
            "arcDur\(Int((tuning.arcDurationMultiplier * 100).rounded()))",
            "pulseDur\(Int((tuning.pulseDurationMultiplier * 100).rounded()))",
            "statusPulse\(Int((tuning.statusPulseDurationMultiplier * 100).rounded()))",
            "completeDur\(Int((tuning.completionDurationMultiplier * 100).rounded()))",
            "flash\(Int((tuning.flashIntensityMultiplier * 100).rounded()))",
            "rays\(tuning.extraCompletionRays)",
            "orbs\(tuning.extraCompletionOrbs)"
        ].joined(separator: "_")
    }

    private static func loadPrebuiltSequence(
        kind: SlayPrebuiltSequenceKind,
        identifier: String
    ) -> SlayRasterSequence? {
        let sequenceKey = "\(kind.rawValue):\(identifier)"
        if missingPrebuiltSequences.contains(sequenceKey) {
            return nil
        }

        guard let rootURL = bundledPrebuiltRootURL() else {
            missingPrebuiltSequences.insert(sequenceKey)
            return nil
        }

        let directoryURL = sequenceDirectoryURL(kind: kind, identifier: identifier, rootURL: rootURL)
        let atlasURL = directoryURL.appendingPathComponent("atlas.png")
        let metadataURL = directoryURL.appendingPathComponent("metadata.json")

        guard let atlas = loadCGImage(from: atlasURL),
              let metadataData = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode(SlayRasterSequenceMetadata.self, from: metadataData),
              metadata.frameCount > 0,
              metadata.columns > 0,
              metadata.rows > 0 else {
            missingPrebuiltSequences.insert(sequenceKey)
            return nil
        }

        return SlayRasterSequence(
            atlas: atlas,
            frameCount: metadata.frameCount,
            columns: metadata.columns,
            rows: metadata.rows
        )
    }

    private static func prebuildOutputRootURL() throws -> URL {
        if let path = ProcessInfo.processInfo.environment["FLOATIFY_PREBUILD_OUTPUT_DIR"], !path.isEmpty {
            return URL(fileURLWithPath: path, isDirectory: true)
        }

        guard let url = bundledPrebuiltRootURL() else {
            throw NSError(domain: "FloatifyPrebuild", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Missing bundle resource URL for prebuilt effect output."
            ])
        }

        return url
    }

    private static func bundledPrebuiltRootURL() -> URL? {
        Bundle.main.resourceURL?.appendingPathComponent(prebuiltDirectoryName, isDirectory: true)
    }

    private static func sequenceDirectoryURL(
        kind: SlayPrebuiltSequenceKind,
        identifier: String,
        rootURL: URL
    ) -> URL {
        rootURL
            .appendingPathComponent(kind.rawValue, isDirectory: true)
            .appendingPathComponent(identifier, isDirectory: true)
    }

    private static func writePrebuiltSequence(
        _ sequence: SlayRasterSequence,
        kind: SlayPrebuiltSequenceKind,
        identifier: String,
        rootURL: URL
    ) throws {
        let directoryURL = sequenceDirectoryURL(kind: kind, identifier: identifier, rootURL: rootURL)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try writePNG(sequence.atlas, to: directoryURL.appendingPathComponent("atlas.png"))
        let metadata = SlayRasterSequenceMetadata(
            frameCount: sequence.frameCount,
            columns: sequence.columns,
            rows: sequence.rows
        )
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: directoryURL.appendingPathComponent("metadata.json"), options: .atomic)
    }

    private static func loadCGImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw NSError(domain: "FloatifyPrebuild", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create PNG writer for \(url.path)."
            ])
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw NSError(domain: "FloatifyPrebuild", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Failed to write PNG frame at \(url.path)."
            ])
        }
    }

    private static func makeSequence(from frames: [CGImage]) -> SlayRasterSequence? {
        guard let first = frames.first else { return nil }

        let frameCount = frames.count
        let columns = min(max(Int(ceil(sqrt(Double(frameCount)))), 1), frameCount)
        let rows = Int(ceil(Double(frameCount) / Double(columns)))
        let atlasWidth = first.width * columns
        let atlasHeight = first.height * rows

        guard let context = CGContext(
            data: nil,
            width: atlasWidth,
            height: atlasHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.interpolationQuality = .none

        for (index, frame) in frames.enumerated() {
            let column = index % columns
            let row = index / columns
            let rect = CGRect(
                x: column * first.width,
                y: row * first.height,
                width: first.width,
                height: first.height
            )
            context.draw(frame, in: rect)
        }

        guard let atlas = context.makeImage() else { return nil }
        return SlayRasterSequence(atlas: atlas, frameCount: frameCount, columns: columns, rows: rows)
    }

    private static func renderImage<Content: View>(size: CGSize, @ViewBuilder content: () -> Content) -> CGImage? {
        let renderer = ImageRenderer(content: content().frame(width: size.width, height: size.height))
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = max(NSScreen.main?.backingScaleFactor ?? 2, 2)
        renderer.isOpaque = false
        return renderer.cgImage
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

    private var idlePulse: CGFloat {
        0.5 - 0.5 * cos(progress * .pi * 2)
    }

    private var completeBurstProgress: CGFloat {
        min(max(progress, 0), 1)
    }

    private var completeBurstEnvelope: CGFloat {
        sin(completeBurstProgress * .pi)
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
        scaledOpacity((isSuperSlay ? 0.20 : 0.16) * Double(completeBurstEnvelope))
    }

    private var completionCoreOpacity: Double {
        scaledOpacity((isSuperSlay ? 0.26 : 0.20) * Double(completeBurstEnvelope))
    }

    private var completionRayOpacity: Double {
        scaledOpacity((isSuperSlay ? 0.94 : 0.68) * Double(completeBurstEnvelope))
    }

    private var completionOrbitOpacity: Double {
        scaledOpacity((isSuperSlay ? 0.88 : 0.56) * Double(completeBurstEnvelope))
    }

    private var completionShockwaveScale: CGFloat {
        0.88 + (isSuperSlay ? 1.10 : 0.76) * completeBurstEnvelope
    }

    private var completionShockwaveOpacity: Double {
        scaledOpacity((isSuperSlay ? 0.62 : 0.44) * Double(completeBurstEnvelope))
    }

    private var completionNovaScale: CGFloat {
        0.90 + (isSuperSlay ? 0.36 : 0.24) * completeBurstEnvelope
    }

    private var completionOuterShockwaveScale: CGFloat {
        0.94 + (isSuperSlay ? 1.62 : 1.12) * completeBurstEnvelope
    }

    private var completionOuterShockwaveOpacity: Double {
        scaledOpacity((isSuperSlay ? 0.38 : 0.28) * Double(completeBurstEnvelope))
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            color.opacity(scaledOpacity(stageCoreOpacity)),
                            color.opacity(scaledOpacity(stageMidOpacity)),
                            FloaterPalette.panelShadow.opacity(stageShadowOpacity),
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

    private var stageCoreOpacity: Double {
        switch state {
        case .running:
            return isSuperSlay ? 0.56 : 0.48
        case .idle:
            return isSuperSlay ? 0.46 : 0.40
        case .complete:
            return isSuperSlay ? 0.42 : 0.36
        }
    }

    private var stageMidOpacity: Double {
        switch state {
        case .running:
            return isSuperSlay ? 0.34 : 0.28
        case .idle:
            return isSuperSlay ? 0.28 : 0.22
        case .complete:
            return isSuperSlay ? 0.24 : 0.20
        }
    }

    private var stageShadowOpacity: Double {
        switch state {
        case .running:
            return 0.18
        case .idle:
            return 0.14
        case .complete:
            return 0.12
        }
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

            ForEach(0..<(isSuperSlay ? 3 : 2), id: \.self) { index in
                let orbitScale = isSuperSlay ? CGFloat(0.09 + Double(index) * 0.016) : CGFloat(0.08 + Double(index) * 0.014)
                let orbitOpacity = isSuperSlay ? 0.46 - Double(index) * 0.08 : 0.34 - Double(index) * 0.07
                let orbitRadius = stageSize * (isSuperSlay ? 0.25 + Double(index) * 0.06 : 0.22 + Double(index) * 0.05)
                let orbitAngle = Double(index) * (isSuperSlay ? 120 : 180) + runningOrbitAngle * (0.54 + Double(index) * 0.17)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.94),
                                color.opacity(scaledOpacity(orbitOpacity)),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: stageSize * orbitScale
                        )
                    )
                    .frame(width: stageSize * orbitScale * 2.1, height: stageSize * orbitScale * 2.1)
                    .shadow(color: color.opacity(scaledOpacity(orbitOpacity * 0.58)), radius: scaledRadius(isSuperSlay ? 3.6 : 2.4), x: 0, y: 0)
                    .offset(y: -orbitRadius)
                    .rotationEffect(.degrees(orbitAngle))
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
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.18 + Double(idlePulse) * 0.30),
                            color.opacity(scaledOpacity(0.20 + 0.26 * Double(idlePulse))),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize * 0.34
                    )
                )
                .frame(width: stageSize * (0.76 + idlePulse * 0.28), height: stageSize * (0.76 + idlePulse * 0.28))
                .blur(radius: scaledRadius(2.4 + idlePulse * 2.2))

            Circle()
                .trim(from: 0.12, to: 0.34)
                .stroke(color.opacity(scaledOpacity(0.52 + 0.22 * Double(idlePulse))), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .frame(width: stageSize * 1.06, height: stageSize * 1.06)
                .rotationEffect(.degrees(-28))

            Circle()
                .fill(color.opacity(0.82))
                .frame(width: stageSize * 0.13, height: stageSize * 0.13)
                .shadow(color: color.opacity(scaledOpacity(0.20)), radius: scaledRadius(2.2), x: 0, y: 0)
                .offset(x: stageSize * 0.22, y: -stageSize * 0.18)

            Circle()
                .strokeBorder(.white.opacity(0.18 + Double(idlePulse) * 0.28), lineWidth: 1.4)
                .frame(width: stageSize * (0.52 + idlePulse * 0.24), height: stageSize * (0.52 + idlePulse * 0.24))
                .blur(radius: 0.4)

            Circle()
                .strokeBorder(color.opacity(scaledOpacity(0.16 + 0.18 * Double(idlePulse))), lineWidth: 2.0)
                .frame(width: stageSize * (0.70 + idlePulse * 0.24), height: stageSize * (0.70 + idlePulse * 0.24))
                .blur(radius: scaledRadius(0.8 + idlePulse * 0.9))
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
                .frame(width: stageSize * (0.52 + completeBurstEnvelope * (isSuperSlay ? 1.20 : 0.66)), height: stageSize * (0.52 + completeBurstEnvelope * (isSuperSlay ? 1.20 : 0.66)))
                .blur(radius: isSuperSlay ? 10 : 7)

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
                .frame(width: stageSize * completionNovaScale, height: stageSize * completionNovaScale)
                .blur(radius: isSuperSlay ? 4.0 : 2.8)

            Circle()
                .strokeBorder(.white.opacity(completionShockwaveOpacity), lineWidth: isSuperSlay ? 2.2 : 1.5)
                .frame(width: stageSize * completionShockwaveScale, height: stageSize * completionShockwaveScale)
                .blur(radius: 0.8)

            Circle()
                .strokeBorder(color.opacity(completionOuterShockwaveOpacity), lineWidth: isSuperSlay ? 2.8 : 2.0)
                .frame(width: stageSize * completionOuterShockwaveScale, height: stageSize * completionOuterShockwaveScale)
                .blur(radius: 1.2)

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
                        width: index.isMultiple(of: 3) ? 4.0 : 2.6,
                        height: stageSize * (0.18 + completeBurstEnvelope * (index.isMultiple(of: 2) ? 0.50 : 0.40))
                    )
                    .offset(y: -(stageSize * (0.18 + completeBurstEnvelope * 0.30)))
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(completionRayCount)) + 34))
                    .opacity(completionRayOpacity)
                    .blur(radius: index.isMultiple(of: 4) ? 0.8 : 0.2)
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
                    .offset(y: -(stageSize * (0.22 + completeBurstEnvelope * 0.30)))
                    .rotationEffect(.degrees(Double(index) * (360.0 / Double(completionOrbitCount)) + 112 + completeBurstEnvelope * (isSuperSlay ? 152 : 96)))
                    .opacity(completionOrbitOpacity)
                    .shadow(color: color.opacity(scaledOpacity(completionOrbitOpacity * 0.52)), radius: scaledRadius(5), x: 0, y: 0)
                    .blendMode(.screen)
            }

            Circle()
                .strokeBorder(color.opacity(0.76), lineWidth: 1.4)
                .frame(width: stageSize * (isSuperSlay ? 0.72 : 0.68), height: stageSize * (isSuperSlay ? 0.72 : 0.68))
                .opacity(0.18)
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

private struct SlayLEDStripSnapshotContent: View {
    let color: Color
    let cornerRadius: CGFloat
    let size: CGSize
    let progress: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack {
                Rectangle()
                    .fill(color.opacity(0.42))
                    .frame(height: 5)
                    .blur(radius: 3)
                    .opacity(0.7)

                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: color.opacity(0.30), location: 0.0),
                                .init(color: color.opacity(0.55), location: max(0, progress - 0.18)),
                                .init(color: .white.opacity(0.95), location: progress),
                                .init(color: color.opacity(0.55), location: min(1, progress + 0.18)),
                                .init(color: color.opacity(0.30), location: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 2)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct SlayAvatarScanSweepSnapshotContent: View {
    let color: Color
    let size: CGSize
    let progress: CGFloat

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: max(0.0, progress - 0.20)),
                .init(color: color.opacity(0.55), location: max(0.0, progress - 0.01)),
                .init(color: .white.opacity(0.70), location: progress),
                .init(color: color.opacity(0.45), location: min(1.0, progress + 0.02)),
                .init(color: .clear, location: min(1.0, progress + 0.22)),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .blendMode(.screen)
        .frame(width: size.width, height: size.height)
    }
}

private struct SlayRainbowBorderSnapshotContent: View {
    let cornerRadius: CGFloat
    let intensity: Double
    let size: CGSize
    let progress: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .strokeBorder(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(hue: 0.00, saturation: 0.95, brightness: 1.0),
                        Color(hue: 0.13, saturation: 0.95, brightness: 1.0),
                        Color(hue: 0.30, saturation: 0.95, brightness: 1.0),
                        Color(hue: 0.50, saturation: 0.95, brightness: 1.0),
                        Color(hue: 0.70, saturation: 0.95, brightness: 1.0),
                        Color(hue: 0.85, saturation: 0.95, brightness: 1.0),
                        Color(hue: 1.00, saturation: 0.95, brightness: 1.0)
                    ]),
                    center: .center,
                    angle: .degrees(progress * 360.0)
                ),
                lineWidth: 1.2
            )
            .opacity(intensity)
            .blendMode(.screen)
            .frame(width: size.width, height: size.height)
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

private func rasterSequenceRects(for sequence: SlayRasterSequence) -> [CGRect] {
    let width = 1.0 / CGFloat(sequence.columns)
    let height = 1.0 / CGFloat(sequence.rows)

    return (0..<sequence.frameCount).map { index in
        let column = index % sequence.columns
        let row = index / sequence.columns
        return CGRect(
            x: CGFloat(column) * width,
            y: CGFloat(row) * height,
            width: width,
            height: height
        )
    }
}

private func rasterSequence(from images: [NSImage]) -> SlayRasterSequence? {
    let frames = images.compactMap { $0.floaterCGImage() }
    guard !frames.isEmpty else { return nil }

    let frameCount = frames.count
    let columns = min(max(Int(ceil(sqrt(Double(frameCount)))), 1), frameCount)
    let rows = Int(ceil(Double(frameCount) / Double(columns)))
    let first = frames[0]
    let atlasWidth = first.width * columns
    let atlasHeight = first.height * rows

    guard let context = CGContext(
        data: nil,
        width: atlasWidth,
        height: atlasHeight,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }

    context.interpolationQuality = .none

    for (index, frame) in frames.enumerated() {
        let column = index % columns
        let row = index / columns
        context.draw(
            frame,
            in: CGRect(
                x: column * first.width,
                y: row * first.height,
                width: first.width,
                height: first.height
            )
        )
    }

    guard let atlas = context.makeImage() else { return nil }
    return SlayRasterSequence(atlas: atlas, frameCount: frameCount, columns: columns, rows: rows)
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
        sequenceLayer.actions = ["contents": NSNull(), "contentsRect": NSNull(), "bounds": NSNull(), "position": NSNull()]
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
        sequence: SlayRasterSequence?,
        frameDuration: CFTimeInterval,
        signature: String,
        cornerRadius: CGFloat
    ) {
        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = true
        sequenceLayer.cornerRadius = cornerRadius
        sequenceLayer.masksToBounds = true

        guard let sequence else {
            sequenceLayer.removeAnimation(forKey: "sequence")
            sequenceLayer.contents = nil
            sequenceLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            currentSignature = signature
            return
        }

        guard currentSignature != signature else { return }
        currentSignature = signature

        sequenceLayer.removeAnimation(forKey: "sequence")
        sequenceLayer.contents = sequence.atlas
        let frameRects = rasterSequenceRects(for: sequence)
        sequenceLayer.contentsRect = frameRects.first ?? CGRect(x: 0, y: 0, width: 1, height: 1)

        guard sequence.frameCount > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contentsRect")
        animation.values = frameRects.map { NSValue(rect: $0) }
        animation.keyTimes = (0..<sequence.frameCount).map { NSNumber(value: Double($0) / Double(max(sequence.frameCount - 1, 1))) }
        animation.duration = frameDuration * Double(sequence.frameCount)
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
    private var currentAvatarEffectSignature = ""
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
        stageLayer.actions = ["contents": NSNull(), "contentsRect": NSNull(), "bounds": NSNull(), "position": NSNull()]
        avatarLayer.contentsGravity = .resizeAspect
        avatarLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        avatarLayer.actions = ["contents": NSNull(), "contentsRect": NSNull(), "bounds": NSNull(), "position": NSNull()]
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
        stageSequence: SlayRasterSequence?,
        stageFrameDuration: CFTimeInterval,
        stageRepeats: Bool,
        stageSignature: String,
        avatarFrames: [NSImage],
        avatarFrameDuration: CFTimeInterval,
        avatarSignature: String,
        avatarState: SlayStageState,
        avatarEffectSignature: String,
        avatarSize: CGFloat
    ) {
        currentAvatarSize = avatarSize
        needsLayout = true

        updateStageSequence(sequence: stageSequence, frameDuration: stageFrameDuration, repeats: stageRepeats, signature: stageSignature)
        updateAvatarSequence(frames: avatarFrames, frameDuration: avatarFrameDuration, signature: avatarSignature)
        updateAvatarEffects(state: avatarState, signature: avatarEffectSignature)
    }

    private func updateStageSequence(
        sequence: SlayRasterSequence?,
        frameDuration: CFTimeInterval,
        repeats: Bool,
        signature: String
    ) {
        guard let sequence else {
            stageLayer.removeAnimation(forKey: "sequence")
            stageLayer.contents = nil
            stageLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            currentStageSignature = signature
            return
        }

        guard currentStageSignature != signature else { return }
        currentStageSignature = signature

        stageLayer.removeAnimation(forKey: "sequence")
        stageLayer.contents = sequence.atlas
        let frameRects = rasterSequenceRects(for: sequence)
        stageLayer.contentsRect = frameRects.first ?? CGRect(x: 0, y: 0, width: 1, height: 1)

        guard sequence.frameCount > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contentsRect")
        animation.values = frameRects.map { NSValue(rect: $0) }
        animation.keyTimes = (0..<sequence.frameCount).map { NSNumber(value: Double($0) / Double(max(sequence.frameCount - 1, 1))) }
        animation.duration = frameDuration * Double(sequence.frameCount)
        animation.repeatCount = repeats ? .infinity : 0
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

        guard let sequence = rasterSequence(from: frames) else {
            avatarLayer.removeAnimation(forKey: "sequence")
            avatarLayer.contents = nil
            avatarLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            return
        }

        avatarLayer.removeAnimation(forKey: "sequence")
        avatarLayer.contents = sequence.atlas
        let frameRects = rasterSequenceRects(for: sequence)
        avatarLayer.contentsRect = frameRects.first ?? CGRect(x: 0, y: 0, width: 1, height: 1)

        guard sequence.frameCount > 1 else { return }

        let animation = CAKeyframeAnimation(keyPath: "contentsRect")
        animation.values = frameRects.map { NSValue(rect: $0) }
        animation.keyTimes = (0..<sequence.frameCount).map { NSNumber(value: Double($0) / Double(max(sequence.frameCount - 1, 1))) }
        animation.duration = frameDuration * Double(sequence.frameCount)
        animation.repeatCount = .infinity
        animation.calculationMode = .discrete
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        avatarLayer.add(animation, forKey: "sequence")
    }

    private func updateAvatarEffects(
        state: SlayStageState,
        signature: String
    ) {
        guard currentAvatarEffectSignature != signature else { return }
        currentAvatarEffectSignature = signature

        avatarLayer.removeAnimation(forKey: "idleFlashOpacity")
        avatarLayer.removeAnimation(forKey: "idleFlashScale")
        avatarLayer.removeAnimation(forKey: "completeFlashOpacity")
        avatarLayer.removeAnimation(forKey: "completeKickScale")
        avatarLayer.removeAnimation(forKey: "completeKickRotation")
        avatarLayer.removeAnimation(forKey: "completeKickLift")
        avatarLayer.opacity = 1
        avatarLayer.transform = CATransform3DIdentity

        if state == .idle {
            let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnimation.values = [1.0, 0.52, 1.0]
            opacityAnimation.keyTimes = [0.0, 0.42, 1.0]
            opacityAnimation.duration = 0.5
            opacityAnimation.repeatCount = .infinity
            opacityAnimation.isRemovedOnCompletion = false
            opacityAnimation.fillMode = .forwards
            avatarLayer.add(opacityAnimation, forKey: "idleFlashOpacity")

            let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
            scaleAnimation.values = [1.0, 1.14, 1.0]
            scaleAnimation.keyTimes = [0.0, 0.38, 1.0]
            scaleAnimation.duration = 0.5
            scaleAnimation.repeatCount = .infinity
            scaleAnimation.isRemovedOnCompletion = false
            scaleAnimation.fillMode = .forwards
            avatarLayer.add(scaleAnimation, forKey: "idleFlashScale")
            return
        }

        guard state == .complete else { return }

        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [1.0, 0.58, 1.0]
        opacityAnimation.keyTimes = [0.0, 0.35, 1.0]
        opacityAnimation.duration = 0.34
        opacityAnimation.isRemovedOnCompletion = true
        avatarLayer.add(opacityAnimation, forKey: "completeFlashOpacity")

        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.20, 0.98, 1.0]
        scaleAnimation.keyTimes = [0.0, 0.28, 0.72, 1.0]
        scaleAnimation.duration = 0.34
        scaleAnimation.isRemovedOnCompletion = true
        avatarLayer.add(scaleAnimation, forKey: "completeKickScale")

        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.values = [0.0, -0.14, 0.10, 0.0]
        rotationAnimation.keyTimes = [0.0, 0.30, 0.62, 1.0]
        rotationAnimation.duration = 0.32
        rotationAnimation.isRemovedOnCompletion = true
        avatarLayer.add(rotationAnimation, forKey: "completeKickRotation")

        let liftAnimation = CAKeyframeAnimation(keyPath: "transform.translation.y")
        liftAnimation.values = [0.0, -4.0, -1.0, 0.0]
        liftAnimation.keyTimes = [0.0, 0.28, 0.70, 1.0]
        liftAnimation.duration = 0.30
        liftAnimation.isRemovedOnCompletion = true
        avatarLayer.add(liftAnimation, forKey: "completeKickLift")
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
        let totalDuration = renderMode == .superSlay
            ? min(max(1.2, 1.2 * effectTuning.sheenDurationMultiplier), 1.5)
            : max(1.2, 1.8 * effectTuning.sheenDurationMultiplier)
        nsView.update(
            sequence: frames,
            frameDuration: totalDuration / Double(max(frames?.frameCount ?? 1, 1)),
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
    let completeTrigger: UUID?
    let avatarPulseTrigger: UUID?

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
        let stageFrameDuration: CFTimeInterval
        let stageRepeats: Bool
        switch state {
        case .running:
            let cycleDuration = renderMode == .superSlay
                ? min(max(1.2, 1.92 * max(effectTuning.orbitDurationMultiplier, effectTuning.arcDurationMultiplier)), 2.2)
                : max(1.4, 3.96 * max(effectTuning.orbitDurationMultiplier, effectTuning.arcDurationMultiplier))
            stageFrameDuration = cycleDuration / Double(max(stageFrames?.frameCount ?? 1, 1))
            stageRepeats = true
        case .idle:
            let cycleDuration = renderMode == .superSlay ? 0.50 : 0.50
            stageFrameDuration = cycleDuration / Double(max(stageFrames?.frameCount ?? 1, 1))
            stageRepeats = true
        case .complete:
            let cycleDuration = renderMode == .superSlay ? 0.86 : 0.70
            stageFrameDuration = cycleDuration / Double(max(stageFrames?.frameCount ?? 1, 1))
            stageRepeats = false
        }
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
            "\(effectTuning.extraCompletionOrbs)",
            state == .complete ? (completeTrigger?.uuidString ?? "complete") : "steady"
        ].joined(separator: ":")
        let avatarSignature = [
            avatar?.id ?? "none",
            shouldAnimateAvatar ? "animated" : "static",
            "\(Int(spriteSize.rounded(.toNearestOrAwayFromZero)))"
        ].joined(separator: ":")
        let avatarEffectSignature = [
            state == .running ? "running" : (state == .complete ? "complete" : "idle"),
            renderMode.rawValue,
            state == .complete ? (avatarPulseTrigger?.uuidString ?? completeTrigger?.uuidString ?? "complete") : "steady"
        ].joined(separator: ":")
        let avatarPayload = shouldAnimateAvatar ? avatarFrames : Array(avatarFrames.prefix(1))

        nsView.update(
            stageSequence: stageFrames,
            stageFrameDuration: stageFrameDuration,
            stageRepeats: stageRepeats,
            stageSignature: stageSignature,
            avatarFrames: avatarPayload,
            avatarFrameDuration: avatarFrameDuration(for: avatar),
            avatarSignature: avatarSignature,
            avatarState: state,
            avatarEffectSignature: avatarEffectSignature,
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

private struct SlayPowerLEDStripRepresentable: NSViewRepresentable {
    let size: CGSize
    let color: Color
    let cornerRadius: CGFloat

    func makeNSView(context: Context) -> SlayImageSequenceRendererView {
        SlayImageSequenceRendererView(frame: CGRect(origin: .zero, size: size))
    }

    func updateNSView(_ nsView: SlayImageSequenceRendererView, context: Context) {
        let frames = SlaySnapshotCache.ledStripFrames(
            color: color,
            cornerRadius: cornerRadius,
            size: size
        )
        let signature = [
            "led-strip",
            "\(Int(size.width.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(size.height.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(cornerRadius.rounded(.toNearestOrAwayFromZero)))",
            NSColor(color).floaterCacheKey
        ].joined(separator: ":")
        nsView.update(
            sequence: frames,
            frameDuration: 2.6 / Double(max(frames?.frameCount ?? 1, 1)),
            signature: signature,
            cornerRadius: cornerRadius
        )
    }
}

private struct SlayAvatarScanSweepRepresentable: NSViewRepresentable {
    let size: CGSize
    let color: Color

    func makeNSView(context: Context) -> SlayImageSequenceRendererView {
        SlayImageSequenceRendererView(frame: CGRect(origin: .zero, size: size))
    }

    func updateNSView(_ nsView: SlayImageSequenceRendererView, context: Context) {
        let frames = SlaySnapshotCache.avatarScanSweepFrames(
            color: color,
            size: size
        )
        let signature = [
            "avatar-scan",
            "\(Int(size.width.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(size.height.rounded(.toNearestOrAwayFromZero)))",
            NSColor(color).floaterCacheKey
        ].joined(separator: ":")
        nsView.update(
            sequence: frames,
            frameDuration: 2.2 / Double(max(frames?.frameCount ?? 1, 1)),
            signature: signature,
            cornerRadius: 0
        )
    }
}

private struct SlayRainbowBorderRepresentable: NSViewRepresentable {
    let size: CGSize
    let cornerRadius: CGFloat
    let intensity: Double

    func makeNSView(context: Context) -> SlayImageSequenceRendererView {
        SlayImageSequenceRendererView(frame: CGRect(origin: .zero, size: size))
    }

    func updateNSView(_ nsView: SlayImageSequenceRendererView, context: Context) {
        let frames = SlaySnapshotCache.rainbowBorderFrames(
            cornerRadius: cornerRadius,
            intensity: intensity,
            size: size
        )
        let signature = [
            "rainbow-border",
            "\(Int(size.width.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(size.height.rounded(.toNearestOrAwayFromZero)))",
            "\(Int(cornerRadius.rounded(.toNearestOrAwayFromZero)))",
            "\(Int((intensity * 100).rounded()))"
        ].joined(separator: ":")
        nsView.update(
            sequence: frames,
            frameDuration: 4.0 / Double(max(frames?.frameCount ?? 1, 1)),
            signature: signature,
            cornerRadius: cornerRadius
        )
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

    @State private var idleSparkleTrigger: UUID?
    @State private var doneSparkleTrigger: UUID?
    @State private var doneAvatarTrigger: UUID?

    private var idleSparkleInterval: TimeInterval {
        renderMode == .superSlay ? 2.4 : 6.4
    }

    private var completeAvatarInterval: TimeInterval {
        renderMode == .superSlay ? 4.8 : 16.0
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
                isComplete: isComplete,
                completeTrigger: completeTrigger,
                avatarPulseTrigger: doneAvatarTrigger
            )

            if isIdle {
                IdleSparkleBurst(trigger: idleSparkleTrigger)
            }

            if isComplete {
                CelebrateRingBurst(color: statusColor, stageSize: stageSize, trigger: doneSparkleTrigger)
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
                doneAvatarTrigger = UUID()
            }
        }
        .task(id: "idle-\(isIdle)-\(renderMode.rawValue)") {
            guard isIdle else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(idleSparkleInterval * 1_000_000_000))
                guard !Task.isCancelled, isIdle else { break }
                await MainActor.run {
                    idleSparkleTrigger = UUID()
                }
            }
        }
        .task(id: "complete-\(isComplete)-\(renderMode.rawValue)") {
            guard isComplete else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(completeAvatarInterval * 1_000_000_000))
                guard !Task.isCancelled, isComplete else { break }
                await MainActor.run {
                    doneAvatarTrigger = UUID()
                }
            }
        }
        .onChange(of: completeTrigger) { _, newValue in
            guard newValue != nil, isComplete else { return }
            doneSparkleTrigger = UUID()
            doneAvatarTrigger = UUID()
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
                                .white.opacity(flashOpacity * 0.26),
                                color.opacity(flashOpacity * 0.22),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: max(size.width, size.height) * 0.82
                        )
                    )
                    .scaleEffect(glowScale)
                    .blur(radius: 12)

                // Primary chunky white sweep
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: color.opacity(flashOpacity * 0.18), location: 0.18),
                                .init(color: .white.opacity(flashOpacity * 0.95), location: 0.50),
                                .init(color: color.opacity(flashOpacity * 0.34), location: 0.82),
                                .init(color: .clear, location: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sweepWidth, height: size.height * 2.1)
                    .blur(radius: 8)
                    .offset(x: travel * sweepOffset - sweepWidth)
                    .rotationEffect(.degrees(-16))
                    .blendMode(.screen)

                // Trailing color echo (chromatic RGB feel)
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.00),
                                .init(color: color.opacity(flashOpacity * 0.52), location: 0.50),
                                .init(color: .clear, location: 1.00)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sweepWidth * 0.45, height: size.height * 2.1)
                    .blur(radius: 14)
                    .offset(x: travel * sweepOffset - sweepWidth * 1.6)
                    .rotationEffect(.degrees(-16))
                    .blendMode(.screen)
                    .opacity(0.85)
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

// MARK: - Gaming HUD Shapes

private struct ScanlinePattern: Shape {
    var spacing: CGFloat = 2.5

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y: CGFloat = 0
        while y < rect.height {
            path.addRect(CGRect(x: rect.minX, y: rect.minY + y, width: rect.width, height: 1))
            y += spacing
        }
        return path
    }
}

private struct PixelGridPattern: Shape {
    var cell: CGFloat = 4
    var dotSize: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var y = rect.minY
        while y < rect.maxY {
            var x = rect.minX
            while x < rect.maxX {
                path.addRect(CGRect(x: x, y: y, width: dotSize, height: dotSize))
                x += cell
            }
            y += cell
        }
        return path
    }
}

private struct AnimatedPowerLEDStrip: View {
    let accentColor: Color
    let cornerRadius: CGFloat

    var body: some View {
        GeometryReader { geometry in
            SlayPowerLEDStripRepresentable(
                size: geometry.size,
                color: accentColor,
                cornerRadius: cornerRadius
            )
        }
        .allowsHitTesting(false)
    }
}

private struct AnimatedAvatarScanSweep: View {
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            SlayAvatarScanSweepRepresentable(
                size: geometry.size,
                color: accentColor
            )
        }
        .allowsHitTesting(false)
    }
}

private struct RainbowStarPowerBorder: View {
    let cornerRadius: CGFloat
    let intensity: Double

    var body: some View {
        GeometryReader { geometry in
            SlayRainbowBorderRepresentable(
                size: geometry.size,
                cornerRadius: cornerRadius,
                intensity: intensity
            )
        }
            .allowsHitTesting(false)
    }
}

private struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let fill: Color
    let delay: Double
    let rotation: Double
}

private struct PixelConfettiBurst: View {
    let color: Color
    let trigger: UUID?

    @State private var particles: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiPixel(piece: p, bounds: geo.size)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if trigger != nil { spawn() }
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != nil else { return }
            spawn()
        }
    }

    private func spawn() {
        let palette: [Color] = [
            color,
            .white,
            Color(red: 1.00, green: 0.80, blue: 0.20),
            Color(red: 0.30, green: 0.80, blue: 1.00),
            Color(red: 1.00, green: 0.36, blue: 0.54),
            Color(red: 0.50, green: 1.00, blue: 0.60)
        ]
        particles = (0..<18).map { i in
            ConfettiPiece(
                x: CGFloat.random(in: 0.05...0.95),
                angle: Double.random(in: -1.2...1.2),
                distance: CGFloat.random(in: 28...62),
                size: CGFloat.random(in: 3...5),
                fill: palette.randomElement() ?? color,
                delay: Double(i) * 0.012,
                rotation: Double.random(in: -180...180)
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            particles = []
        }
    }
}

private struct ConfettiPixel: View {
    let piece: ConfettiPiece
    let bounds: CGSize

    @State private var progress: CGFloat = 0

    private var positionX: CGFloat {
        let base = bounds.width * piece.x
        let drift = CGFloat(cos(piece.angle)) * piece.distance * progress
        return base + drift
    }

    private var positionY: CGFloat {
        let base = bounds.height * 0.55
        let lift = piece.distance * progress
        let fall = piece.distance * progress * progress * 1.8
        return base - lift + fall
    }

    var body: some View {
        Rectangle()
            .fill(piece.fill)
            .frame(width: piece.size, height: piece.size)
            .shadow(color: piece.fill.opacity(0.8), radius: 2)
            .rotationEffect(.degrees(piece.rotation * Double(progress) * 2))
            .position(x: positionX, y: positionY)
            .opacity(Double(1 - progress))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + piece.delay) {
                    withAnimation(.easeOut(duration: 1.2)) {
                        progress = 1
                    }
                }
            }
    }
}

private struct ShineSparkle: Shape {
    var armRatio: CGFloat = 0.18

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let w = rect.width
        let h = rect.height
        let ax = w * armRatio * 0.5
        let ay = h * armRatio * 0.5
        // Diamond horizontal arm
        path.move(to: CGPoint(x: rect.minX, y: cy))
        path.addLine(to: CGPoint(x: cx, y: cy - ay))
        path.addLine(to: CGPoint(x: rect.maxX, y: cy))
        path.addLine(to: CGPoint(x: cx, y: cy + ay))
        path.closeSubpath()
        // Diamond vertical arm
        path.move(to: CGPoint(x: cx, y: rect.minY))
        path.addLine(to: CGPoint(x: cx + ax, y: cy))
        path.addLine(to: CGPoint(x: cx, y: rect.maxY))
        path.addLine(to: CGPoint(x: cx - ax, y: cy))
        path.closeSubpath()
        return path
    }
}

private struct HUDCornerBrackets: Shape {
    var length: CGFloat = 6
    var thickness: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let l = min(length, min(rect.width, rect.height) / 3)

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY - l))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + l, y: rect.maxY))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX - l, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - l))

        return path
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
                    ShineSparkle()
                        .fill(statusColor.opacity(0.92))
                        .blur(radius: 0.4)
                    ShineSparkle()
                        .fill(.white.opacity(0.95))
                        .frame(width: stageSize * 0.14, height: stageSize * 0.14)
                }
                    .frame(width: stageSize * 0.26, height: stageSize * 0.26)
                    .shadow(color: statusColor.opacity(scaledOpacity(isSuperSlay ? 0.65 : 0.46)), radius: scaledRadius(isSuperSlay ? 5 : 3.5), x: 0, y: 0)
                    .rotationEffect(.degrees(runningOrbitAngle * 1.4))
                    .offset(y: -stageSize * 0.43)
                    .rotationEffect(.degrees(runningOrbitAngle))

                if showsSecondaryOrbit {
                    ZStack {
                        ShineSparkle()
                            .fill(statusColor.opacity(0.74))
                        ShineSparkle()
                            .fill(.white.opacity(0.78))
                            .frame(width: stageSize * 0.08, height: stageSize * 0.08)
                    }
                    .frame(width: stageSize * 0.18, height: stageSize * 0.18)
                    .shadow(color: statusColor.opacity(scaledOpacity(0.34)), radius: scaledRadius(3), x: 0, y: 0)
                    .rotationEffect(.degrees(-runningOrbitAngle * 2.1))
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

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .shadow(color: color.opacity(0.28), radius: 1.5, x: 0, y: 0)
            }
            .frame(width: dotSize + 4, height: dotSize + 4)

            Text(label.uppercased())
                .font(.system(size: fontSize, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
                .shadow(color: color.opacity(0.24), radius: 1, x: 0, y: 0)
        }
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .padding(.vertical, 2.5)
        .background(
            ZStack {
                // Chunky Nintendo pixel hard shadow (offset, no blur)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .offset(x: 0, y: 1.2)

                // Switch-button gradient fill
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.22),
                                color.opacity(0.10)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Top highlight bar (3D button lift)
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.30), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 4)
                        .padding(.horizontal, 2)
                        .padding(.top, 1)
                    Spacer(minLength: 0)
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(color.opacity(0.55), lineWidth: 0.8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .inset(by: 0.8)
                .stroke(.white.opacity(0.16), lineWidth: 0.4)
        )
        .shadow(color: color.opacity(0.14), radius: 1.2, x: 0, y: 0.5)
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
    let showsCPUInHeader: Bool
    let onToggleCollapsed: () -> Void

    @ObservedObject private var cpuMonitor = FloatifyCPUUsageMonitor.shared
    @State private var isHoveringCollapse = false
    @State private var isCPUMonitorActive = false

    private let animation = Animation.interpolatingSpring(
        mass: 1.0, stiffness: 160, damping: 18, initialVelocity: 0.0
    )

    private var cpuText: String {
        String(format: "%.1f%%CPU", cpuMonitor.cpuPercent)
    }

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

                    if showsCPUInHeader {
                        Text(cpuText)
                            .font(.system(size: 10, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(FloaterPalette.secondaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(FloaterPalette.chipFill.opacity(0.85)))
                    }

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
        .onAppear {
            syncCPUMonitorState()
        }
        .onDisappear {
            deactivateCPUMonitorIfNeeded()
        }
        .onChange(of: showsCPUInHeader) { _, _ in
            syncCPUMonitorState()
        }
    }

    private func syncCPUMonitorState() {
        if showsCPUInHeader {
            guard !isCPUMonitorActive else { return }
            FloatifyCPUUsageMonitor.shared.activate()
            isCPUMonitorActive = true
            return
        }

        deactivateCPUMonitorIfNeeded()
    }

    private func deactivateCPUMonitorIfNeeded() {
        guard isCPUMonitorActive else { return }
        FloatifyCPUUsageMonitor.shared.deactivate()
        isCPUMonitorActive = false
    }
}

// MARK: - Floater Panel

struct FloaterPanelView: View {
    let items: [FloaterPanelItem]
    let spacing: CGFloat
    let isCollapsed: Bool
    let showsCPUInHeader: Bool
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
                showsCPUInHeader: showsCPUInHeader,
                onToggleCollapsed: {
                    withAnimation(animation) { onToggleCollapsed() }
                }
            )

            if !isCollapsed {
                VStack(alignment: .leading, spacing: spacing) {
                    ForEach(items) { item in
                        FloaterStatusView(
                            message: item.item.state.message,
                            project: item.item.project,
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
                            runningPanelCount: item.runningPanelCount,
                            runningPanelIndex: item.runningPanelIndex,
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

// MARK: - FloaterStatusView

struct FloaterStatusView: View {
    let message: String
    var project: String?
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
    var runningPanelCount: Int = 0
    var runningPanelIndex: Int?
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

    init(
        message: String,
        project: String? = nil,
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
        runningPanelCount: Int = 0,
        runningPanelIndex: Int? = nil,
        isCompact: Bool = false,
        lastActivity: Date? = nil,
        modifiedFilesCount: Int = 0,
        shouldShake: Bool = false,
        dismissController: DismissController
    ) {
        self.message = message
        self.project = project
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
        self.runningPanelCount = runningPanelCount
        self.runningPanelIndex = runningPanelIndex
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

    private enum RunningEffectBudget {
        case focus
        case standard
        case reduced
        case minimal
    }

    private var effectiveSound: String? {
        sound
    }

    private var isRunning: Bool {
        statusState?.isProgressState == true
    }

    private var runningEffectBudget: RunningEffectBudget {
        guard isRunning else { return .focus }

        let count = runningPanelCount
        let index = runningPanelIndex ?? 0

        switch count {
        case 0...1:
            return .focus
        case 2:
            return index == 0 ? .standard : .minimal
        case 3...4:
            return index == 0 ? .reduced : .minimal
        default:
            return .minimal
        }
    }

    private var effectiveRenderMode: FloaterRenderMode {
        guard isRunning else { return renderMode }

        switch runningEffectBudget {
        case .focus:
            return renderMode
        case .standard:
            return renderMode == .superSlay ? .slay : renderMode
        case .reduced:
            return .lame
        case .minimal:
            return .lame
        }
    }

    private var accentColor: Color {
        statusIndicatorColor ?? .blue
    }

    private var effectTuning: FloaterEffectTuning {
        effectPreset.tuning
    }

    private var effectGlowMultiplier: Double {
        let base = max(effectTuning.glowMultiplier, 0.2)
        guard isRunning else { return base }

        switch runningEffectBudget {
        case .focus:
            return base
        case .standard:
            return min(base, 0.75)
        case .reduced:
            return min(base, 0.52)
        case .minimal:
            return 0.2
        }
    }

    private var usesMinimalRenderMode: Bool {
        isPersistent && effectiveRenderMode == .lame
    }

    private var isSuperSlayRenderMode: Bool {
        effectiveRenderMode == .superSlay
    }

    private var showsFancyFloaterEffects: Bool {
        isPersistent && effectiveRenderMode != .lame && runningEffectBudget != .minimal
    }

    private var showsParticleTrail: Bool {
        false
    }

    private func scaledGlow(_ value: Double) -> Double {
        min(value * effectGlowMultiplier, 1.0)
    }

    private var animatesPersistentStatus: Bool {
        effectiveRenderMode != .lame && (runningEffectBudget == .focus || runningEffectBudget == .standard) && animatesStatus
    }

    private var showsRunningSheen: Bool {
        false
    }

    private var showsPowerLEDStrip: Bool {
        false
    }

    private var showsAvatarScanSweep: Bool {
        false
    }

    private var showsRainbowBorder: Bool {
        false
    }

    private var panelGlowShadowOpacity: Double {
        guard isRunning else { return scaledGlow(0.03) }

        switch runningEffectBudget {
        case .focus:
            return scaledGlow(0.08)
        case .standard:
            return scaledGlow(0.045)
        case .reduced:
            return scaledGlow(0.02)
        case .minimal:
            return 0
        }
    }

    private var avatarBackgroundPrimaryOpacity: Double {
        guard let statusState else { return 0.18 }
        switch statusState {
        case .running: return 0.66
        case .idle: return 0.58
        case .complete: return 0.54
        }
    }

    private var avatarBackgroundSecondaryOpacity: Double {
        guard let statusState else { return 0.08 }
        switch statusState {
        case .running: return 0.40
        case .idle: return 0.34
        case .complete: return 0.30
        }
    }

    private var avatarBackgroundBorderOpacity: Double {
        guard let statusState else { return 0.08 }
        switch statusState {
        case .running: return 0.34
        case .idle: return 0.30
        case .complete: return 0.28
        }
    }

    private var stateLabel: String? {
        guard let state = statusState else { return nil }
        switch state {
        case .running: return "Running"
        case .idle: return "Idle"
        case .complete: return "Complete"
        }
    }

    private var completeTrigger: UUID? {
        completionTrigger
    }

    private var showsRunningDuration: Bool {
        false
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
            panelBackground
            persistentContent
        }
        .frame(
            width: floaterSize.persistentPanelWidth,
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
                    if showsRunningSheen {
                        SlayRunningSheenView(
                            color: accentColor,
                            cornerRadius: floaterSize.cornerRadius,
                            renderMode: effectiveRenderMode,
                            effectTuning: effectTuning
                        )
                    }

                    // Star-power rainbow border (Mario Kart invincibility vibe)
                    // Gated to Super Slay to save CPU on lower-tier modes.
                    if showsRainbowBorder {
                        RainbowStarPowerBorder(
                            cornerRadius: floaterSize.cornerRadius,
                            intensity: 0.55
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
        .shadow(
            color: FloaterPalette.panelShadow.opacity(isRunning ? 0.06 : (isHovering ? 0.22 : 0.16)),
            radius: isRunning ? 3 : (isHovering ? floaterSize.cardShadowRadius : max(floaterSize.cardShadowRadius - 2, 6)),
            x: 0,
            y: isRunning ? 1 : (isHovering ? 5 : 3)
        )
        .shadow(color: accentColor.opacity(isRunning ? 0.0 : panelGlowShadowOpacity), radius: isHovering ? 10 : 7, x: 0, y: 2)
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
                // Static panel layers: rasterized once via drawingGroup until
                // inputs (color, hovering, state, renderMode) change.
                panelBackgroundStaticLayers
                    .drawingGroup(opaque: false)

                // Power-LED strip (animated when running) - outside drawingGroup.
                if showsPowerLEDStrip {
                    AnimatedPowerLEDStrip(
                        accentColor: accentColor,
                        cornerRadius: floaterSize.cornerRadius
                    )
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
                .font(.system(size: floaterSize.projectFontSize, weight: .semibold, design: .rounded))
                .tracking(-0.2)
                .foregroundStyle(FloaterPalette.primaryText)
                .shadow(color: accentColor.opacity(isRunning ? 0.35 : 0.18), radius: 2, x: 0, y: 0)
                .shadow(color: .black.opacity(0.35), radius: 0.5, x: 0, y: 0.5)
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
                    fontSize: floaterSize.metaFontSize
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
                    .fill(accentColor.opacity(0.34))
                    .frame(
                        width: floaterSize.persistentStageSize * 0.58,
                        height: floaterSize.persistentStageSize * 0.58
                    )

                Circle()
                    .fill(accentColor)
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
                renderMode: effectiveRenderMode,
                effectTuning: effectTuning,
                isAnimating: animatesPersistentStatus,
                isRunning: isRunning,
                isIdle: statusState == .idle,
                isComplete: statusState == .complete,
                completeTrigger: completeTrigger
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var panelBackgroundStaticLayers: some View {
        ZStack {
            // Deep Switch-bezel base
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                .fill(FloaterPalette.panelTint.opacity(isHovering ? 0.96 : 0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                        .fill(Color.white.opacity(0.05))
                )

            // Cartridge body gradient: top lift, bottom shadow
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.06),
                            .clear,
                            Color.black.opacity(0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Subtle pixel-grid texture
            PixelGridPattern(cell: 5, dotSize: 1)
                .fill(.white.opacity(isSuperSlayRenderMode ? 0.025 : 0.018))
                .clipShape(RoundedRectangle(cornerRadius: floaterSize.cornerRadius))

            if isPersistent {
                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(isRunning ? (isSuperSlayRenderMode ? 0.24 : 0.18) : (isSuperSlayRenderMode ? 0.14 : 0.10)),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            // Glossy top sheen
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            FloaterPalette.highlight.opacity(0.14),
                            FloaterPalette.highlight.opacity(0.04),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            // Inner bevel
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius - 1)
                .inset(by: 1)
                .stroke(.white.opacity(isSuperSlayRenderMode ? 0.14 : 0.09), lineWidth: 0.8)

            if isSuperSlayRenderMode {
                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .strokeBorder(.white.opacity(isRunning ? 0.14 : 0.08), lineWidth: 0.8)
            }
        }
    }

    private var persistentAvatarBackground: some View {
        ZStack {
            // Static layers: rasterized once via drawingGroup and cached by SwiftUI
            // until inputs change (accentColor, state, renderMode).
            persistentAvatarBackgroundStaticLayers
                .drawingGroup(opaque: false)

            // Animated scan sweep (running only) - outside drawingGroup so it
            // animates cheaply on top of the cached static raster.
            if showsAvatarScanSweep {
                AnimatedAvatarScanSweep(accentColor: accentColor)
            }
        }
    }

    @ViewBuilder
    private var persistentAvatarBackgroundStaticLayers: some View {
        ZStack {
            // Base: deep void with status-tinted gradient
            Rectangle()
                .fill(avatarBackgroundFill)

            // Angular iridescent sweep (gamer holographic feel)
            if !usesMinimalRenderMode {
                Rectangle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: accentColor.opacity(0.00), location: 0.00),
                                .init(color: accentColor.opacity(0.38), location: 0.22),
                                .init(color: .white.opacity(0.22), location: 0.50),
                                .init(color: accentColor.opacity(0.32), location: 0.78),
                                .init(color: accentColor.opacity(0.00), location: 1.00)
                            ]),
                            center: .center
                        )
                    )
                    .blendMode(.screen)
                    .opacity(isRunning ? 0.95 : 0.60)
            }

            // Neon core glow
            RadialGradient(
                colors: [
                    .white.opacity(isRunning ? 0.28 : 0.16),
                    accentColor.opacity(usesMinimalRenderMode ? 0.36 : 0.46),
                    accentColor.opacity(0.08),
                    .clear
                ],
                center: .center,
                startRadius: 1,
                endRadius: floaterSize.avatarHitSize * 0.58
            )
            .blendMode(.plusLighter)

            // CRT scanlines
            if !usesMinimalRenderMode {
                ScanlinePattern(spacing: 2.5)
                    .fill(.white.opacity(isSuperSlayRenderMode ? 0.07 : 0.05))
                    .blendMode(.overlay)
            }

            // Top light wash (HUD highlight)
            if !usesMinimalRenderMode {
                LinearGradient(
                    colors: [
                        FloaterPalette.highlight.opacity(isSuperSlayRenderMode ? 0.22 : 0.14),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .blendMode(.screen)
            }

            // HUD corner brackets (static once rasterized, shadow bakes into raster)
            if !usesMinimalRenderMode {
                HUDCornerBrackets(length: 6, thickness: 1.2)
                    .stroke(
                        accentColor.opacity(isRunning ? 0.95 : 0.62),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)
                    )
                    .padding(3)
            }

            // Outer neon border (shadow baked into raster, no per-frame pass)
            Rectangle()
                .strokeBorder(accentColor.opacity(min(avatarBackgroundBorderOpacity + 0.18, 1.0)), lineWidth: 1.0)

            // Inner highlight line (double-border gamer seal)
            if !usesMinimalRenderMode {
                Rectangle()
                    .inset(by: 1.5)
                    .stroke(.white.opacity(isSuperSlayRenderMode ? 0.16 : 0.10), lineWidth: 0.5)
            }

            // Right-edge neon seam
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0),
                                accentColor.opacity(0.90),
                                .white.opacity(0.80),
                                accentColor.opacity(0.90),
                                accentColor.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2)
                    .padding(.vertical, 2)
                    .blendMode(.screen)
            }
        }
    }

    private var avatarBackgroundFill: AnyShapeStyle {
        if usesMinimalRenderMode {
            return AnyShapeStyle(accentColor.opacity(0.48))
        }

        return AnyShapeStyle(
            LinearGradient(
                colors: [
                    accentColor.opacity(scaledGlow(min(avatarBackgroundPrimaryOpacity + 0.10, 1.0))),
                    accentColor.opacity(scaledGlow(avatarBackgroundSecondaryOpacity)),
                    FloaterPalette.panelShadow.opacity(0.58),
                    Color.black.opacity(0.44)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
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
