import AppKit
import Foundation
import CoreVideo

final class CursorTracker {
    static let shared = CursorTracker()

    private var monitor: Any?
    private var rawPosition: CGPoint = .zero
    private var smoothedPosition: CGPoint = .zero
    private var velocityX: CGFloat = 0
    private var velocityY: CGFloat = 0

    // Spring physics parameters
    var smoothingSpeed: CGFloat = 12.0
    var springDamping: CGFloat = 0.70
    var springResponse: CGFloat = 0.40

    var edgePadding: CGFloat = 20

    // CVDisplayLink for frame-precise updates
    private var displayLink: CVDisplayLink?
    private var trackedPanels: [FloatPanel] = []
    private var lastFrameTime: CFTimeInterval = 0

    // Frame throttling for scroll performance
    private var frameCounter: Int = 0
    var frameSkip: Int = 1  // Update every 2nd frame (30Hz at 60Hz display)

    var currentPosition: CGPoint {
        NSEvent.mouseLocation
    }

    private init() {
        // Load frameSkip from UserDefaults (default: 1 = every 2nd frame = 30Hz)
        frameSkip = UserDefaults.standard.integer(forKey: "cursorFollowFrameSkip")
        if frameSkip == 0 {
            frameSkip = 1  // Ensure non-zero default
        }

        startTracking()
    }

    deinit {
        stopTracking()
        stopDisplayLink()
    }

    func startTracking() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            self?.handleMouseMove(event)
        }
    }

    func stopTracking() {
        monitor.map { NSEvent.removeMonitor($0) }
        monitor = nil
    }

    private func handleMouseMove(_ event: NSEvent) {
        rawPosition = NSEvent.mouseLocation
    }

    func updateSmoothing(dt: CGFloat) {
        let targetX = rawPosition.x
        let targetY = rawPosition.y
        let prevX = smoothedPosition.x
        let prevY = smoothedPosition.y

        // Spring physics parameters
        let w0 = 2.0 * .pi / springResponse  // natural frequency
        let zeta = springDamping              // damping ratio

        // Damped frequency
        let wd = w0 * sqrt(max(0, 1 - zeta * zeta))

        // Spring coefficients for underdamped system
        let expTerm = exp(-zeta * w0 * dt)
        let cosTerm = cos(wd * dt)
        let sinTerm = sin(wd * dt)

        // A and B coefficients for position update
        let A = expTerm * (cosTerm + (zeta * w0 / wd) * sinTerm)
        let B = expTerm * (sinTerm / wd)

        // Calculate displacement
        let dispX = targetX - prevX
        let dispY = targetY - prevY

        // Update smoothed position with spring physics
        let newX = targetX - B * velocityX + A * dispX
        let newY = targetY - B * velocityY + A * dispY

        smoothedPosition = CGPoint(x: newX, y: newY)

        // Update velocity
        if dt > 0 {
            velocityX = (newX - prevX) / dt
            velocityY = (newY - prevY) / dt
        }
    }

    func smoothedCursorPosition(panelSize: CGSize) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero
        return clampedPosition(in: screen, panelSize: panelSize)
    }

    func clampedPosition(in rect: CGRect, panelSize: CGSize = .zero) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero
        let pos = smoothedPosition

        var x = pos.x
        var y = pos.y

        let halfW = panelSize.width / 2
        let halfH = panelSize.height / 2

        x = max(rect.minX + edgePadding + halfW, min(x, rect.maxX - edgePadding - halfW))
        y = max(rect.minY + edgePadding + halfH, min(y, rect.maxY - edgePadding - halfH))

        x = max(edgePadding + halfW, min(x, screen.width - edgePadding - halfW))
        y = max(edgePadding + halfH, min(y, screen.height - edgePadding - halfH))

        return CGPoint(x: x, y: y)
    }

    func screenCornerPosition(for corner: Corner, panelSize: CGSize) -> CGPoint {
        let screen = NSScreen.main?.frame ?? .zero

        switch corner {
        case .bottomLeft:
            return CGPoint(x: edgePadding + panelSize.width / 2, y: edgePadding + panelSize.height / 2)
        case .bottomRight:
            return CGPoint(x: screen.width - edgePadding - panelSize.width / 2, y: edgePadding + panelSize.height / 2)
        case .topLeft:
            return CGPoint(x: edgePadding + panelSize.width / 2, y: screen.height - edgePadding - panelSize.height / 2)
        case .topRight:
            return CGPoint(x: screen.width - edgePadding - panelSize.width / 2, y: screen.height - edgePadding - panelSize.height / 2)
        case .center:
            return CGPoint(x: screen.midX, y: screen.midY)
        case .menubar:
            return CGPoint(x: screen.midX, y: screen.height - edgePadding - panelSize.height / 2)
        case .horizontal:
            return CGPoint(x: screen.midX, y: edgePadding + panelSize.height / 2)
        case .cursorFollow:
            return smoothedCursorPosition(panelSize: panelSize)
        }
    }

    // MARK: - DisplayLink

    func startDisplayLink(for panel: FloatPanel) {
        if displayLink == nil {
            var link: CVDisplayLink?
            CVDisplayLinkCreateWithActiveCGDisplays(&link)

            guard let displayLink = link else { return }

            let callback: CVDisplayLinkOutputCallback = { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, context) -> CVReturn in
                guard let context = context else { return kCVReturnSuccess }
                let tracker = Unmanaged<CursorTracker>.fromOpaque(context).takeUnretainedValue()

                // Calculate delta time from display link
                let currentTime = CACurrentMediaTime()
                let dt = CGFloat(currentTime - tracker.lastFrameTime)
                tracker.lastFrameTime = currentTime

                // Clamp dt to avoid huge jumps on resume or first frame
                let clampedDt = min(max(dt, 1.0 / 240.0), 1.0 / 30.0)

                // Throttle: only update every (frameSkip + 1) frames
                tracker.frameCounter += 1
                if tracker.frameCounter % (tracker.frameSkip + 1) != 0 {
                    return kCVReturnSuccess
                }

                tracker.updateSmoothing(dt: clampedDt)

                // Update all tracked panels
                DispatchQueue.main.async {
                    for trackedPanel in tracker.trackedPanels {
                        guard trackedPanel.isVisible else { continue }
                        let newOrigin = tracker.smoothedCursorPosition(panelSize: trackedPanel.frame.size)
                        trackedPanel.setFrameOrigin(newOrigin)
                    }
                }

                return kCVReturnSuccess
            }

            CVDisplayLinkSetOutputCallback(displayLink, callback, Unmanaged.passUnretained(self).toOpaque())
            self.displayLink = displayLink
            self.lastFrameTime = CACurrentMediaTime()
        }

        if !trackedPanels.contains(where: { $0 === panel }) {
            trackedPanels.append(panel)
        }

        if let link = displayLink {
            CVDisplayLinkStart(link)
        }
    }

    func stopDisplayLink(for panel: FloatPanel) {
        trackedPanels.removeAll { $0 === panel }

        if trackedPanels.isEmpty {
            stopDisplayLink()
        }
    }

    private func stopDisplayLink() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            displayLink = nil
        }
    }
}
