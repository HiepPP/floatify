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
    var statusIndicatorColor: Color?
    var spriteCharacter: StatusSpriteCharacter?
    var animatesStatus = true
    var isDraggablePanel = false
    var playsEntryAnimation = true
    @ObservedObject var dismissController: DismissController

    @State private var showGlow = false
    @State private var showIdleAnimations = false
    @State private var isEntryPlaying = false
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

    var body: some View {
        ZStack {
            if corner == .cursorFollow {
                ParticleTrailView(system: particleSystem, color: .yellow)
                    .frame(width: 300, height: 100)
            }

            RoundedRectangle(cornerRadius: 14)
                .fill(.regularMaterial)

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
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 10) {
                duckIcon

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        if let statusIndicatorColor {
                            Circle()
                                .fill(statusIndicatorColor)
                                .frame(width: 8, height: 8)
                        }

                        Text(displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(2)
                }

                if !isDraggablePanel {
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .fixedSize(horizontal: isDraggablePanel, vertical: false)
        .frame(width: isDraggablePanel ? nil : 280)
        .frame(minHeight: 68)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
        .scaleEffect(panelScale)
        .opacity(panelOpacity)
        .allowsHitTesting(!isDraggablePanel)
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
                .glowPulse(isEnabled: showIdleAnimations && showGlow)
                .floatDrift(isEnabled: showIdleAnimations)
                .hoverScale()
        } else {
            icon
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
