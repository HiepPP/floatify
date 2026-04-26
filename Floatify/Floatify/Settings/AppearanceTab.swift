import SwiftUI

struct AppearanceTab: View {
    @Environment(FloatifySettings.self) private var settings
    @Environment(FloaterStyleCatalog.self) private var styleCatalog

    @State private var message = ""
    @State private var messageLevel: SetupHealthLevel = .good

    var body: some View {
        @Bindable var settings = settings

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TabHeader(
                    title: "Appearance",
                    subtitle: "Theme, size, render mode, and header display.",
                    symbol: "paintbrush.fill"
                )

                Form {
                    Section {
                        SettingRow("Theme", subtitle: "Pick a visual preset for floaters.") {
                            Picker(
                                "Theme",
                                selection: Binding(
                                    get: { settings.selectedFloaterStyleID },
                                    set: { settings.selectFloaterStyle($0, catalog: styleCatalog) }
                                )
                            ) {
                                ForEach(styleCatalog.presets, id: \.id) { preset in
                                    Text(preset.displayName).tag(preset.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        SettingRow("Header CPU", subtitle: "Show CPU usage in the floater bar.") {
                            Picker("Header CPU", selection: $settings.floaterHeaderCPUDisplay) {
                                ForEach(FloaterHeaderCPUDisplay.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    } header: {
                        SectionHeader("Theme")
                    }

                    Section {
                        Picker("Display style", selection: $settings.floaterSize) {
                            ForEach(FloaterSize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        SectionHeader("Display Style")
                    } footer: {
                        Text("Choose the floater footprint. Smaller sizes save screen space.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Picker("Render mode", selection: $settings.floaterRenderMode) {
                            ForEach(FloaterRenderMode.allCases, id: \.self) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Toggle("Limit running effects when many floaters are active", isOn: $settings.limitRunningRenderEffects)
                    } header: {
                        SectionHeader("Render Mode")
                    } footer: {
                        Text("Slay keeps full effects. Super Slay pushes extra effects for high-end machines. Lame removes heavy repeat effects for the lowest CPU.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        HStack(spacing: 10) {
                            Button {
                                styleCatalog.revealStylesDirectory()
                                setMessage("Opened \(styleCatalog.stylesDirectoryPath).", level: .good)
                            } label: {
                                Label("Reveal Folder", systemImage: "folder")
                            }

                            Button {
                                styleCatalog.reload()
                                settings.normalizeStyleSelection(catalog: styleCatalog)
                                setMessage(styleCatalog.lastReloadMessage ?? "Reloaded style presets.", level: .good)
                            } label: {
                                Label("Reload", systemImage: "arrow.clockwise")
                            }

                            Spacer()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)

                        InlineMessage(message: message, level: messageLevel)
                            .task(id: message) {
                                guard !message.isEmpty else { return }
                                try? await Task.sleep(nanoseconds: 4_000_000_000)
                                withAnimation { message = "" }
                            }
                    } header: {
                        SectionHeader("Style Presets")
                    } footer: {
                        Text("Drop custom theme presets into the styles folder and click Reload.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
            .padding(24)
        }
    }

    private func setMessage(_ text: String, level: SetupHealthLevel) {
        withAnimation { message = text; messageLevel = level }
    }
}

struct SectionHeader: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .textCase(nil)
    }
}
