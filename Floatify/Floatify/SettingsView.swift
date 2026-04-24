import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case appearance
    case avatars
    case hooks
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .avatars: return "Avatars"
        case .hooks: return "Hooks & CLI"
        case .general: return "General"
        }
    }

    var systemImage: String {
        switch self {
        case .appearance: return "paintbrush.fill"
        case .avatars: return "person.crop.square.fill"
        case .hooks: return "terminal.fill"
        case .general: return "gearshape.fill"
        }
    }
}

struct SettingsView: View {
    @Environment(FloatifySettings.self) private var settings
    @Environment(FloaterVisualCatalog.self) private var visualCatalog
    @Environment(FloaterStyleCatalog.self) private var styleCatalog

    @State private var selection: SettingsTab = .appearance
    @State private var health = SettingsHealthModel()

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selection) { tab in
                NavigationLink(value: tab) {
                    Label(tab.title, systemImage: tab.systemImage)
                        .labelStyle(.titleAndIcon)
                        .padding(.vertical, 2)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            Group {
                switch selection {
                case .appearance:
                    AppearanceTab()
                case .avatars:
                    AvatarsTab()
                case .hooks:
                    HooksCLITab()
                case .general:
                    GeneralTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationSplitViewColumnWidth(min: 480, ideal: 520)
        }
        .frame(minWidth: 720, minHeight: 520)
        .environment(health)
        .onAppear {
            settings.normalizeVisualSelection(catalog: visualCatalog)
            settings.normalizeStyleSelection(catalog: styleCatalog)
        }
    }
}

#Preview {
    SettingsView()
        .environment(FloatifySettings.shared)
        .environment(FloaterVisualCatalog.shared)
        .environment(FloaterStyleCatalog.shared)
}
