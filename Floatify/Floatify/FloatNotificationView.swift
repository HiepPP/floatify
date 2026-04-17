import AppKit
import SwiftUI

enum FloaterPalette {
    static let panelTint = Color(red: 0.075, green: 0.082, blue: 0.118)
    static let panelShadow = Color(red: 0.020, green: 0.024, blue: 0.040)
    static let primaryText = Color(red: 0.955, green: 0.970, blue: 1.000)
    static let secondaryText = Color(red: 0.645, green: 0.705, blue: 0.815)
    static let strokeStrong = Color(red: 0.720, green: 0.790, blue: 0.930)
    static let strokeSoft = Color(red: 0.280, green: 0.330, blue: 0.430)
    static let highlight = Color(red: 0.980, green: 0.990, blue: 1.000)
    static let running = Color(red: 0.965, green: 0.470, blue: 0.410)
    static let idle = Color(red: 0.915, green: 0.705, blue: 0.320)
    static let complete = Color(red: 0.330, green: 0.845, blue: 0.645)
    static let warning = Color(red: 0.948, green: 0.598, blue: 0.360)
    static let chipFill = Color(red: 0.145, green: 0.165, blue: 0.230)
    static let closeHover = Color(red: 0.240, green: 0.280, blue: 0.390)
}

// MARK: - FloaterSize

enum FloaterSize: Equatable {
    case compact
    case regular
    case large

    var rowHeight: CGFloat {
        switch self {
        case .compact: return 38
        case .regular: return 44
        case .large: return 56
        }
    }

    var spriteSize: CGFloat {
        switch self {
        case .compact: return 18
        case .regular: return 24
        case .large: return 36
        }
    }

    var stageSize: CGFloat {
        switch self {
        case .compact: return 24
        case .regular: return 30
        case .large: return 44
        }
    }

    var dotSize: CGFloat {
        switch self {
        case .compact: return 5
        case .regular: return 6
        case .large: return 9
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 10
        case .large: return 14
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 7
        case .regular: return 8
        case .large: return 12
        }
    }

    var projectFontSize: CGFloat {
        switch self {
        case .compact: return 11.5
        case .regular: return 12.5
        case .large: return 14.5
        }
    }

    var metaFontSize: CGFloat {
        switch self {
        case .compact: return 9
        case .regular: return 9.5
        case .large: return 11.5
        }
    }

    var isSingleLine: Bool {
        switch self {
        case .compact, .regular, .large: return false
        }
    }

    var panelWidth: CGFloat {
        switch self {
        case .compact: return 210
        case .regular: return 262
        case .large: return 352
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 7
        case .large: return 8
        }
    }

    var statusRailWidth: CGFloat {
        switch self {
        case .compact: return 4
        case .regular: return 5
        case .large: return 6
        }
    }

    var closeButtonSize: CGFloat {
        switch self {
        case .compact: return 12
        case .regular: return 13
        case .large: return 14
        }

    }

    var trailingInset: CGFloat {
        horizontalPadding + statusRailWidth + 6
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
        }
    }

    var statusPillMinWidth: CGFloat {
        switch self {
        case .compact: return 42
        case .regular: return 58
        case .large: return 66
        }
    }

    var bodySpacing: CGFloat {
        switch self {
        case .compact: return 1
        case .regular: return 2
        case .large: return 3
        }
    }
}

// MARK: - Sprite Sheet Infrastructure

private struct SpriteSheetMetadata {
    let frameRects: [CGRect]

    static let defaultMetadata = SpriteSheetMetadata(frameRects: [
        CGRect(x: 6, y: 203, width: 44, height: 44),
        CGRect(x: 45, y: 203, width: 44, height: 44),
        CGRect(x: 85, y: 203, width: 46, height: 44),
        CGRect(x: 128, y: 205, width: 42, height: 44),
        CGRect(x: 168, y: 206, width: 42, height: 42),
        CGRect(x: 207, y: 207, width: 44, height: 42)
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

    static func forSheet(_ name: String) -> SpriteSheetMetadata {
        bySheetName[name] ?? defaultMetadata
    }
}

private enum SpriteSheetCache {
    static var sheetCache: [String: CGImage] = [:]
    static var frames: [String: NSImage] = [:]

    static func cgImage(for sheetName: String) -> CGImage? {
        if let cached = sheetCache[sheetName] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: sheetName, withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }

        sheetCache[sheetName] = image
        return image
    }

    static func image(for rect: CGRect, sheetName: String) -> NSImage? {
        let key = "\(sheetName):\(Int(rect.origin.x)):\(Int(rect.origin.y)):\(Int(rect.size.width)):\(Int(rect.size.height))"
        if let cached = frames[key] {
            return cached
        }

        guard let sheet = cgImage(for: sheetName),
              let cropped = sheet.cropping(to: rect) else {
            return nil
        }

        let image = NSImage(cgImage: cropped, size: rect.size)
        frames[key] = image
        return image
    }
}

private struct SpriteAnimationView: View {
    let sheetName: String?
    let isAnimating: Bool
    var size: CGFloat = 34

    @State private var frameIndex = 0
    private let timer = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()

    private var effectiveSheetName: String {
        sheetName ?? "image"
    }

    private var metadata: SpriteSheetMetadata {
        SpriteSheetMetadata.forSheet(effectiveSheetName)
    }

    private var frameRects: [CGRect] {
        metadata.frameRects
    }

    var body: some View {
        Group {
            if let image = SpriteSheetCache.image(for: frameRects[frameIndex], sheetName: effectiveSheetName) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .onReceive(timer) { _ in
            guard isAnimating else { return }
            frameIndex = (frameIndex + 1) % frameRects.count
        }
    }
}

// MARK: - Typing Dots

private struct TypingDots: View {
    let color: Color
    let fontSize: CGFloat

    @State private var phase = 0
    private let timer = Timer.publish(every: 0.35, on: .main, in: .common).autoconnect()

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
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
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
        .onChange(of: trigger) { newValue in
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
    let sheetName: String?
    let statusColor: Color
    let stageSize: CGFloat
    let spriteSize: CGFloat
    let isAnimating: Bool
    let isRunning: Bool
    let isComplete: Bool
    let completeTrigger: UUID?

    @State private var glowPulse: CGFloat = 1.0
    @State private var celebrateScale: CGFloat = 1.0
    @State private var celebrateRotation: Double = 0
    @State private var celebrateRingScale: CGFloat = 0.76
    @State private var celebrateRingOpacity: Double = 0

    var body: some View {
        ZStack {
            // Single soft status-tinted halo. No glass disc.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            statusColor.opacity(isRunning ? 0.38 : 0.20),
                            statusColor.opacity(isRunning ? 0.14 : 0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize / 2 + 2
                    )
                )
                .frame(width: stageSize * 1.35 * glowPulse, height: stageSize * 1.35 * glowPulse)
                .blur(radius: 5)

            if isComplete {
                Circle()
                    .strokeBorder(statusColor.opacity(0.85), lineWidth: 1.6)
                    .frame(width: stageSize * celebrateRingScale, height: stageSize * celebrateRingScale)
                    .opacity(celebrateRingOpacity)
                    .blur(radius: 0.5)
            }

            // Sprite - motion gated on state
            Group {
                if let sheetName {
                    SpriteAnimationView(
                        sheetName: sheetName,
                        isAnimating: isRunning && isAnimating,
                        size: spriteSize
                    )
                } else {
                    Text("\u{1F986}")
                        .font(.system(size: spriteSize - 4))
                }
            }
            .bobbing(isEnabled: isRunning && isAnimating)
            .scaleEffect(celebrateScale)
            .rotationEffect(.degrees(celebrateRotation))

            if isComplete {
                SparkleBurst(trigger: completeTrigger)
            }

        }
        .frame(width: stageSize, height: stageSize)
        .onAppear {
            if isRunning && isAnimating {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    glowPulse = 1.10
                }
            }
            if isComplete {
                celebrate()
            }
        }
        .onChange(of: completeTrigger) { newValue in
            guard newValue != nil, isComplete else { return }
            celebrate()
        }
    }

    private func celebrate() {
        celebrateRingScale = 0.76
        celebrateRingOpacity = 0.84

        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            celebrateScale = 1.20
            celebrateRotation = -8
        }
        withAnimation(.easeOut(duration: 0.45)) {
            celebrateRingScale = 1.42
            celebrateRingOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                celebrateRotation = 6
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.58)) {
                celebrateScale = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                celebrateRotation = 0
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
    let isPulsing: Bool
    let showsTypingDots: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.55

    var body: some View {
        HStack(spacing: 4) {
            ZStack {
                if isPulsing {
                    Circle()
                        .fill(color.opacity(0.45))
                        .frame(width: dotSize * pulseScale * 2.0, height: dotSize * pulseScale * 2.0)
                        .opacity(pulseOpacity)
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
                TypingDots(color: color, fontSize: fontSize)
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
        .onAppear {
            guard isPulsing else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.4
                pulseOpacity = 0
            }
        }
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
            .onChange(of: shakeTrigger) { newValue in
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
                            sheetName: item.sheetName,
                            animatesStatus: item.item.state == .running || item.item.state == .idle,
                            isDraggablePanel: true,
                            playsEntryAnimation: item.playsEntryAnimation,
                            floaterSize: item.floaterSize,
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
    var sheetName: String?
    var animatesStatus = true
    var isDraggablePanel = false
    var playsEntryAnimation = true
    var floaterSize: FloaterSize = .regular
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
        sheetName: String? = nil,
        animatesStatus: Bool = true,
        isDraggablePanel: Bool = false,
        playsEntryAnimation: Bool = true,
        floaterSize: FloaterSize = .regular,
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
        self.sheetName = sheetName
        self.animatesStatus = animatesStatus
        self.isDraggablePanel = isDraggablePanel
        self.playsEntryAnimation = playsEntryAnimation
        self.floaterSize = floaterSize
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
    }

    private var effectiveSound: String? {
        sound ?? corner.defaultSound
    }

    private var isRunning: Bool {
        statusState == .running
    }

    private var accentColor: Color {
        statusIndicatorColor ?? .blue
    }

    private var stateLabel: String? {
        guard let state = statusState else { return nil }
        switch state {
        case .running: return "Running"
        case .idle: return "Idle"
        case .complete: return "Done"
        }
    }

    private var completeTrigger: UUID? {
        completionTrigger
    }

    private var timeAgoText: String? {
        guard let lastActivity else { return nil }
        let interval = Date().timeIntervalSince(lastActivity)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval) / 60)m" }
        return "\(Int(interval) / 3600)h"
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
            if corner == .cursorFollow {
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
        .frame(width: floaterSize.panelWidth, height: floaterSize.rowHeight)
        .clipShape(RoundedRectangle(cornerRadius: floaterSize.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                .strokeBorder(FloaterPalette.highlight.opacity(isHovering ? 0.14 : 0.08), lineWidth: 1)
        )
        .overlay(alignment: .trailing) {
            if isPersistent {
                statusRail
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
        .shadow(color: accentColor.opacity(isRunning ? 0.08 : 0.03), radius: isHovering ? 10 : 7, x: 0, y: 2)
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
        .onChange(of: statusState) { newValue in
            syncCompletionAnimation(for: newValue)
        }
        .onChange(of: shouldShake) { newValue in
            if newValue { shakeTrigger = UUID() }
        }
        .onChange(of: dismissController.shouldDismiss) { shouldDismiss in
            if shouldDismiss { triggerExit() }
        }
        .modifier(CompletionShakeModifier(shakeTrigger: shakeTrigger))
    }

    private var panelBackground: some View {
        ZStack {
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
                                accentColor.opacity(isRunning ? 0.14 : 0.08),
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
                        .scaleEffect(isAvatarHovering ? 1.06 : 1.0)
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
                    isPulsing: isRunning && animatesStatus,
                    showsTypingDots: isRunning && animatesStatus
                )
                .fixedSize(horizontal: true, vertical: false)
            }

            if floaterSize != .compact, let timeAgoText {
                Text(timeAgoText)
                    .font(.system(size: floaterSize.metaFontSize, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(FloaterPalette.secondaryText)
                    .lineLimit(1)
                    .fixedSize()
            }

            if floaterSize != .compact, timeAgoText != nil, modifiedFilesCount > 0 {
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
        SpriteStageView(
            sheetName: sheetName,
            statusColor: accentColor,
            stageSize: floaterSize.persistentStageSize,
            spriteSize: floaterSize.persistentSpriteSize,
            isAnimating: animatesStatus,
            isRunning: isRunning,
            isComplete: statusState == .complete,
            completeTrigger: completeTrigger
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var persistentAvatarBackground: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        accentColor.opacity(isRunning ? 0.24 : 0.16),
                        accentColor.opacity(isRunning ? 0.10 : 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [
                        FloaterPalette.highlight.opacity(0.10),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(FloaterPalette.highlight.opacity(0.08))
                    .frame(width: 1)
                    .padding(.vertical, 4)
            }
    }

    private var statusRail: some View {
        ZStack(alignment: .trailing) {
            Capsule()
                .fill(accentColor.opacity(isRunning ? 0.16 : 0.08))
                .frame(width: floaterSize.statusRailWidth + 3)
                .blur(radius: isRunning ? 3 : 2)

            Capsule()
                .fill(accentColor.opacity(isRunning ? 0.96 : 0.78))
                .frame(width: floaterSize.statusRailWidth)
                .overlay(
                    Capsule()
                        .fill(.white.opacity(isRunning ? 0.28 : 0.12))
                        .frame(width: 1),
                    alignment: .leading
                )
        }
        .padding(.vertical, 5)
        .padding(.trailing, 4)
    }

    @ViewBuilder
    private var temporaryContent: some View {
        HStack(spacing: 10) {
            // Sprite avatar (or duck fallback) for personality
            Group {
                if let sheetName {
                    SpriteAnimationView(
                        sheetName: sheetName,
                        isAnimating: animatesStatus,
                        size: floaterSize.spriteSize - 4
                    )
                } else {
                    Text("\u{1F986}")
                        .font(.system(size: floaterSize.spriteSize - 8))
                }
            }
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
    }
}
