import AppKit
import SwiftUI

// MARK: - FloaterSize

enum FloaterSize {
    case compact
    case regular
    case large

    var rowHeight: CGFloat {
        switch self {
        case .compact: return 38
        case .regular: return 46
        case .large: return 60
        }
    }

    var spriteSize: CGFloat {
        switch self {
        case .compact: return 26
        case .regular: return 32
        case .large: return 40
        }
    }

    var stageSize: CGFloat {
        switch self {
        case .compact: return 30
        case .regular: return 38
        case .large: return 48
        }
    }

    var dotSize: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 7
        case .large: return 9
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 10
        case .regular: return 12
        case .large: return 14
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 10
        case .large: return 12
        }
    }

    var projectFontSize: CGFloat {
        switch self {
        case .compact: return 12
        case .regular: return 13
        case .large: return 14.5
        }
    }

    var metaFontSize: CGFloat {
        switch self {
        case .compact: return 9.5
        case .regular: return 10.5
        case .large: return 11.5
        }
    }

    var isSingleLine: Bool {
        switch self {
        case .compact, .regular: return true
        case .large: return false
        }
    }

    var panelWidth: CGFloat {
        switch self {
        case .compact: return 270
        case .regular: return 330
        case .large: return 380
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

            if isComplete {
                SparkleBurst(trigger: completeTrigger)
            }
        }
        .frame(width: stageSize + 6, height: stageSize + 6)
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
        withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) {
            celebrateScale = 1.22
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                celebrateScale = 1.0
            }
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    let color: Color
    let label: String
    let emoji: String?
    let dotSize: CGFloat
    let fontSize: CGFloat
    let isPulsing: Bool
    let showsTypingDots: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.55

    var body: some View {
        HStack(spacing: 4) {
            if let emoji {
                Text(emoji)
                    .font(.system(size: fontSize + 1))
            } else {
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
            }

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
        .padding(.leading, 6)
        .padding(.trailing, 8)
        .padding(.vertical, 2.5)
        .fixedSize()
        .background(
            Capsule().fill(color.opacity(0.14))
        )
        .overlay(
            Capsule().strokeBorder(color.opacity(0.28), lineWidth: 0.5)
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

    @State private var shakeAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: shakeTrigger) { newValue in
                guard newValue != nil else { return }
                shakeAmount = 0
                withAnimation(.easeOut(duration: 0.6)) {
                    shakeAmount = 1
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

                HStack(spacing: 8) {
                    VStack(spacing: 2.5) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 2.5) {
                                Circle().fill(.white.opacity(0.22)).frame(width: 3, height: 3)
                                Circle().fill(.white.opacity(0.22)).frame(width: 3, height: 3)
                            }
                        }
                    }

                    Text("Floaters")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundStyle(.primary)

                    Text("\(itemCount)")
                        .font(.system(size: 10.5, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(.white.opacity(0.12)))

                    Spacer(minLength: 0)
                }
                .padding(.leading, 10)
                .padding(.trailing, 4)
                .padding(.vertical, 7)
                .allowsHitTesting(false)
            }

            Capsule()
                .fill(.white.opacity(0.10))
                .frame(width: 1, height: 16)

            Button(action: onToggleCollapsed) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isHoveringCollapse ? .primary : .secondary)
                    .rotationEffect(.degrees(isCollapsed ? 180 : 0))
                    .animation(animation, value: isCollapsed)
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHoveringCollapse = $0 }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.18), .white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 5)
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
        .padding(7)
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
        case .running: return "Cooking"
        case .idle: return "Chillin"
        case .complete: return "Done!"
        }
    }

    private var stateEmoji: String? {
        guard let state = statusState else { return nil }
        switch state {
        case .running: return "\u{1F468}\u{200D}\u{1F373}"  // 👨‍🍳
        case .idle: return "\u{1F634}"                      // 😴
        case .complete: return "\u{1F389}"                  // 🎉
        }
    }

    private var completeTrigger: UUID? {
        statusState == .complete ? UUID() : nil
    }

    private var timeAgoText: String? {
        guard let lastActivity else { return nil }
        let interval = Date().timeIntervalSince(lastActivity)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval) / 60)m" }
        return "\(Int(interval) / 3600)h"
    }

    private var displayName: String {
        let name = project ?? "Claude Code"
        let maxLength = isCompact ? 14 : 18
        if name.count > maxLength {
            return String(name.prefix(maxLength)) + "..."
        }
        return name
    }

    private var isPersistent: Bool {
        isDraggablePanel && statusIndicatorColor != nil
    }

    var body: some View {
        ZStack {
            if corner == .cursorFollow {
                ParticleTrailView(system: particleSystem, color: .yellow)
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
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(isHovering ? 0.32 : 0.20),
                            .white.opacity(isHovering ? 0.12 : 0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(isHovering ? 0.26 : 0.18), radius: isHovering ? 18 : 12, x: 0, y: isHovering ? 10 : 5)
        .shadow(color: accentColor.opacity(isRunning ? 0.22 : 0), radius: 14, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.18), value: isHovering)
        .animation(.easeInOut(duration: 0.22), value: accentColor)
        .scaleEffect(panelScale)
        .opacity(panelOpacity)
        .onHover { isHovering = $0 }
        .onAppear {
            if playsEntryAnimation {
                triggerEntry()
            }
            if shouldShake {
                shakeTrigger = UUID()
            }
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
                .fill(.ultraThinMaterial)

            if isPersistent {
                // Status-tinted radial wash from the avatar side (quieter)
                RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(isRunning ? 0.10 : 0.04),
                                accentColor.opacity(isRunning ? 0.04 : 0.02),
                                .clear
                            ],
                            center: .leading,
                            startRadius: 0,
                            endRadius: floaterSize.panelWidth * 0.55
                        )
                    )
            }

            // Top-edge sheen
            RoundedRectangle(cornerRadius: floaterSize.cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.10),
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
        HStack(spacing: 8) {
            Button(action: {
                NSLog("Floatify: Avatar tapped, invoking onTap")
                onTap?()
            }) {
                avatarStage
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .scaleEffect(isAvatarHovering ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAvatarHovering)
            .onHover { isAvatarHovering = $0 }
            .help("Open project in editor")

            if floaterSize.isSingleLine {
                singleLineBody
            } else {
                twoLineBody
            }

            if let stateLabel {
                StatusPill(
                    color: accentColor,
                    label: stateLabel,
                    emoji: stateEmoji,
                    dotSize: floaterSize.dotSize,
                    fontSize: floaterSize.metaFontSize,
                    isPulsing: isRunning && animatesStatus,
                    showsTypingDots: isRunning && animatesStatus
                )
            }

            closeButton
                .opacity(isHovering ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: isHovering)
                .frame(width: 16, alignment: .trailing)
        }
        .padding(.leading, floaterSize.horizontalPadding - 2)
        .padding(.trailing, floaterSize.horizontalPadding)
    }

    @ViewBuilder
    private var singleLineBody: some View {
        HStack(spacing: 6) {
            Text(displayName)
                .font(.system(size: floaterSize.projectFontSize, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(1)

            metaInline
                .layoutPriority(0)

            Spacer(minLength: 4)
        }
    }

    @ViewBuilder
    private var twoLineBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(displayName)
                .font(.system(size: floaterSize.projectFontSize, weight: .semibold))
                .tracking(-0.2)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            metaInline
        }

        Spacer(minLength: 4)
    }

    @ViewBuilder
    private var metaInline: some View {
        HStack(spacing: 5) {
            if let timeAgoText {
                Text(timeAgoText)
                    .font(.system(size: floaterSize.metaFontSize, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize()
            }

            if timeAgoText != nil && modifiedFilesCount > 0 {
                Circle()
                    .fill(.secondary.opacity(0.5))
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
                .foregroundStyle(.orange)
                .fixedSize()
            }
        }
    }

    @ViewBuilder
    private var avatarStage: some View {
        SpriteStageView(
            sheetName: sheetName,
            statusColor: accentColor,
            stageSize: floaterSize.stageSize,
            spriteSize: floaterSize.spriteSize,
            isAnimating: animatesStatus,
            isRunning: isRunning,
            isComplete: statusState == .complete,
            completeTrigger: completeTrigger
        )
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
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer(minLength: 4)

            if let project {
                Text(project)
                    .font(.system(size: floaterSize.metaFontSize, weight: .semibold))
                    .tracking(-0.1)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(.white.opacity(0.12)))
                    .overlay(Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, floaterSize.horizontalPadding)
    }

    private var closeButton: some View {
        Button(action: { onClose?() }) {
            Image(systemName: "xmark")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(isCloseHovering ? .primary : .secondary)
                .frame(width: 14, height: 14)
                .background(
                    Circle()
                        .fill(isCloseHovering ? .white.opacity(0.20) : .white.opacity(0.06))
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
}
