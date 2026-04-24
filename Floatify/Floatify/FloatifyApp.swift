import AppKit
import ImageIO
import SwiftUI

@main
struct FloatifyApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    private let settings = FloatifySettings.shared
    private let visualCatalog = FloaterVisualCatalog.shared
    private let styleCatalog = FloaterStyleCatalog.shared

    var body: some Scene {
        MenuBarExtra {
            FloatifyMenuBarContent()
        } label: {
            MenuBarAvatarIcon()
        }

        Settings {
            SettingsView()
                .environment(settings)
                .environment(visualCatalog)
                .environment(styleCatalog)
        }
    }
}

private struct MenuBarAvatarIcon: View {
    private static let iconImage = makeIconImage()
    private static let canvasSize = CGSize(width: 18, height: 18)

    var body: some View {
        Group {
            if let image = Self.iconImage {
                Image(nsImage: image)
                    .renderingMode(.original)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
            } else {
                Text("🦆")
            }
        }
    }

    private static func makeIconImage() -> NSImage? {
        let source = FloaterAvatarImageSource.bundledResource(name: SpriteSheetMetadata.defaultSheetName)
        guard let url = bundledURL(for: source),
              let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let sheet = CGImageSourceCreateImageAtIndex(imageSource, 0, nil),
              let firstFrame = SpriteSheetMetadata.defaultMetadata.frameRects.first,
              let cropped = sheet.cropping(to: firstFrame) else {
            return nil
        }

        let spriteImage = NSImage(cgImage: cropped, size: firstFrame.size)
        let canvasImage = NSImage(size: canvasSize)
        canvasImage.lockFocus()
        defer { canvasImage.unlockFocus() }

        NSGraphicsContext.current?.imageInterpolation = .none

        let drawSize = CGSize(width: 16, height: 16)
        let drawOrigin = CGPoint(
            x: (canvasSize.width - drawSize.width) / 2,
            y: (canvasSize.height - drawSize.height) / 2
        )
        spriteImage.draw(in: CGRect(origin: drawOrigin, size: drawSize))

        return canvasImage
    }

    private static func bundledURL(for source: FloaterAvatarImageSource) -> URL? {
        switch source {
        case let .bundledResource(name):
            return Bundle.main.url(forResource: name, withExtension: "png")
        case let .file(path):
            return URL(fileURLWithPath: path)
        }
    }
}

private struct FloatifyMenuBarContent: View {
    var body: some View {
        Button("Settings...") {
            FloatifySettingsWindowPresenter.shared.show()
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Arrange") {
            FloaterPanelManager.shared.arrangePersistentStatuses()
        }

        Divider()

        Button("Quit Floatify") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}

final class FloatifySettingsWindowPresenter {
    static let shared = FloatifySettingsWindowPresenter()

    private var window: NSWindow?
    private let settings = FloatifySettings.shared
    private let visualCatalog = FloaterVisualCatalog.shared
    private let styleCatalog = FloaterStyleCatalog.shared

    private init() {}

    func show() {
        let settingsWindow = window ?? makeWindow()
        window = settingsWindow
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.orderFrontRegardless()
    }

    private func makeWindow() -> NSWindow {
        let contentView = SettingsView()
            .environment(settings)
            .environment(visualCatalog)
            .environment(styleCatalog)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Floatify Settings"
        window.contentView = NSHostingView(rootView: contentView)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.level = .floating
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}
