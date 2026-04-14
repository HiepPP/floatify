import SwiftUI
import Lottie

struct FloatNotificationView: View {
    let message: String
    var project: String?
    var corner: Corner = .bottomRight
    var effect: String?
    var sound: String?
    var onTap: (() -> Void)?
    var statusIndicatorColor: Color?
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

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 280, height: 68)
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

    private var duckIcon: some View {
        Text("\u{1F986}")
            .font(.system(size: 32))
            .bobbing(isEnabled: showIdleAnimations)
            .glowPulse(isEnabled: showIdleAnimations && showGlow)
            .floatDrift(isEnabled: showIdleAnimations)
            .hoverScale()
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
