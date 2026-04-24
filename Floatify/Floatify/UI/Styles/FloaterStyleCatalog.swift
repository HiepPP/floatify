import AppKit
import Foundation
import Observation

extension Notification.Name {
    static let floaterStyleCatalogDidChange = Notification.Name("FloaterStyleCatalogDidChange")
}

@Observable
final class FloaterStyleCatalog {
    static let shared = FloaterStyleCatalog()

    @ObservationIgnored private let fileManager = FileManager.default
    @ObservationIgnored private let decoder = JSONDecoder()

    var presets: [FloaterStylePreset] = []
    var lastReloadMessage: String?

    let stylesDirectoryURL: URL

    private init() {
        stylesDirectoryURL = URL(fileURLWithPath: ("~/.floatify/styles" as NSString).expandingTildeInPath)
        reload()
    }

    var stylesDirectoryPath: String {
        stylesDirectoryURL.path
    }

    var currentPreset: FloaterStylePreset {
        let selectedID = UserDefaults.standard.string(forKey: FloatifySettings.Key.selectedFloaterStyleID)
            ?? FloaterStyleConstants.defaultStyleID
        return resolvedPreset(id: selectedID)
    }

    func reload() {
        var nextPresets = loadBundledPresets()
        var failures: [String] = []

        do {
            try fileManager.createDirectory(at: stylesDirectoryURL, withIntermediateDirectories: true)
        } catch {
            presets = nextPresets
            lastReloadMessage = "Failed to create styles folder: \(error.localizedDescription)"
            NotificationCenter.default.post(name: .floaterStyleCatalogDidChange, object: nil)
            return
        }

        let urls = (try? fileManager.contentsOfDirectory(
            at: stylesDirectoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for url in urls.sorted(by: { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }) {
            guard url.pathExtension.lowercased() == "json" else { continue }

            do {
                let preset = try loadPreset(from: url)
                nextPresets.append(preset)
            } catch {
                failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        presets = mergedPresets(nextPresets)

        if failures.isEmpty {
            lastReloadMessage = "Loaded \(max(presets.count - FloaterStyleConstants.bundledStylePresetNames.count, 0)) custom style(s)."
        } else {
            lastReloadMessage = "Loaded styles. Failed: \(failures.joined(separator: "; "))"
        }

        NotificationCenter.default.post(name: .floaterStyleCatalogDidChange, object: nil)
    }

    func revealStylesDirectory() {
        do {
            try fileManager.createDirectory(at: stylesDirectoryURL, withIntermediateDirectories: true)
        } catch {
            return
        }

        NSWorkspace.shared.open(stylesDirectoryURL)
    }

    func resolvedPreset(id: String) -> FloaterStylePreset {
        presets.first(where: { $0.id == id })
            ?? presets.first(where: { $0.id == FloaterStyleConstants.defaultStyleID })
            ?? .defaultPreset
    }

    private func loadBundledPresets() -> [FloaterStylePreset] {
        var results: [FloaterStylePreset] = []

        for name in FloaterStyleConstants.bundledStylePresetNames {
            guard let url = bundledPresetURL(named: name) else {
                if name == FloaterStyleConstants.defaultStyleID {
                    results.append(.defaultPreset)
                }
                continue
            }

            do {
                results.append(try loadPreset(from: url))
            } catch {
                if name == FloaterStyleConstants.defaultStyleID {
                    results.append(.defaultPreset)
                }
            }
        }

        if !results.contains(where: { $0.id == FloaterStyleConstants.defaultStyleID }) {
            results.insert(.defaultPreset, at: 0)
        }

        return mergedPresets(results)
    }

    private func bundledPresetURL(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "json", subdirectory: "StylePresets")
            ?? Bundle.main.url(forResource: name, withExtension: "json")
    }

    private func loadPreset(from url: URL) throws -> FloaterStylePreset {
        let data = try Data(contentsOf: url)
        return try decoder.decode(FloaterStylePreset.self, from: data)
    }

    private func mergedPresets(_ values: [FloaterStylePreset]) -> [FloaterStylePreset] {
        var byID: [String: FloaterStylePreset] = [:]
        var order: [String] = []

        for preset in values {
            if byID[preset.id] == nil {
                order.append(preset.id)
            }
            byID[preset.id] = preset
        }

        return order.compactMap { byID[$0] }
    }
}
