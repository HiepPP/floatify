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

private enum SpriteSheetCache {
    static let sheetName = "image"
    static var sheetCGImage: CGImage? = {
        guard let url = Bundle.main.url(forResource: sheetName, withExtension: "png"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }()
    static var frames: [String: NSImage] = [:]

    static func image(for rect: CGRect) -> NSImage? {
        let key = "\(Int(rect.origin.x)):\(Int(rect.origin.y)):\(Int(rect.size.width)):\(Int(rect.size.height))"
        if let cached = frames[key] {
            return cached
        }

        guard let cropped = sheetCGImage?.cropping(to: rect) else {
            return nil
        }

        let image = NSImage(cgImage: cropped, size: rect.size)
        frames[key] = image
        return image
    }
}

private struct SpriteAnimationView: View {
    let character: StatusSpriteCharacter
    let isAnimating: Bool
    var size: CGFloat = 44

    @State private var frameIndex = 0
    private let timer = Timer.publish(every: 0.16, on: .main, in: .common).autoconnect()

    private var frameRects: [CGRect] {
        switch character {
        case .squirtle:
            return [
                CGRect(x: 6, y: 203, width: 44, height: 44),
                CGRect(x: 45, y: 203, width: 44, height: 44),
                CGRect(x: 85, y: 203, width: 46, height: 44),
                CGRect(x: 128, y: 205, width: 42, height: 44),
                CGRect(x: 168, y: 206, width: 42, height: 42),
                CGRect(x: 207, y: 207, width: 44, height: 42)
            ]
        case .wartortle:
            return [
                CGRect(x: 302, y: 206, width: 47, height: 40),
                CGRect(x: 350, y: 208, width: 47, height: 40),
                CGRect(x: 430, y: 210, width: 44, height: 44),
                CGRect(x: 478, y: 208, width: 45, height: 46),
                CGRect(x: 520, y: 210, width: 46, height: 44),
                CGRect(x: 564, y: 210, width: 46, height: 42)
            ]
        case .blastoise:
            return [
                CGRect(x: 13, y: 149, width: 44, height: 44),
                CGRect(x: 54, y: 146, width: 46, height: 46),
                CGRect(x: 98, y: 154, width: 46, height: 38),
                CGRect(x: 141, y: 156, width: 45, height: 38),
                CGRect(x: 184, y: 151, width: 47, height: 42),
                CGRect(x: 225, y: 152, width: 46, height: 41)
            ]
        }
    }

    var body: some View {
        Group {
            if let image = SpriteSheetCache.image(for: frameRects[frameIndex]) {
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

    private let collapseAnimation = Animation.spring(response: 0.34, dampingFraction: 0.86)

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

    private let collapseAnimation = Animation.spring(response: 0.34, dampingFraction: 0.86)

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
                            spriteCharacter: item.spriteCharacter,
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
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .scale(scale: 0.96, anchor: .top).combined(with: .opacity)
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
    var spriteCharacter: StatusSpriteCharacter?
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
        spriteCharacter: StatusSpriteCharacter? = nil,
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
        self.spriteCharacter = spriteCharacter
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
        .fixedSize(horizontal: isDraggablePanel, vertical: false)
        .frame(width: isDraggablePanel ? nil : (isCompact ? 240 : 280))
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
            } else {
                showIdleAnimations = true
            }
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
            if let spriteCharacter {
                SpriteAnimationView(
                    character: spriteCharacter,
                    isAnimating: showIdleAnimations && shouldAnimateStatus,
                    size: floaterSize.spriteSize
                )
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
        let stageSize = floaterSize.stageSize
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.12),
                            .white.opacity(0.06)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: stageSize / 2
                    )
                )
                .frame(width: stageSize, height: stageSize)

            Circle()
                .fill(statusAccentColor.opacity(isRunning ? 0.18 : 0.10))
                .frame(width: stageSize - 10, height: stageSize - 10)
                .blur(radius: 8)

            duckIcon
                .scaleEffect(1.1)
        }
        .frame(width: stageSize, height: stageSize)
        .overlay(
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.16),
                            .white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }

    @ViewBuilder
    private var tappablePersistentSpriteStage: some View {
        if let onTap {
            Button(action: onTap) {
                persistentSpriteStage
            }
            .buttonStyle(.plain)
            .contentShape(Circle())
            .help("Open project in VS Code")
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
