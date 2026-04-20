import AppKit
import Foundation
import Observation

enum FloaterVisualConstants {
    static let builtInPackID = "builtin"
    static let personalPackID = "personal"
    static let personalPackName = "Personal"
    static let autoAvatarID = "auto"
    static let defaultEffectPresetID = "default"
    static let avatarExtractorScriptPath = "/Users/hiep/Projects/floatify/animate-source/extract_avatar_sprites.py"
}

enum FloaterAvatarImageSource: Hashable {
    case bundledResource(name: String)
    case file(path: String)
}

enum FloaterAvatarSource: Hashable {
    case automatic
    case spriteSheet(imageSource: FloaterAvatarImageSource, metadata: SpriteSheetMetadata, frameDuration: TimeInterval)
    case staticImage(imageSource: FloaterAvatarImageSource)
}

struct FloaterAvatarDefinition: Identifiable, Hashable {
    let id: String
    let displayName: String
    let source: FloaterAvatarSource

    var isAutomatic: Bool {
        if case .automatic = source {
            return true
        }
        return false
    }
}

struct FloaterEffectTuning: Hashable, Codable {
    var showsSheen: Bool?
    var showsParticleTrail: Bool?
    var showsCounterArc: Bool?
    var showsSecondaryOrbit: Bool?
    var glowMultiplier: Double
    var sheenDurationMultiplier: Double
    var orbitDurationMultiplier: Double
    var arcDurationMultiplier: Double
    var pulseDurationMultiplier: Double
    var statusPulseDurationMultiplier: Double
    var completionDurationMultiplier: Double
    var flashIntensityMultiplier: Double
    var extraCompletionRays: Int
    var extraCompletionOrbs: Int

    init(
        showsSheen: Bool? = nil,
        showsParticleTrail: Bool? = nil,
        showsCounterArc: Bool? = nil,
        showsSecondaryOrbit: Bool? = nil,
        glowMultiplier: Double = 1.0,
        sheenDurationMultiplier: Double = 1.0,
        orbitDurationMultiplier: Double = 1.0,
        arcDurationMultiplier: Double = 1.0,
        pulseDurationMultiplier: Double = 1.0,
        statusPulseDurationMultiplier: Double = 1.0,
        completionDurationMultiplier: Double = 1.0,
        flashIntensityMultiplier: Double = 1.0,
        extraCompletionRays: Int = 0,
        extraCompletionOrbs: Int = 0
    ) {
        self.showsSheen = showsSheen
        self.showsParticleTrail = showsParticleTrail
        self.showsCounterArc = showsCounterArc
        self.showsSecondaryOrbit = showsSecondaryOrbit
        self.glowMultiplier = glowMultiplier
        self.sheenDurationMultiplier = sheenDurationMultiplier
        self.orbitDurationMultiplier = orbitDurationMultiplier
        self.arcDurationMultiplier = arcDurationMultiplier
        self.pulseDurationMultiplier = pulseDurationMultiplier
        self.statusPulseDurationMultiplier = statusPulseDurationMultiplier
        self.completionDurationMultiplier = completionDurationMultiplier
        self.flashIntensityMultiplier = flashIntensityMultiplier
        self.extraCompletionRays = extraCompletionRays
        self.extraCompletionOrbs = extraCompletionOrbs
    }

    static let identity = FloaterEffectTuning()
}

struct FloaterEffectPreset: Identifiable, Hashable {
    let id: String
    let displayName: String
    let tuning: FloaterEffectTuning

    static let builtInPresets: [FloaterEffectPreset] = [
        FloaterEffectPreset(
            id: FloaterVisualConstants.defaultEffectPresetID,
            displayName: "Default",
            tuning: .identity
        ),
        FloaterEffectPreset(
            id: "orbit-rush",
            displayName: "Orbit Rush",
            tuning: FloaterEffectTuning(
                showsSheen: true,
                showsParticleTrail: true,
                showsCounterArc: true,
                showsSecondaryOrbit: true,
                glowMultiplier: 1.18,
                sheenDurationMultiplier: 0.82,
                orbitDurationMultiplier: 0.72,
                arcDurationMultiplier: 0.76,
                pulseDurationMultiplier: 0.86,
                statusPulseDurationMultiplier: 0.88,
                completionDurationMultiplier: 0.82,
                flashIntensityMultiplier: 1.20,
                extraCompletionRays: 2,
                extraCompletionOrbs: 1
            )
        ),
        FloaterEffectPreset(
            id: "soft-bloom",
            displayName: "Soft Bloom",
            tuning: FloaterEffectTuning(
                showsParticleTrail: false,
                showsCounterArc: false,
                showsSecondaryOrbit: false,
                glowMultiplier: 0.92,
                sheenDurationMultiplier: 1.24,
                orbitDurationMultiplier: 1.16,
                arcDurationMultiplier: 1.20,
                pulseDurationMultiplier: 1.18,
                statusPulseDurationMultiplier: 1.16,
                completionDurationMultiplier: 1.10,
                flashIntensityMultiplier: 0.84
            )
        )
    ]
}

struct FloaterVisualPack: Identifiable, Hashable {
    let id: String
    let displayName: String
    let avatars: [FloaterAvatarDefinition]
    let effectPresets: [FloaterEffectPreset]
    let defaultAvatarID: String
    let defaultEffectPresetID: String
    let sourceURL: URL?
    let isBuiltIn: Bool
}

struct FloaterResolvedVisualStyle: Hashable {
    let avatar: FloaterAvatarDefinition?
    let effectPreset: FloaterEffectPreset
}

struct FloaterImportedAvatarResult: Hashable {
    let packID: String
    let packName: String
    let avatarID: String
    let avatarName: String
    let frameCount: Int
}

struct FloaterManagedAvatarResult: Hashable {
    let packID: String
    let packName: String
    let avatarID: String?
    let avatarName: String?
}

extension Notification.Name {
    static let floaterVisualCatalogDidChange = Notification.Name("FloaterVisualCatalogDidChange")
}

@Observable
final class FloaterVisualCatalog {
    static let shared = FloaterVisualCatalog()

    @ObservationIgnored private let fileManager = FileManager.default
    @ObservationIgnored private let decoder = JSONDecoder()

    var packs: [FloaterVisualPack] = []
    var lastReloadMessage: String?

    let packsDirectoryURL: URL

    private init() {
        packsDirectoryURL = URL(fileURLWithPath: ("~/.floatify/packs" as NSString).expandingTildeInPath)
        reload()
    }

    var builtInPack: FloaterVisualPack {
        Self.makeBuiltInPack()
    }

    var packsDirectoryPath: String {
        packsDirectoryURL.path
    }

    func reload() {
        do {
            try fileManager.createDirectory(at: packsDirectoryURL, withIntermediateDirectories: true)
        } catch {
            packs = [builtInPack]
            lastReloadMessage = "Failed to create packs folder: \(error.localizedDescription)"
            NotificationCenter.default.post(name: .floaterVisualCatalogDidChange, object: nil)
            return
        }

        var nextPacks: [FloaterVisualPack] = [builtInPack]
        var failures: [String] = []

        let urls = (try? fileManager.contentsOfDirectory(
            at: packsDirectoryURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []

        for url in urls.sorted(by: { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }) {
            guard (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }

            do {
                let pack = try loadPack(from: url)
                nextPacks.append(pack)
            } catch {
                failures.append("\(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        packs = nextPacks

        if failures.isEmpty {
            lastReloadMessage = "Loaded \(max(nextPacks.count - 1, 0)) custom pack(s)."
        } else {
            lastReloadMessage = "Loaded \(max(nextPacks.count - 1, 0)) custom pack(s). Failed: \(failures.joined(separator: "; "))"
        }

        NotificationCenter.default.post(name: .floaterVisualCatalogDidChange, object: nil)
    }

    func revealPacksDirectory() {
        do {
            try fileManager.createDirectory(at: packsDirectoryURL, withIntermediateDirectories: true)
        } catch {
            return
        }

        NSWorkspace.shared.open(packsDirectoryURL)
    }

    func resolvedPack(id: String) -> FloaterVisualPack {
        packs.first(where: { $0.id == id }) ?? builtInPack
    }

    func resolvedAvatar(in packID: String, avatarID: String, seedText: String) -> FloaterAvatarDefinition? {
        let pack = resolvedPack(id: packID)
        let concreteAvatars = pack.avatars.filter { !$0.isAutomatic }

        if !pack.isBuiltIn, concreteAvatars.isEmpty {
            return resolvedAvatar(
                in: FloaterVisualConstants.builtInPackID,
                avatarID: FloaterVisualConstants.autoAvatarID,
                seedText: seedText
            )
        }

        let selected = pack.avatars.first(where: { $0.id == avatarID }) ?? pack.avatars.first(where: { $0.id == pack.defaultAvatarID })

        guard let selected else { return nil }
        guard selected.isAutomatic else { return selected }

        guard !concreteAvatars.isEmpty else { return nil }
        let index = stableSeed(for: seedText) % concreteAvatars.count
        return concreteAvatars[index]
    }

    func resolvedEffectPreset(in packID: String, effectPresetID: String) -> FloaterEffectPreset {
        let pack = resolvedPack(id: packID)
        return pack.effectPresets.first(where: { $0.id == effectPresetID })
            ?? pack.effectPresets.first(where: { $0.id == pack.defaultEffectPresetID })
            ?? FloaterEffectPreset.builtInPresets[0]
    }

    func resolveStyle(packID: String, avatarID: String, effectPresetID: String, seedText: String) -> FloaterResolvedVisualStyle {
        FloaterResolvedVisualStyle(
            avatar: resolvedAvatar(in: packID, avatarID: avatarID, seedText: seedText),
            effectPreset: resolvedEffectPreset(in: packID, effectPresetID: effectPresetID)
        )
    }

    static func importAvatarAsset(
        from imageURL: URL,
        preferredPackID: String,
        preferredPackName: String,
        preferredPackDirectoryURL: URL?,
        preferredPackIsBuiltIn: Bool,
        packsDirectoryURL: URL,
        displayName: String?
    ) throws -> FloaterImportedAvatarResult {
        let fileManager = FileManager.default
        let target = try resolveWritablePackTarget(
            preferredPackID: preferredPackID,
            preferredPackName: preferredPackName,
            preferredPackDirectoryURL: preferredPackDirectoryURL,
            preferredPackIsBuiltIn: preferredPackIsBuiltIn,
            packsDirectoryURL: packsDirectoryURL,
            fileManager: fileManager
        )

        try fileManager.createDirectory(at: target.directoryURL, withIntermediateDirectories: true)

        let baseName = sanitizedAvatarName(
            displayName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? imageURL.deletingPathExtension().lastPathComponent
        )
        let existingIDs = Set(target.manifest.avatars.map(\.id))
        let avatarID = uniqueSlug(base: baseName, existing: existingIDs)

        let originalExtension = imageURL.pathExtension.isEmpty ? "png" : imageURL.pathExtension.lowercased()
        let importsDirectoryURL = target.directoryURL.appendingPathComponent("imports", isDirectory: true)
        let spritesDirectoryURL = target.directoryURL.appendingPathComponent("sprites", isDirectory: true)
        try fileManager.createDirectory(at: importsDirectoryURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: spritesDirectoryURL, withIntermediateDirectories: true)

        let importedSourceURL = importsDirectoryURL.appendingPathComponent("\(avatarID)-source.\(originalExtension)")
        let spriteOutputURL = spritesDirectoryURL.appendingPathComponent("\(avatarID).png")

        try copyImagePreservingContents(from: imageURL, to: importedSourceURL, fileManager: fileManager)
        let extraction = try runAvatarExtractor(inputURL: importedSourceURL, outputURL: spriteOutputURL)

        let frameRects = (0..<extraction.frameCount).map { index in
            PackRectManifest(
                x: CGFloat(index * extraction.cellWidth),
                y: 0,
                width: CGFloat(extraction.cellWidth),
                height: CGFloat(extraction.cellHeight)
            )
        }

        var nextManifest = target.manifest
        nextManifest.avatars.removeAll(where: { $0.id == avatarID })
        nextManifest.avatars.append(
            PackAvatarManifest(
                id: avatarID,
                name: baseName,
                type: .spriteSheet,
                image: "sprites/\(avatarID).png",
                frames: frameRects,
                frameDuration: 0.16
            )
        )

        if nextManifest.defaultAvatarID == FloaterVisualConstants.autoAvatarID, nextManifest.avatars.count == 1 {
            nextManifest.defaultAvatarID = avatarID
        }

        let manifestURL = target.directoryURL.appendingPathComponent("manifest.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(nextManifest).write(to: manifestURL, options: .atomic)

        return FloaterImportedAvatarResult(
            packID: nextManifest.id,
            packName: nextManifest.name,
            avatarID: avatarID,
            avatarName: baseName,
            frameCount: extraction.frameCount
        )
    }

    static func renameAvatarAsset(
        avatarID: String,
        in packDirectoryURL: URL,
        displayName: String
    ) throws -> FloaterManagedAvatarResult {
        let sanitizedName = sanitizedAvatarName(displayName)
        var manifest = try loadPackManifest(from: packDirectoryURL)

        guard let avatarIndex = manifest.avatars.firstIndex(where: { $0.id == avatarID }) else {
            throw AvatarImportError.avatarMissing(avatarID)
        }

        manifest.avatars[avatarIndex].name = sanitizedName
        try writePackManifest(manifest, to: packDirectoryURL)

        return FloaterManagedAvatarResult(
            packID: manifest.id,
            packName: manifest.name,
            avatarID: avatarID,
            avatarName: sanitizedName
        )
    }

    static func deleteAvatarAsset(
        avatarID: String,
        in packDirectoryURL: URL
    ) throws -> FloaterManagedAvatarResult {
        let fileManager = FileManager.default
        var manifest = try loadPackManifest(from: packDirectoryURL)

        guard let avatarIndex = manifest.avatars.firstIndex(where: { $0.id == avatarID }) else {
            throw AvatarImportError.avatarMissing(avatarID)
        }

        let avatar = manifest.avatars.remove(at: avatarIndex)

        if let imagePath = avatar.image?.nilIfEmpty {
            let assetURL = packDirectoryURL.appendingPathComponent(imagePath)
            if fileManager.fileExists(atPath: assetURL.path) {
                try fileManager.removeItem(at: assetURL)
            }
        }

        let importsDirectoryURL = packDirectoryURL.appendingPathComponent("imports", isDirectory: true)
        if let importURLs = try? fileManager.contentsOfDirectory(at: importsDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for importURL in importURLs where importURL.lastPathComponent.hasPrefix("\(avatarID)-source.") {
                try? fileManager.removeItem(at: importURL)
            }
        }

        if manifest.defaultAvatarID == avatarID {
            manifest.defaultAvatarID = manifest.avatars.first?.id ?? FloaterVisualConstants.autoAvatarID
        }

        try writePackManifest(manifest, to: packDirectoryURL)

        return FloaterManagedAvatarResult(
            packID: manifest.id,
            packName: manifest.name,
            avatarID: manifest.avatars.first?.id,
            avatarName: avatar.name
        )
    }

    private func loadPack(from directoryURL: URL) throws -> FloaterVisualPack {
        let manifestURL = directoryURL.appendingPathComponent("manifest.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try decoder.decode(PackManifest.self, from: data)

        let avatars = try resolveAvatars(from: manifest, directoryURL: directoryURL)
        let effectPresets = mergedEffectPresets(manifest.effectPresets?.map { $0.resolved() } ?? [])

        let defaultAvatarID = avatars.contains(where: { $0.id == manifest.defaultAvatarID }) ? manifest.defaultAvatarID : FloaterVisualConstants.autoAvatarID
        let defaultEffectPresetID = effectPresets.contains(where: { $0.id == manifest.defaultEffectPresetID }) ? manifest.defaultEffectPresetID : FloaterVisualConstants.defaultEffectPresetID

        return FloaterVisualPack(
            id: manifest.id,
            displayName: manifest.name,
            avatars: avatars,
            effectPresets: effectPresets,
            defaultAvatarID: defaultAvatarID,
            defaultEffectPresetID: defaultEffectPresetID,
            sourceURL: directoryURL,
            isBuiltIn: false
        )
    }

    private func resolveAvatars(from manifest: PackManifest, directoryURL: URL) throws -> [FloaterAvatarDefinition] {
        var avatars: [FloaterAvatarDefinition] = [
            FloaterAvatarDefinition(
                id: FloaterVisualConstants.autoAvatarID,
                displayName: "Automatic",
                source: .automatic
            )
        ]

        for avatar in manifest.avatars {
            switch avatar.type {
            case .automatic:
                continue
            case .spriteSheet:
                guard let image = avatar.image else {
                    throw PackManifestError.invalidAvatar("Missing image for avatar '\(avatar.id)'")
                }
                guard let frames = avatar.frames, !frames.isEmpty else {
                    throw PackManifestError.invalidAvatar("Missing frames for avatar '\(avatar.id)'")
                }

                let fileURL = directoryURL.appendingPathComponent(image)
                let metadata = SpriteSheetMetadata(frameRects: frames.map(\.cgRect))
                avatars.append(
                    FloaterAvatarDefinition(
                        id: avatar.id,
                        displayName: avatar.name,
                        source: .spriteSheet(
                            imageSource: .file(path: fileURL.path),
                            metadata: metadata,
                            frameDuration: avatar.frameDuration ?? 0.16
                        )
                    )
                )
            case .staticImage:
                guard let image = avatar.image else {
                    throw PackManifestError.invalidAvatar("Missing image for avatar '\(avatar.id)'")
                }
                let fileURL = directoryURL.appendingPathComponent(image)
                avatars.append(
                    FloaterAvatarDefinition(
                        id: avatar.id,
                        displayName: avatar.name,
                        source: .staticImage(imageSource: .file(path: fileURL.path))
                    )
                )
            }
        }

        return avatars
    }

    private static func makeBuiltInPack() -> FloaterVisualPack {
        let bundledSheets = SpriteSheetMetadata.bundledSheetNames()
        let avatars = [
            FloaterAvatarDefinition(
                id: FloaterVisualConstants.autoAvatarID,
                displayName: "Automatic",
                source: .automatic
            )
        ] + bundledSheets.map { sheetName in
            FloaterAvatarDefinition(
                id: slugify(sheetName),
                displayName: sheetName == SpriteSheetMetadata.defaultSheetName ? "Default Sprite" : sheetName,
                source: .spriteSheet(
                    imageSource: .bundledResource(name: sheetName),
                    metadata: SpriteSheetMetadata.forSheet(sheetName),
                    frameDuration: 0.16
                )
            )
        }

        return FloaterVisualPack(
            id: FloaterVisualConstants.builtInPackID,
            displayName: "Built-in",
            avatars: avatars,
            effectPresets: FloaterEffectPreset.builtInPresets,
            defaultAvatarID: FloaterVisualConstants.autoAvatarID,
            defaultEffectPresetID: FloaterVisualConstants.defaultEffectPresetID,
            sourceURL: nil,
            isBuiltIn: true
        )
    }

    private func mergedEffectPresets(_ custom: [FloaterEffectPreset]) -> [FloaterEffectPreset] {
        var byID: [String: FloaterEffectPreset] = [:]
        var order: [String] = []

        for preset in FloaterEffectPreset.builtInPresets + custom {
            if byID[preset.id] == nil {
                order.append(preset.id)
            }
            byID[preset.id] = preset
        }

        return order.compactMap { byID[$0] }
    }

    private func stableSeed(for text: String) -> Int {
        var hash = 5381
        for scalar in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        return abs(hash)
    }

    private static func slugify(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private static func resolveWritablePackTarget(
        preferredPackID: String,
        preferredPackName: String,
        preferredPackDirectoryURL: URL?,
        preferredPackIsBuiltIn: Bool,
        packsDirectoryURL: URL,
        fileManager: FileManager
    ) throws -> WritablePackTarget {
        if !preferredPackIsBuiltIn, let preferredPackDirectoryURL {
            let manifestURL = preferredPackDirectoryURL.appendingPathComponent("manifest.json")
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(PackManifest.self, from: manifestData)
            return WritablePackTarget(directoryURL: preferredPackDirectoryURL, manifest: manifest)
        }

        let personalDirectoryURL = packsDirectoryURL.appendingPathComponent(FloaterVisualConstants.personalPackID, isDirectory: true)
        let personalManifestURL = personalDirectoryURL.appendingPathComponent("manifest.json")
        if fileManager.fileExists(atPath: personalManifestURL.path) {
            let data = try Data(contentsOf: personalManifestURL)
            let manifest = try JSONDecoder().decode(PackManifest.self, from: data)
            return WritablePackTarget(directoryURL: personalDirectoryURL, manifest: manifest)
        }

        return WritablePackTarget(
            directoryURL: personalDirectoryURL,
            manifest: PackManifest(
                id: FloaterVisualConstants.personalPackID,
                name: FloaterVisualConstants.personalPackName,
                defaultAvatarID: FloaterVisualConstants.autoAvatarID,
                defaultEffectPresetID: FloaterVisualConstants.defaultEffectPresetID,
                avatars: [],
                effectPresets: []
            )
        )
    }

    private static func loadPackManifest(from directoryURL: URL) throws -> PackManifest {
        let manifestURL = directoryURL.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        return try JSONDecoder().decode(PackManifest.self, from: manifestData)
    }

    private static func writePackManifest(_ manifest: PackManifest, to directoryURL: URL) throws {
        let manifestURL = directoryURL.appendingPathComponent("manifest.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(manifest).write(to: manifestURL, options: .atomic)
    }

    private static func copyImagePreservingContents(from sourceURL: URL, to destinationURL: URL, fileManager: FileManager) throws {
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    private static func runAvatarExtractor(inputURL: URL, outputURL: URL) throws -> SpriteExtractionInfo {
        let scriptURL = URL(fileURLWithPath: FloaterVisualConstants.avatarExtractorScriptPath)
        guard FileManager.default.fileExists(atPath: scriptURL.path) else {
            throw AvatarImportError.extractorMissing(scriptURL.path)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "python3",
            scriptURL.path,
            inputURL.path,
            "--output",
            outputURL.path
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw AvatarImportError.extractorFailed((stderr.isEmpty ? stdout : stderr).trimmingCharacters(in: .whitespacesAndNewlines))
        }

        guard let metadata = parseExtractionInfo(from: stdout) else {
            throw AvatarImportError.invalidExtractorOutput(stdout.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return metadata
    }

    private static func parseExtractionInfo(from output: String) -> SpriteExtractionInfo? {
        var frameCount: Int?
        var cellWidth: Int?
        var cellHeight: Int?

        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.hasPrefix("Frames: ") {
                frameCount = Int(line.replacingOccurrences(of: "Frames: ", with: ""))
            } else if line.hasPrefix("Cell size: ") {
                let value = line.replacingOccurrences(of: "Cell size: ", with: "")
                let parts = value.split(separator: "x")
                if parts.count == 2 {
                    cellWidth = Int(parts[0])
                    cellHeight = Int(parts[1])
                }
            }
        }

        guard let frameCount, let cellWidth, let cellHeight, frameCount > 0, cellWidth > 0, cellHeight > 0 else {
            return nil
        }

        return SpriteExtractionInfo(frameCount: frameCount, cellWidth: cellWidth, cellHeight: cellHeight)
    }

    private static func sanitizedAvatarName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .nilIfEmpty ?? "Imported Avatar"
    }

    private static func uniqueSlug(base: String, existing: Set<String>) -> String {
        let normalizedBase = slugify(base).nilIfEmpty ?? "avatar"
        guard existing.contains(normalizedBase) else { return normalizedBase }

        var index = 2
        while existing.contains("\(normalizedBase)-\(index)") {
            index += 1
        }
        return "\(normalizedBase)-\(index)"
    }
}

private enum PackManifestError: LocalizedError {
    case invalidAvatar(String)

    var errorDescription: String? {
        switch self {
        case let .invalidAvatar(message):
            return message
        }
    }
}

private struct PackManifest: Codable {
    let id: String
    let name: String
    var defaultAvatarID: String
    var defaultEffectPresetID: String
    var avatars: [PackAvatarManifest]
    var effectPresets: [PackEffectPresetManifest]?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case defaultAvatarID
        case defaultEffectPresetID
        case avatars
        case effectPresets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        defaultAvatarID = try container.decodeIfPresent(String.self, forKey: .defaultAvatarID) ?? FloaterVisualConstants.autoAvatarID
        defaultEffectPresetID = try container.decodeIfPresent(String.self, forKey: .defaultEffectPresetID) ?? FloaterVisualConstants.defaultEffectPresetID
        avatars = try container.decodeIfPresent([PackAvatarManifest].self, forKey: .avatars) ?? []
        effectPresets = try container.decodeIfPresent([PackEffectPresetManifest].self, forKey: .effectPresets)
    }

    init(
        id: String,
        name: String,
        defaultAvatarID: String,
        defaultEffectPresetID: String,
        avatars: [PackAvatarManifest],
        effectPresets: [PackEffectPresetManifest]?
    ) {
        self.id = id
        self.name = name
        self.defaultAvatarID = defaultAvatarID
        self.defaultEffectPresetID = defaultEffectPresetID
        self.avatars = avatars
        self.effectPresets = effectPresets
    }
}

private struct PackAvatarManifest: Codable {
    enum AvatarType: String, Codable {
        case automatic
        case spriteSheet
        case staticImage
    }

    var id: String
    var name: String
    var type: AvatarType
    var image: String?
    var frames: [PackRectManifest]?
    var frameDuration: TimeInterval?
}

private struct PackRectManifest: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

private struct PackEffectPresetManifest: Codable {
    var id: String
    var name: String
    var showsSheen: Bool?
    var showsParticleTrail: Bool?
    var showsCounterArc: Bool?
    var showsSecondaryOrbit: Bool?
    var glowMultiplier: Double?
    var sheenDurationMultiplier: Double?
    var orbitDurationMultiplier: Double?
    var arcDurationMultiplier: Double?
    var pulseDurationMultiplier: Double?
    var statusPulseDurationMultiplier: Double?
    var completionDurationMultiplier: Double?
    var flashIntensityMultiplier: Double?
    var extraCompletionRays: Int?
    var extraCompletionOrbs: Int?

    func resolved() -> FloaterEffectPreset {
        FloaterEffectPreset(
            id: id,
            displayName: name,
            tuning: FloaterEffectTuning(
                showsSheen: showsSheen,
                showsParticleTrail: showsParticleTrail,
                showsCounterArc: showsCounterArc,
                showsSecondaryOrbit: showsSecondaryOrbit,
                glowMultiplier: glowMultiplier ?? 1.0,
                sheenDurationMultiplier: sheenDurationMultiplier ?? 1.0,
                orbitDurationMultiplier: orbitDurationMultiplier ?? 1.0,
                arcDurationMultiplier: arcDurationMultiplier ?? 1.0,
                pulseDurationMultiplier: pulseDurationMultiplier ?? 1.0,
                statusPulseDurationMultiplier: statusPulseDurationMultiplier ?? 1.0,
                completionDurationMultiplier: completionDurationMultiplier ?? 1.0,
                flashIntensityMultiplier: flashIntensityMultiplier ?? 1.0,
                extraCompletionRays: extraCompletionRays ?? 0,
                extraCompletionOrbs: extraCompletionOrbs ?? 0
            )
        )
    }
}

private struct WritablePackTarget {
    let directoryURL: URL
    let manifest: PackManifest
}

private struct SpriteExtractionInfo {
    let frameCount: Int
    let cellWidth: Int
    let cellHeight: Int
}

private enum AvatarImportError: LocalizedError {
    case extractorMissing(String)
    case extractorFailed(String)
    case invalidExtractorOutput(String)
    case avatarMissing(String)

    var errorDescription: String? {
        switch self {
        case let .extractorMissing(path):
            return "Extractor script not found at \(path)"
        case let .extractorFailed(message):
            return message.isEmpty ? "Sprite extraction failed." : message
        case let .invalidExtractorOutput(output):
            return output.isEmpty ? "Sprite extractor returned invalid output." : output
        case let .avatarMissing(avatarID):
            return "Avatar '\(avatarID)' was not found in this pack."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
