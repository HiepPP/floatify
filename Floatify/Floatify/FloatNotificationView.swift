import SwiftUI
import Lottie

enum StatusSpriteCharacter {
    case squirtle
    case wartortle
    case blastoise
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
        .frame(width: 44, height: 44)
        .onReceive(timer) { _ in
            guard isAnimating else { return }
            frameIndex = (frameIndex + 1) % frameRects.count
        }
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
        if name.count > 20 {
            return String(name.prefix(20)) + "..."
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
        showsStatusAsColorOnly ? 22 : 16
    }

    private var statusDotSize: CGFloat {
        showsStatusAsColorOnly ? 12 : 8
    }

    private var panelBorderColor: Color {
        showsStatusAsColorOnly ? .white.opacity(0.18) : .white.opacity(0.10)
    }

    private var textForegroundStyle: AnyShapeStyle {
        AnyShapeStyle(showsStatusAsColorOnly ? .primary : .secondary)
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

            HStack(spacing: showsStatusAsColorOnly ? 10 : 12) {
                if showsStatusAsColorOnly {
                    persistentSpriteStage
                } else {
                    duckIcon
                }

                VStack(alignment: .leading, spacing: showsStatusAsColorOnly ? 2 : 4) {
                    if showsStatusAsColorOnly {
                        HStack(spacing: 10) {
                            Text(displayName)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            statusIndicator
                        }
                    } else {
                        HStack(spacing: 7) {
                            statusIndicator

                            Text(displayName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(textForegroundStyle)
                                .lineLimit(1)
                        }
                    }

                    if !showsStatusAsColorOnly {
                        Text(message)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    }
                }

                if !isDraggablePanel {
                    Spacer(minLength: 0)
                } else {
                    Capsule()
                        .fill(.white.opacity(0.08))
                        .frame(width: 1, height: 36)
                        .padding(.leading, 2)
                }
            }
            .padding(.horizontal, showsStatusAsColorOnly ? 12 : 16)
            .padding(.vertical, showsStatusAsColorOnly ? 8 : 12)
        }
        .fixedSize(horizontal: isDraggablePanel, vertical: false)
        .frame(width: isDraggablePanel ? nil : 280)
        .frame(minHeight: showsStatusAsColorOnly ? 72 : 68)
        .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius))
        .shadow(color: .black.opacity(showsStatusAsColorOnly ? 0.16 : 0.18), radius: 16, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        .scaleEffect(panelScale)
        .opacity(panelOpacity)
        .allowsHitTesting(true)
        .overlay(alignment: .topTrailing) {
            if isDraggablePanel {
                closeButton
                    .padding(7)
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
                .fill(.regularMaterial)

            if showsStatusAsColorOnly {
                RoundedRectangle(cornerRadius: panelCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            RoundedRectangle(cornerRadius: panelCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.12),
                            .white.opacity(0.03),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            if showsStatusAsColorOnly {
                HStack {
                    Circle()
                        .fill(statusAccentColor.opacity(0.16))
                        .frame(width: 58, height: 58)
                        .blur(radius: 20)
                    Spacer()
                }
                .padding(.leading, 6)
            }

            RoundedRectangle(cornerRadius: panelCornerRadius)
                .stroke(panelBorderColor, lineWidth: 1)

            RoundedRectangle(cornerRadius: panelCornerRadius - 1.5)
                .stroke(.white.opacity(0.05), lineWidth: 1)
                .padding(1.5)
        }
    }

    @ViewBuilder
    private var duckIcon: some View {
        let icon = Group {
            if let spriteCharacter {
                SpriteAnimationView(character: spriteCharacter, isAnimating: showIdleAnimations && shouldAnimateStatus)
            } else {
                Text("\u{1F986}")
                    .font(.system(size: 30))
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
                Circle()
                    .fill(statusIndicatorColor.opacity(showsStatusAsColorOnly ? 0.26 : 0.14))
                    .frame(width: statusDotSize + (showsStatusAsColorOnly ? 10 : 9), height: statusDotSize + (showsStatusAsColorOnly ? 10 : 9))
                    .blur(radius: showsStatusAsColorOnly ? 7 : 2)

                Circle()
                    .fill(statusIndicatorColor)
                    .frame(width: statusDotSize, height: statusDotSize)
            }
        }
    }

    private var persistentSpriteStage: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 52, height: 52)

            Circle()
                .fill(statusAccentColor.opacity(0.12))
                .frame(width: 42, height: 42)
                .blur(radius: 6)

            duckIcon
                .scaleEffect(1.08)
        }
        .frame(width: 56, height: 56)
        .overlay(
            Circle()
                .stroke(.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var closeButton: some View {
        Button(action: {
            onClose?()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isCloseHovering ? .primary : .secondary)
                .frame(width: 18, height: 18)
                .background(
                    Circle()
                        .fill(isCloseHovering ? .white.opacity(0.18) : .black.opacity(0.08))
                )
                .overlay(
                    Circle().strokeBorder(.white.opacity(isCloseHovering ? 0.24 : 0.10), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .scaleEffect(isCloseHovering ? 1.04 : 1.0)
        .onHover { hovering in
            isCloseHovering = hovering
        }
    }

    private func triggerEntry() {
        SoundManager.shared.play(effectiveSound)

        isEntryPlaying = true

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            panelScale = 1.0
            panelOpacity = 1.0
        }
    }

    private func triggerExit() {
        showIdleAnimations = false
        isEntryPlaying = false

        withAnimation(.easeOut(duration: 0.25)) {
            panelScale = 0.85
            panelOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            dismissController.onDismissComplete?()
        }
    }
}
