# Settings Display Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native macOS Settings window (Cmd+,) that lets users choose floater display style with live animated updates.

**Architecture:** Replace main.swift with SwiftUI App lifecycle (FloatifyApp.swift) to enable SettingsScene. Create SettingsView with @AppStorage picker. FloatNotificationManager observes UserDefaults changes and refreshes floaters with animation.

**Tech Stack:** SwiftUI, AppKit, UserDefaults, NotificationCenter

---

### Task 1: Create FloatifyApp.swift with SettingsScene

**Files:**
- Create: `Floatify/Floatify/FloatifyApp.swift`
- Modify: `Floatify/project.yml` (add file to target)

- [ ] **Step 1: Create FloatifyApp.swift**

```swift
import SwiftUI

@main
struct FloatifyApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .onAppear {
                    // Hide the empty window immediately
                    if let window = NSApplication.shared.windows.first {
                        window.close()
                    }
                }
        }
        .defaultSize(width: 0, height: 0)
        .windowStyle(.hiddenTitleBar)
        .commands {
            // Remove "New Window" and other unnecessary commands
            CommandGroup(replacing: .newItem) {}
        }

        Settings {
            SettingsView()
        }
    }
}
```

- [ ] **Step 2: Add FloatifyApp.swift to project.yml**

Find the `sources` section in `Floatify/project.yml` under the `Floatify` target and add `FloatifyApp.swift`.

Read the current project.yml first to find the exact format.

- [ ] **Step 3: Build the app to verify no compile errors**

Run:
```bash
cd Floatify && xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Floatify/Floatify/FloatifyApp.swift Floatify/project.yml
git commit -m "feat: add SwiftUI App entry point with SettingsScene"
```

---

### Task 2: Create SettingsView.swift

**Files:**
- Create: `Floatify/Floatify/SettingsView.swift`
- Modify: `Floatify/project.yml` (add file to target)

- [ ] **Step 1: Create SettingsView.swift**

```swift
import SwiftUI

struct SettingsView: View {
    @AppStorage("FloaterSize") private var floaterSize: String = "regular"

    var body: some View {
        Form {
            Section {
                Picker("Display Style", selection: $floaterSize) {
                    Text("Compact").tag("compact")
                    Text("Regular").tag("regular")
                    Text("Large").tag("large")
                }
                .pickerStyle(.inline)
            } header: {
                Text("Floater Appearance")
            } footer: {
                Text("Changes apply immediately to all visible floaters.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 320)
        .padding()
    }
}

#Preview {
    SettingsView()
}
```

- [ ] **Step 2: Add SettingsView.swift to project.yml**

Same as Task 1 Step 2 - find the `sources` section and add `SettingsView.swift`.

- [ ] **Step 3: Build the app to verify no compile errors**

Run:
```bash
cd Floatify && xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Floatify/Floatify/SettingsView.swift Floatify/project.yml
git commit -m "feat: add SettingsView with display style picker"
```

---

### Task 3: Remove main.swift

**Files:**
- Delete: `Floatify/Floatify/main.swift`
- Modify: `Floatify/project.yml` (remove file from target)

- [ ] **Step 1: Read main.swift to confirm it only contains NSApplicationMain**

```bash
cat Floatify/Floatify/main.swift
```

Expected: Contains `NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)` or similar minimal entry point.

- [ ] **Step 2: Delete main.swift**

```bash
rm Floatify/Floatify/main.swift
git add -A Floatify/Floatify/main.swift
```

- [ ] **Step 3: Remove main.swift from project.yml**

Edit `Floatify/project.yml` to remove `main.swift` from the sources list.

- [ ] **Step 4: Build the app to verify entry point works**

Run:
```bash
cd Floatify && xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add Floatify/project.yml
git commit -m "refactor: remove main.swift, use SwiftUI App lifecycle"
```

---

### Task 4: Add UserDefaults observation to FloatNotificationManager

**Files:**
- Modify: `Floatify/Floatify/FloatNotificationManager.swift`

- [ ] **Step 1: Add properties for tracking size changes**

In `FloatNotificationManager` class, add these properties after existing private properties (around line 88):

```swift
    private var defaultsObserver: NSObjectProtocol?
    private var lastFloaterSizeRaw: String = "regular"
```

- [ ] **Step 2: Add floaterSize computed property**

Replace the existing `floaterSizeFromDefaults()` function (lines 302-309) with:

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
```

- [ ] **Step 3: Add UserDefaults observation in init()**

In the `init()` method (around line 89), add after `isFloaterPanelCollapsed = false`:

```swift
    private init() {
        isFloaterPanelCollapsed = false
        lastFloaterSizeRaw = UserDefaults.standard.string(forKey: "FloaterSize") ?? "regular"

        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDefaultsChange()
        }
    }
```

- [ ] **Step 4: Add handleDefaultsChange method**

Add this method after the `init()` method:

```swift
    private func handleDefaultsChange() {
        let newSize = floaterSizeRaw
        guard newSize != lastFloaterSizeRaw else { return }
        lastFloaterSizeRaw = newSize
        refreshFloaterPanel(animated: true)
    }
```

- [ ] **Step 5: Update refreshFloaterPanel to accept animated parameter**

Modify the `refreshFloaterPanel` method signature (line 202) to accept an animated parameter:

```swift
    private func refreshFloaterPanel(animatedItemIDs: Set<String> = [], animated: Bool = false) {
```

Then modify the resize call inside (around line 225-227) to pass the animated flag:

```swift
        if let panel = floaterPanel {
            resizeFloaterPanel(panel, to: size, animated: animated)
            panel.orderFrontRegardless()
            return
        }
```

- [ ] **Step 6: Update resizeFloaterPanel to accept animated parameter**

Modify `resizeFloaterPanel` method (line 426) signature:

```swift
    private func resizeFloaterPanel(_ panel: FloatPanel, to size: CGSize, animated: Bool = false) {
```

The existing animation logic in `resizeFloaterPanel` should already work. Just ensure the method can handle both animated and non-animated cases. The existing code uses `NSAnimationContext` which handles the animation - we just need to make sure existing callers (which don't pass `animated`) continue to work with the default `false` value.

Current code at line 426-443:
```swift
    private func resizeFloaterPanel(_ panel: FloatPanel, to size: CGSize) {
        let origin = clampedFloaterPanelOrigin(
            CGPoint(x: panel.frame.maxX - size.width, y: panel.frame.minY),
            size: size
        )
        let frame = NSRect(origin: origin, size: size)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = floaterPanelAnimationDuration
            context.allowsImplicitAnimation = true
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 0.0, 0.30, 1.0)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            panel.setFrame(frame, display: true)
        }

        saveFloaterPanelOrigin(origin)
    }
```

Change to:
```swift
    private func resizeFloaterPanel(_ panel: FloatPanel, to size: CGSize, animated: Bool = false) {
        let origin = clampedFloaterPanelOrigin(
            CGPoint(x: panel.frame.maxX - size.width, y: panel.frame.minY),
            size: size
        )
        let frame = NSRect(origin: origin, size: size)

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = floaterPanelAnimationDuration
                context.allowsImplicitAnimation = true
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 0.0, 0.30, 1.0)
                panel.animator().setFrame(frame, display: true)
            } completionHandler: {
                panel.setFrame(frame, display: true)
            }
        } else {
            panel.setFrame(frame, display: true)
        }

        saveFloaterPanelOrigin(origin)
    }
```

- [ ] **Step 7: Update floaterSizeFromDefaults usage**

Find all calls to `floaterSizeFromDefaults()` and replace with `floaterSize` property access.

In `refreshFloaterPanel` (around line 209-218), the `FloaterPanelItem` uses `floaterSizeFromDefaults()`. Change it to:

```swift
        let floaterItems = items.map { item in
            let style = statusStyle(for: item.id)
            return FloaterPanelItem(
                item: item,
                dismissController: floaterDismissController(for: item.id),
                playsEntryAnimation: animatedItemIDs.contains(item.id),
                effect: style.effect,
                spriteCharacter: style.spriteCharacter,
                floaterSize: floaterSize
            )
        }
```

- [ ] **Step 8: Build the app to verify no compile errors**

Run:
```bash
cd Floatify && xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Expected: BUILD SUCCEEDED

- [ ] **Step 9: Commit**

```bash
git add Floatify/Floatify/FloatNotificationManager.swift
git commit -m "feat: add UserDefaults observation for live floater size updates"
```

---

### Task 5: Add Settings menu item to menu bar (Optional but recommended)

**Files:**
- Modify: `Floatify/Floatify/AppDelegate.swift`

- [ ] **Step 1: Add openSettings action to AppDelegate**

Add this method after the `arrangeFloaters()` method (around line 361):

```swift
    @objc private func openSettings() {
        if #available(macOS 13, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
```

- [ ] **Step 2: Add Settings menu item**

In `setupStatusItem()` (around line 341-350), add a Settings item before the separator:

```swift
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🦆"
        }

        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let testItem = NSMenuItem(title: "Test Notification", action: #selector(testNotification), keyEquivalent: "")
        testItem.target = self
        menu.addItem(testItem)

        let arrangeItem = NSMenuItem(title: "Arrange", action: #selector(arrangeFloaters), keyEquivalent: "")
        arrangeItem.target = self
        menu.addItem(arrangeItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Floatify", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }
```

- [ ] **Step 3: Build the app to verify no compile errors**

Run:
```bash
cd Floatify && xcodebuild -project Floatify.xcodeproj -scheme Floatify -configuration Debug build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Floatify/Floatify/AppDelegate.swift
git commit -m "feat: add Settings menu item to menu bar"
```

---

### Task 6: Test the feature

**Files:**
- None (manual testing)

- [ ] **Step 1: Kill any running Floatify processes**

```bash
pkill -f Floatify || true
```

- [ ] **Step 2: Run the fresh build**

Locate the built app in DerivedData and run it, or use:

```bash
open Floatify/build/Debug/Floatify.app 2>/dev/null || \
find ~/Library/Developer/Xcode/DerivedData -name "Floatify.app" -type d 2>/dev/null | head -1 | xargs open
```

- [ ] **Step 3: Test Settings window opens with Cmd+,**

- Press Cmd+, (or go to menu bar → Settings...)
- Verify Settings window appears
- Verify current size is selected in picker

- [ ] **Step 4: Test live update**

- Have Claude Code or Codex running so floaters are visible
- Change the display style in Settings
- Verify floaters animate to new size immediately

- [ ] **Step 5: Test persistence**

- Quit Floatify (Cmd+Q or menu bar → Quit)
- Relaunch the app
- Verify the setting persists (Settings shows the selected size, floaters use that size)

---

## Testing Checklist

- [ ] Settings window opens with Cmd+,
- [ ] Picker shows current size as selected
- [ ] Selecting different size updates floaters immediately
- [ ] Animation is smooth (spring physics)
- [ ] Setting persists after app restart
- [ ] Compact shows smaller panels
- [ ] Large shows bigger panels
- [ ] No impact on temporary notifications
