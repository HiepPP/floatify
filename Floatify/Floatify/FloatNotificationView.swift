import AppKit
import SwiftUI
import Lottie

enum StatusSpriteCharacter {
    case squirtle
    case wartortle
    case blastoise
}

enum FloaterSize {
    case compact
    case regular
    case large

    var spriteSize: CGFloat {
        switch self {
        case .compact: return 36
        case .regular: return 44
        case .large: return 52
        }
    }

    var statusDotSize: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 10
        case .large: return 12
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .compact: return 16
        case .regular: return 20
        case .large: return 24
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .compact: return 10
        case .regular: return 12
        case .large: return 14
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .compact: return 6
        case .regular: return 8
        case .large: return 10
        }
    }

    var projectNameSize: CGFloat {
        switch self {
        case .compact: return 12
        case .regular: return 14
        case .large: return 16
        }
    }

    var stageSize: CGFloat {
        switch self {
        case .compact: return 44
        case .regular: return 56
        case .large: return 64
        }
    }
}

// MARK: - Sprite Sheet Metadata

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

// MARK: - Animate Source Manager

private enum AnimateSourceManager {
    static var availableSheets: [String] = {
        guard let bundleURL = Bundle.main.resourceURL,
              let contents = try? FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil) else {
            return []
        }
        return contents
            .filter { $0.pathExtension.lowercased() == "png" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }()

    static func randomSheetName() -> String? {
        guard !availableSheets.isEmpty else { return nil }
        return availableSheets.randomElement()
    }
}

// MARK: - Sprite Sheet Cache

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
    var size: CGFloat = 44

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

// MARK: - Cosmic Avatar Effects

private struct EnergyParticle: Identifiable {
    let id = UUID()
    var angle: Double
    var radius: CGFloat
    var opacity: Double
    var scale: CGFloat
    var speed: Double
    var birthTime: Date

    var age: TimeInterval {
        Date().timeIntervalSince(birthTime)
    }
}

private struct AvatarAuraView: View {
    let baseColor: Color
    let isAnimating: Bool
    let intensity: Double

    @State private var auraPhase: Double = 0
    @State private var innerGlowScale: CGFloat = 1.0
    @State private var outerGlowScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer glow layer - slow pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(0.25 * intensity),
                            baseColor.opacity(0.15 * intensity),
                            baseColor.opacity(0.05 * intensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 35
                    )
                )
                .frame(width: 70 * outerGlowScale, height: 70 * outerGlowScale)
                .blur(radius: 8)

            // Middle aura - medium pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            baseColor.opacity(0.35 * intensity),
                            baseColor.opacity(0.20 * intensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 25
                    )
                )
                .frame(width: 50 * innerGlowScale, height: 50 * innerGlowScale)
                .blur(radius: 5)

            // Core glow - fast shimmer
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.30 * intensity),
                            baseColor.opacity(0.40 * intensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 18
                    )
                )
                .frame(width: 36, height: 36)
                .blur(radius: 3)
                .rotationEffect(.degrees(auraPhase * 30))
                .opacity(0.8 + 0.2 * sin(auraPhase * 2))
        }
        .onAppear {
            guard isAnimating else { return }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                innerGlowScale = 1.15
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                outerGlowScale = 1.2
            }
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                auraPhase = 1
            }
        }
    }
}

private struct PulsingRingsView: View {
    let color: Color
    let isAnimating: Bool

    @State private var ring1Progress: CGFloat = 0
    @State private var ring2Progress: CGFloat = 0
    @State private var ring3Progress: CGFloat = 0

    var body: some View {
        ZStack {
            // Ring 1 - fastest
            Circle()
                .stroke(
                    color.opacity(0.6 - ring1Progress * 0.5),
                    lineWidth: 1.5 - ring1Progress
                )
                .frame(width: 44 + ring1Progress * 20, height: 44 + ring1Progress * 20)
                .scaleEffect(1 + ring1Progress * 0.3)
                .opacity(1 - ring1Progress)

            // Ring 2 - medium
            Circle()
                .stroke(
                    color.opacity(0.5 - ring2Progress * 0.4),
                    lineWidth: 1.2 - ring2Progress * 0.8
                )
                .frame(width: 48 + ring2Progress * 24, height: 48 + ring2Progress * 24)
                .scaleEffect(1 + ring2Progress * 0.35)
                .opacity(0.8 - ring2Progress * 0.7)

            // Ring 3 - slowest
            Circle()
                .stroke(
                    color.opacity(0.4 - ring3Progress * 0.35),
                    lineWidth: 1 - ring3Progress * 0.7
                )
                .frame(width: 52 + ring3Progress * 28, height: 52 + ring3Progress * 28)
                .scaleEffect(1 + ring3Progress * 0.4)
                .opacity(0.6 - ring3Progress * 0.5)
        }
        .onAppear {
            guard isAnimating else { return }

            // Staggered ring animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    ring1Progress = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                    ring2Progress = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 2.2).repeatForever(autoreverses: false)) {
                    ring3Progress = 1
                }
            }
        }
    }
}

private struct OrbitingParticlesView: View {
    let color: Color
    let isAnimating: Bool
    var particleCount: Int = 6

    @State private var rotation: Double = 0
    @State private var particles: [EnergyParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(particle.opacity),
                                color.opacity(particle.opacity * 0.5),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 3
                        )
                    )
                    .frame(width: 5 * particle.scale, height: 5 * particle.scale)
                    .blur(radius: 1)
                    .offset(
                        x: cos(particle.angle) * particle.radius,
                        y: sin(particle.angle) * particle.radius
                    )
            }
        }
        .onAppear {
            initializeParticles()
            guard isAnimating else { return }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            startParticleLifecycle()
        }
        .onChange(of: rotation) { _ in
            updateParticlePositions()
        }
    }

    private func initializeParticles() {
        particles = (0..<particleCount).map { i in
            EnergyParticle(
                angle: Double(i) * (2 * .pi / Double(particleCount)),
                radius: CGFloat(22 + Double.random(in: -3...3)),
                opacity: Double.random(in: 0.4...0.8),
                scale: CGFloat.random(in: 0.6...1.2),
                speed: Double.random(in: 0.8...1.2),
                birthTime: Date()
            )
        }
    }

    private func updateParticlePositions() {
        for i in particles.indices {
            particles[i].angle += 0.02 * particles[i].speed
        }
    }

    private func startParticleLifecycle() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            updateParticlePositions()
            for i in particles.indices {
                particles[i].opacity = 0.4 + 0.4 * sin(Date().timeIntervalSince(particles[i].birthTime) * 2)
            }
        }
    }
}

private struct AvatarBreathingView: View {
    let isAnimating: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var tiltAngle: Double = 0

    private let randomTiltTimer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    var body: some View {
        content
            .scaleEffect(breathScale)
            .rotationEffect(.degrees(tiltAngle))
            .onAppear {
                guard isAnimating else { return }
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    breathScale = 1.03
                }
            }
            .onReceive(randomTiltTimer) { _ in
                guard isAnimating else { return }
                let newTilt = Double.random(in: -3...3)
                withAnimation(.easeInOut(duration: 1.5)) {
                    tiltAngle = newTilt
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        tiltAngle = 0
                    }
                }
            }
    }

    var content: some View {
        Rectangle().opacity(0)
    }
}

private struct EnhancedAvatarStageView: View {
    let sheetName: String?
    let statusColor: Color
    let isRunning: Bool
    let isAnimating: Bool
    let size: CGFloat

    @State private var isHovering = false
    @StateObject private var particleSystem = ParticleSystem()

    private var intensity: Double {
        isRunning ? 1.0 : (isHovering ? 0.8 : 0.6)
    }

    var body: some View {
        ZStack {
            // Outer aura glow
            AvatarAuraView(
                baseColor: statusColor,
                isAnimating: isAnimating,
                intensity: intensity
            )

            // Pulsing energy rings
            PulsingRingsView(
                color: statusColor,
                isAnimating: isAnimating && isRunning
            )

            // Orbiting particles
            OrbitingParticlesView(
                color: statusColor,
                isAnimating: isAnimating && isRunning,
                particleCount: isRunning ? 8 : 4
            )

            // Main stage container
            ZStack {
                // Glass stage background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.08),
                                .white.opacity(0.03)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)

                // Status-colored inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                statusColor.opacity(isRunning ? 0.25 : 0.15),
                                statusColor.opacity(isRunning ? 0.15 : 0.08),
                                .clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size / 2 - 5
                        )
                    )
                    .frame(width: size - 10, height: size - 10)
                    .blur(radius: 6)

                // The sprite with breathing effect
                if let sheetName {
                    SpriteAnimationView(
                        sheetName: sheetName,
                        isAnimating: isAnimating,
                        size: size - 16
                    )
                    .modifier(AvatarBreathingModifier(isEnabled: isAnimating))
                    .scaleEffect(1.12)
                }
            }
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovering ? 0.35 : 0.22),
                                .white.opacity(isHovering ? 0.18 : 0.10)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

private struct AvatarBreathingModifier: ViewModifier {
    let isEnabled: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var tiltAngle: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(breathScale)
            .rotationEffect(.degrees(tiltAngle))
            .onAppear {
                guard isEnabled else { return }
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    breathScale = 1.04
                }
                startRandomTilt()
            }
    }

    private func startRandomTilt() {
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            let newTilt = Double.random(in: -2.5...2.5)
            withAnimation(.easeInOut(duration: 1.2)) {
                tiltAngle = newTilt
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    tiltAngle = 0
                }
            }
        }
    }
}

private struct PulsingCircle: View {
    let color: Color
    let size: CGFloat
    var isPulsing: Bool = true

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: CGFloat = 1.0

    var body: some View {
        ZStack {
            if isPulsing {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: size * pulseScale * 1.5, height: size * pulseScale * 1.5)
                    .opacity(pulseOpacity * 0.4)
            }

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            guard isPulsing else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
                pulseOpacity = 0.5
            }
        }
    }
}

private struct ProgressRing: View {
    let color: Color
    let size: CGFloat
    var isAnimating: Bool = true

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            guard isAnimating else { return }
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

private final class WindowDragRegionView: NSView {
    override var acceptsFirstResponder: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        self
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

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

private struct FloaterPanelHeaderView: View {
    let itemCount: Int
    let runningCount: Int
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void

    @State private var isCollapseHovering = false

    private let collapseAnimation = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 160,
        damping: 18,
        initialVelocity: 0.0
    )

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                WindowDragRegion()

                HStack(spacing: 8) {
                    VStack(spacing: 2.5) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 2.5) {
                                Circle().fill(.white.opacity(0.25)).frame(width: 3, height: 3)
                                Circle().fill(.white.opacity(0.25)).frame(width: 3, height: 3)
                            }
                        }
                    }

                    Text("Floaters")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("\(itemCount)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.08)))

                    if runningCount > 0 {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                            Text("\(runningCount)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(.red.opacity(0.9))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.red.opacity(0.10)))
                    }

                    Spacer(minLength: 0)
                }
                .padding(.leading, 12)
                .padding(.trailing, 4)
                .padding(.vertical, 10)
                .allowsHitTesting(false)
            }

            Capsule()
                .fill(.white.opacity(0.08))
                .frame(width: 1, height: 18)

            Button(action: onToggleCollapsed) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isCollapseHovering ? .primary : .secondary)
                    .rotationEffect(.degrees(isCollapsed ? 180 : 0))
                    .animation(collapseAnimation, value: isCollapsed)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isCollapseHovering = hovering
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
    }
}

struct FloaterPanelView: View {
    let items: [FloaterPanelItem]
    let spacing: CGFloat
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void
    let onItemTap: (PersistentStatusItem) -> Void
    let onItemClose: (PersistentStatusItem) -> Void

    private let collapseAnimation = Animation.interpolatingSpring(
        mass: 1.0,
        stiffness: 160,
        damping: 18,
        initialVelocity: 0.0
    )

    private var runningCount: Int {
        items.reduce(into: 0) { result, item in
            if item.item.state == .running {
                result += 1
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FloaterPanelHeaderView(
                itemCount: items.count,
                runningCount: runningCount,
                isCollapsed: isCollapsed,
                onToggleCollapsed: {
                    withAnimation(collapseAnimation) {
                        onToggleCollapsed()
                    }
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
                            onTap: {
                                onItemTap(item.item)
                            },
                            onClose: {
                                onItemClose(item.item)
                            },
                            statusIndicatorColor: item.item.state.indicatorColor,
                            sheetName: item.sheetName,
                            animatesStatus: item.item.state == .running,
                            isDraggablePanel: true,
                            playsEntryAnimation: item.playsEntryAnimation,
                            floaterSize: item.floaterSize,
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
        .padding(8)
        .fixedSize()
        .clipped()
        .background(.clear)
        .animation(collapseAnimation, value: isCollapsed)
    }
}

struct FloatNotificationView: View {
    let message: String
    var project: String?
    var corner: Corner = .bottomRight
    var effect: String?
    var sound: String?
    var onTap: (() -> Void)?
    var onClose: (() -> Void)?
    var statusIndicatorColor: Color?
    var sheetName: String?
    var animatesStatus = true
    var isDraggablePanel = false
    var playsEntryAnimation = true
    var floaterSize: FloaterSize = .regular
    var isCompact: Bool = false
    @ObservedObject var dismissController: DismissController

    @State private var showGlow = false
    @State private var showIdleAnimations = false
    @State private var isEntryPlaying = false
    @State private var isPanelHovering = false
    @State private var isCloseHovering = false
    @State private var panelScale: CGFloat
    @State private var panelOpacity: CGFloat
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
        sheetName: String? = nil,
        animatesStatus: Bool = true,
        isDraggablePanel: Bool = false,
        playsEntryAnimation: Bool = true,
        floaterSize: FloaterSize = .regular,
        isCompact: Bool = false,
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
        self.sheetName = sheetName
        self.animatesStatus = animatesStatus
        self.isDraggablePanel = isDraggablePanel
        self.playsEntryAnimation = playsEntryAnimation
        self.floaterSize = floaterSize
        self.isCompact = isCompact || floaterSize == .compact
        self.dismissController = dismissController
        _panelScale = State(initialValue: playsEntryAnimation ? 0.85 : 1.0)
        _panelOpacity = State(initialValue: playsEntryAnimation ? 0 : 1.0)
    }

    private var effectiveEffect: String {
        effect ?? corner.defaultEffect
    }

    private var effectiveSound: String? {
        sound ?? corner.defaultSound
    }

    private var displayName: String {
        let name = project ?? "Claude Code"
        let maxLength = isCompact ? 16 : 20
        if name.count > maxLength {
            return String(name.prefix(maxLength)) + "..."
        }
        return name
    }

    private var shouldAnimateStatus: Bool {
        !isDraggablePanel || animatesStatus
    }

    private var showsStatusAsColorOnly: Bool {
        isDraggablePanel && statusIndicatorColor != nil
    }

    private var statusAccentColor: Color {
        statusIndicatorColor ?? .clear
    }

    private var panelCornerRadius: CGFloat {
        showsStatusAsColorOnly ? floaterSize.cornerRadius + 2 : floaterSize.cornerRadius
    }

    private var statusDotSize: CGFloat {
        floaterSize.statusDotSize
    }

    private var panelBorderColor: Color {
        showsStatusAsColorOnly ? .white.opacity(0.20) : .white.opacity(0.12)
    }

    private var textForegroundStyle: AnyShapeStyle {
        AnyShapeStyle(showsStatusAsColorOnly ? .primary : .secondary)
    }

    private var isRunning: Bool {
        statusIndicatorColor == .red
    }

    private var panelWidth: CGFloat? {
        if isDraggablePanel {
            switch floaterSize {
            case .compact: return 200
            case .regular: return 260
            case .large: return 320
            }
        }
        return isCompact ? 240 : 280
    }

    var body: some View {
        ZStack {
            if corner == .cursorFollow {
                ParticleTrailView(system: particleSystem, color: .yellow)
                    .frame(width: 300, height: 100)
            }

            panelBackground

            if !showsStatusAsColorOnly {
                LottiePanelBackground(
                    animationName: effectiveEffect.lottieFileName,
                    isPlaying: $isEntryPlaying,
                    onEntryComplete: {
                        showIdleAnimations = true
                        showGlow = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showGlow = false
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius))
            }

            HStack(spacing: floaterSize.horizontalPadding - 2) {
                if showsStatusAsColorOnly {
                    tappablePersistentSpriteStage
                } else {
                    duckIcon
                }

                VStack(alignment: .leading, spacing: isCompact ? 1 : 3) {
                    if showsStatusAsColorOnly {
                        HStack(spacing: 8) {
                            Text(displayName)
                                .font(.system(size: floaterSize.projectNameSize, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            Spacer(minLength: 0)

                            statusIndicator
                        }
                    } else {
                        HStack(spacing: 6) {
                            statusIndicator

                            Text(displayName)
                                .font(.system(size: isCompact ? 10 : 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(textForegroundStyle)
                                .lineLimit(1)
                        }
                    }

                    if !showsStatusAsColorOnly {
                        Text(message)
                            .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                }

                if !isDraggablePanel {
                    Spacer(minLength: 0)
                } else {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.14), .white.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 1, height: floaterSize.stageSize - 12)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, floaterSize.horizontalPadding)
            .padding(.vertical, floaterSize.verticalPadding)
        }
        .fixedSize(horizontal: isDraggablePanel ? false : true, vertical: false)
        .frame(width: panelWidth)
        .frame(minHeight: showsStatusAsColorOnly ? (isCompact ? 56 : 72) : (isCompact ? 56 : 68))
        .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius))
        .shadow(color: .black.opacity(isPanelHovering && isDraggablePanel ? 0.30 : 0.25), radius: isPanelHovering && isDraggablePanel ? 24 : 20, x: 0, y: isPanelHovering && isDraggablePanel ? 16 : 12)
        .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
        .shadow(color: statusAccentColor.opacity(isRunning ? 0.15 : 0), radius: 16, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.15), value: isPanelHovering)
        .scaleEffect(panelScale)
        .opacity(panelOpacity)
        .allowsHitTesting(true)
        .overlay(alignment: .topTrailing) {
            if isDraggablePanel {
                closeButton
                    .padding(6)
                    .opacity(isPanelHovering ? 1 : 0)
            }
        }
        .onHover { hovering in
            isPanelHovering = hovering
        }
        .onAppear {
            if playsEntryAnimation {
                triggerEntry()
            }
            showIdleAnimations = true
        }
        .onChange(of: dismissController.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                triggerExit()
            }
        }
    }

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: panelCornerRadius)
                .fill(.ultraThinMaterial)

            if showsStatusAsColorOnly {
                RoundedRectangle(cornerRadius: panelCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.10),
                                .white.opacity(0.04),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                HStack {
                    Circle()
                        .fill(statusAccentColor.opacity(isRunning ? 0.20 : 0.14))
                        .frame(width: floaterSize.stageSize, height: floaterSize.stageSize)
                        .blur(radius: 24)
                    Spacer()
                }
                .padding(.leading, -10)

                if isRunning {
                    RoundedRectangle(cornerRadius: panelCornerRadius)
                        .fill(
                            RadialGradient(
                                colors: [
                                    statusAccentColor.opacity(0.08),
                                    .clear
                                ],
                                center: .leading,
                                startRadius: 0,
                                endRadius: 120
                            )
                        )
                }
            }

            RoundedRectangle(cornerRadius: panelCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.14),
                            .white.opacity(0.04),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: panelCornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(isPanelHovering && isDraggablePanel ? 0.35 : 0.25),
                            .white.opacity(isPanelHovering && isDraggablePanel ? 0.14 : 0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .animation(.easeInOut(duration: 0.15), value: isPanelHovering)

            RoundedRectangle(cornerRadius: panelCornerRadius - 1)
                .strokeBorder(.white.opacity(0.06), lineWidth: 1)
                .padding(1)
        }
    }

    @ViewBuilder
    private var duckIcon: some View {
        let icon = Group {
            if let sheetName {
                SpriteAnimationView(
                    sheetName: sheetName,
                    isAnimating: showIdleAnimations && shouldAnimateStatus,
                    size: floaterSize.spriteSize
                )
                .modifier(AvatarBreathingModifier(isEnabled: showIdleAnimations && shouldAnimateStatus))
            } else {
                Text("\u{1F986}")
                    .font(.system(size: floaterSize.spriteSize - 14))
            }
        }

        if shouldAnimateStatus {
            icon
                .bobbing(isEnabled: showIdleAnimations)
                .floatDrift(isEnabled: showIdleAnimations)
        } else {
            icon
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if let statusIndicatorColor {
            ZStack {
                if isRunning && showsStatusAsColorOnly {
                    ProgressRing(
                        color: statusIndicatorColor,
                        size: statusDotSize + 6,
                        isAnimating: isRunning
                    )
                } else {
                    Circle()
                        .fill(statusIndicatorColor.opacity(0.20))
                        .frame(width: statusDotSize + (showsStatusAsColorOnly ? 8 : 6), height: statusDotSize + (showsStatusAsColorOnly ? 8 : 6))
                        .blur(radius: showsStatusAsColorOnly ? 6 : 2)
                }

                PulsingCircle(
                    color: statusIndicatorColor,
                    size: statusDotSize,
                    isPulsing: isRunning
                )
            }
        }
    }

    private var persistentSpriteStage: some View {
        EnhancedAvatarStageView(
            sheetName: sheetName,
            statusColor: statusAccentColor,
            isRunning: isRunning,
            isAnimating: showIdleAnimations && shouldAnimateStatus,
            size: floaterSize.stageSize
        )
    }

    @ViewBuilder
    private var tappablePersistentSpriteStage: some View {
        if let onTap {
            Button(action: {
                NSLog("Floatify: Avatar tapped, invoking onTap")
                onTap()
            }) {
                persistentSpriteStage
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .help("Open project in VS Code:")
        } else {
            persistentSpriteStage
        }
    }

    private var closeButton: some View {
        let buttonSize: CGFloat = isCompact ? 16 : 18
        return Button(action: {
            onClose?()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: isCompact ? 7 : 8, weight: .bold))
                .foregroundStyle(isCloseHovering ? .primary : .secondary)
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    ZStack {
                        Circle()
                            .fill(isCloseHovering ? .white.opacity(0.20) : .black.opacity(0.06))
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(isCloseHovering ? 0.10 : 0.04),
                                        .clear
                                    ],
                                    center: .top,
                                    startRadius: 0,
                                    endRadius: buttonSize / 2
                                )
                            )
                    }
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            .white.opacity(isCloseHovering ? 0.28 : 0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isCloseHovering ? 1.06 : 1.0)
        .onHover { hovering in
            isCloseHovering = hovering
        }
    }

    private func triggerEntry() {
        SoundManager.shared.play(effectiveSound)

        isEntryPlaying = true

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75, blendDuration: 0.1)) {
            panelScale = 1.0
            panelOpacity = 1.0
        }
    }

    private func triggerExit() {
        showIdleAnimations = false
        isEntryPlaying = false

        withAnimation(.easeOut(duration: 0.22)) {
            panelScale = 0.90
            panelOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            dismissController.onDismissComplete?()
        }
    }
}
