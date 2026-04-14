# Settings: Display Style Feature Design

Date: 2026-04-14

## Summary

Add a Settings window to Floatify that allows users to choose floater display style (Compact, Regular, Large). Changes apply immediately to all visible floaters with animation.

## Requirements

- Native macOS Settings window (Cmd+, shortcut)
- Display style options: Compact, Regular, Large
- Live update: animated refresh when setting changes
- Persist preference across app launches

## Architecture

```
main.swift → FloatifyApp.swift (SwiftUI App)
            ├── WindowGroup (empty - headless app)
            └── SettingsScene → SettingsView
                                └── FloaterSizePicker

AppDelegate (NSApplicationDelegate)
├── Pipe IPC listener
├── Session monitors (Claude/Codex)
└── Menu bar status item

FloatNotificationManager (class)
└── UserDefaults observation → floaterSize
    └── notification callback → refreshFloaterPanel(animated: true)
```

## Components

### New Files

#### FloatifyApp.swift

SwiftUI App entry point replacing main.swift.

```swift
@main
struct FloatifyApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        // Empty WindowGroup - headless menu bar app
        WindowGroup {
            EmptyView()
        }

        Settings {
            SettingsView()
        }
    }
}
```

#### SettingsView.swift

Settings window content with display style picker.

```swift
struct SettingsView: View {
    @AppStorage("FloaterSize") private var floaterSize: String = "regular"

    var body: some View {
        Form {
            Picker("Display Style", selection: $floaterSize) {
                Text("Compact").tag("compact")
                Text("Regular").tag("regular")
                Text("Large").tag("large")
            }
            .pickerStyle(.inline)
        }
        .frame(width: 300)
        .padding()
    }
}
```

### Modified Files

#### main.swift

Remove or replace. The app entry point moves to `FloatifyApp.swift` with `@main` attribute.

Option: Keep main.swift as empty file for build compatibility, or delete entirely.

#### FloatNotificationManager.swift

Add UserDefaults observation to react to setting changes.

Current code:
```swift
private func floaterSizeFromDefaults() -> FloaterSize {
    let sizeString = UserDefaults.standard.string(forKey: "FloaterSize") ?? "regular"
    switch sizeString {
    case "compact": return .compact
    case "large": return .large
    default: return .regular
    }
}
```

New code:
```swift
private var floaterSizeRaw: String {
    UserDefaults.standard.string(forKey: "FloaterSize") ?? "regular"
}

private var floaterSize: FloaterSize {
    switch floaterSizeRaw {
    case "compact": return .compact
    case "large": return .large
    default: return .regular
    }
}

private var defaultsObserver: NSObjectProtocol?
private var lastFloaterSizeRaw: String = "regular"

// In init():
defaultsObserver = NotificationCenter.default.addObserver(
    forName: UserDefaults.didChangeNotification,
    object: nil,
    queue: .main
) { [weak self] _ in
    self?.handleDefaultsChange()
}

private func handleDefaultsChange() {
    let newSize = floaterSizeRaw
    guard newSize != lastFloaterSizeRaw else { return }
    lastFloaterSizeRaw = newSize
    refreshFloaterPanel(animated: true)
}
```

The key is observing `UserDefaults.didChangeNotification` and refreshing floaters only when the size actually changes.

#### AppDelegate.swift

No significant changes. Keep existing:
- `setupStatusItem()` - menu bar with duck emoji
- `setupPipeListener()` - FIFO IPC
- `setupPersistentStatusFloater()` - session monitors

The menu bar menu could optionally add a "Settings..." item that opens the settings window:
```swift
let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
settingsItem.target = self
menu.insertItem(settingsItem, at: 0)
```

## Data Flow

1. User opens Settings (Cmd+, or menu bar → Settings...)
2. SettingsView displays current `FloaterSize` value from `@AppStorage`
3. User selects different size
4. `@AppStorage` writes to UserDefaults
5. `UserDefaults.didChangeNotification` fires
6. `FloatNotificationManager` receives notification
7. Manager checks if size changed, calls `refreshFloaterPanel(animated: true)`
8. All floaters re-render with new size using existing spring animation

## Animation

Use existing animation constants in `FloatNotificationManager`:
- `floaterPanelAnimationDuration: TimeInterval = 0.38`
- `floaterPanelSpringDamping: CGFloat = 0.82`
- `floaterPanelSpringVelocity: CGFloat = 0.45`

The `resizeFloaterPanel(_:to:)` method already uses these for smooth resize.

## Implementation Steps

1. Create `FloatifyApp.swift` with `@main` and `SettingsScene`
2. Create `SettingsView.swift` with FloaterSize picker
3. Remove `main.swift` or leave empty
4. Update `FloatNotificationManager`:
   - Add UserDefaults observation in init()
   - Track lastFloaterSizeRaw to detect actual changes
   - Call refreshFloaterPanel(animated: true) on change
5. Optionally add "Settings..." menu item to menu bar
6. Test: change setting, verify floaters animate to new size

## Testing Checklist

- [ ] Settings window opens with Cmd+,
- [ ] Picker shows current size as selected
- [ ] Selecting different size updates floaters immediately
- [ ] Animation is smooth (spring physics)
- [ ] Setting persists after app restart
- [ ] Compact shows smaller panels
- [ ] Large shows bigger panels
- [ ] No impact on temporary notifications (they use their own sizing)

## Out of Scope

- Custom animation timing configuration
- Additional settings beyond display style
- Float vs non-float window behavior
- Per-session display styles
