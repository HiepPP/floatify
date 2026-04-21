import AppKit
import Foundation
import ImageIO
import Observation

enum FloaterVisualConstants {
    static let builtInPackID = "builtin"
    static let personalPackID = "personal"
    static let personalPackName = "Personal"
    static let autoAvatarID = "auto"
    static let defaultEffectPresetID = "default"
    static let avatarImportBackgroundTolerance = 12
    static let avatarImportPadding = 8
}

enum FloaterAvatarImageSource: Hashable {
    case bundledResource(name: String)
    case file(path: String)
}

enum FloaterAvatarOrientation: String, Codable, Hashable, CaseIterable {
    case upright
    case flipVertical
    case flipHorizontal
    case rotate180

    var displayName: String {
        switch self {
        case .upright:
            return "Normal"
        case .flipVertical:
            return "Flip Vertical"
        case .flipHorizontal:
            return "Flip Horizontal"
        case .rotate180:
            return "Rotate 180"
        }
    }
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
    let orientation: FloaterAvatarOrientation

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
                frameDuration: 0.16,
                orientation: .upright
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

    static func updateAvatarAsset(
        avatarID: String,
        in packDirectoryURL: URL,
        displayName: String,
        orientation: FloaterAvatarOrientation
    ) throws -> FloaterManagedAvatarResult {
        let sanitizedName = sanitizedAvatarName(displayName)
        var manifest = try loadPackManifest(from: packDirectoryURL)

        guard let avatarIndex = manifest.avatars.firstIndex(where: { $0.id == avatarID }) else {
            throw AvatarImportError.avatarMissing(avatarID)
        }

        manifest.avatars[avatarIndex].name = sanitizedName
        manifest.avatars[avatarIndex].orientation = orientation
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
                source: .automatic,
                orientation: .upright
            )
        ]

        for avatar in manifest.avatars {
            let orientation = avatar.orientation ?? .upright
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
                        ),
                        orientation: orientation
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
                        source: .staticImage(imageSource: .file(path: fileURL.path)),
                        orientation: orientation
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
                source: .automatic,
                orientation: .upright
            )
        ] + bundledSheets.map { sheetName in
            FloaterAvatarDefinition(
                id: slugify(sheetName),
                displayName: sheetName == SpriteSheetMetadata.defaultSheetName ? "Default Sprite" : sheetName,
                source: .spriteSheet(
                    imageSource: .bundledResource(name: sheetName),
                    metadata: SpriteSheetMetadata.forSheet(sheetName),
                    frameDuration: 0.16
                ),
                orientation: .upright
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
        var image = try RGBAImage(contentsOf: inputURL)
        let background = image.colorAt(x: 0, y: 0)
        var occupiedColumns = [Bool](repeating: false, count: image.width)

        for y in 0..<image.height {
            for x in 0..<image.width {
                let pixel = image.colorAt(x: x, y: y)
                if isBackground(
                    pixel,
                    background: background,
                    tolerance: FloaterVisualConstants.avatarImportBackgroundTolerance
                ) {
                    image.setColor(pixel.withAlpha(0), atX: x, y: y)
                }

                if image.alphaAt(x: x, y: y) > 0 {
                    occupiedColumns[x] = true
                }
            }
        }

        let segments = findSegments(in: occupiedColumns)
        guard !segments.isEmpty else {
            throw AvatarImportError.extractorFailed("No visible frames found after background removal.")
        }

        let frames = segments.compactMap { left, right -> RGBAImage? in
            var top: Int?
            var bottom: Int?

            for y in 0..<image.height where image.hasVisiblePixel(inRow: y, left: left, right: right) {
                top = y
                break
            }

            for y in stride(from: image.height - 1, through: 0, by: -1) where image.hasVisiblePixel(inRow: y, left: left, right: right) {
                bottom = y
                break
            }

            guard let top, let bottom else { return nil }
            return image.cropped(left: left, right: right, top: top, bottom: bottom)
        }

        guard !frames.isEmpty else {
            throw AvatarImportError.extractorFailed("No visible frames found after background removal.")
        }

        let cellWidth = (frames.map(\.width).max() ?? 0) + FloaterVisualConstants.avatarImportPadding * 2
        let cellHeight = (frames.map(\.height).max() ?? 0) + FloaterVisualConstants.avatarImportPadding * 2
        var sheet = RGBAImage(width: cellWidth * frames.count, height: cellHeight)

        for (index, frame) in frames.enumerated() {
            let originX = index * cellWidth + (cellWidth - frame.width) / 2
            let originY = (cellHeight - frame.height) / 2
            sheet.draw(frame, atX: originX, y: originY)
        }

        try sheet.writePNG(to: outputURL)
        return SpriteExtractionInfo(frameCount: frames.count, cellWidth: cellWidth, cellHeight: cellHeight)
    }

    private static func isBackground(_ pixel: RGBAColor, background: RGBAColor, tolerance: Int) -> Bool {
        abs(Int(pixel.red) - Int(background.red)) <= tolerance
            && abs(Int(pixel.green) - Int(background.green)) <= tolerance
            && abs(Int(pixel.blue) - Int(background.blue)) <= tolerance
    }

    private static func findSegments(in occupiedColumns: [Bool]) -> [(Int, Int)] {
        var segments: [(Int, Int)] = []
        var start: Int?

        for (x, isOccupied) in occupiedColumns.enumerated() {
            if isOccupied, start == nil {
                start = x
            } else if !isOccupied, let startX = start {
                segments.append((startX, x - 1))
                start = nil
            }
        }

        if let start {
            segments.append((start, occupiedColumns.count - 1))
        }

        return segments
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
    var orientation: FloaterAvatarOrientation?
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

private struct RGBAColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    func withAlpha(_ alpha: UInt8) -> Self {
        Self(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private struct RGBAImage {
    let width: Int
    let height: Int
    private(set) var pixels: [UInt8]

    init(contentsOf url: URL) throws {
        if let image = NSImage(contentsOf: url),
           let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            try self.init(cgImage: cgImage)
            return
        }

        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw AvatarImportError.invalidSourceImage(url.path)
        }
        try self.init(cgImage: cgImage)
    }

    init(cgImage: CGImage) throws {
        width = cgImage.width
        height = cgImage.height
        pixels = Array(repeating: 0, count: width * height * 4)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        let bytesPerRow = width * 4

        let rendered = pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            ) else {
                return false
            }

            context.interpolationQuality = .none
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }

        guard rendered else {
            throw AvatarImportError.bitmapContextUnavailable
        }
    }

    init(width: Int, height: Int, fill: RGBAColor = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0)) {
        self.width = width
        self.height = height
        pixels = Array(repeating: 0, count: width * height * 4)

        guard fill.red != 0 || fill.green != 0 || fill.blue != 0 || fill.alpha != 0 else {
            return
        }

        for y in 0..<height {
            for x in 0..<width {
                setColor(fill, atX: x, y: y)
            }
        }
    }

    func colorAt(x: Int, y: Int) -> RGBAColor {
        let index = pixelIndex(x: x, y: y)
        return RGBAColor(
            red: pixels[index],
            green: pixels[index + 1],
            blue: pixels[index + 2],
            alpha: pixels[index + 3]
        )
    }

    func alphaAt(x: Int, y: Int) -> UInt8 {
        pixels[pixelIndex(x: x, y: y) + 3]
    }

    mutating func setColor(_ color: RGBAColor, atX x: Int, y: Int) {
        let index = pixelIndex(x: x, y: y)
        pixels[index] = color.red
        pixels[index + 1] = color.green
        pixels[index + 2] = color.blue
        pixels[index + 3] = color.alpha
    }

    func hasVisiblePixel(inRow y: Int, left: Int, right: Int) -> Bool {
        for x in left...right where alphaAt(x: x, y: y) > 0 {
            return true
        }
        return false
    }

    func cropped(left: Int, right: Int, top: Int, bottom: Int) -> Self {
        var cropped = Self(width: right - left + 1, height: bottom - top + 1)
        for y in top...bottom {
            for x in left...right {
                cropped.setColor(colorAt(x: x, y: y), atX: x - left, y: y - top)
            }
        }
        return cropped
    }

    mutating func draw(_ image: Self, atX originX: Int, y originY: Int) {
        for y in 0..<image.height {
            for x in 0..<image.width {
                setColor(image.colorAt(x: x, y: y), atX: originX + x, y: originY + y)
            }
        }
    }

    func writePNG(to url: URL) throws {
        guard let cgImage = makeCGImage() else {
            throw AvatarImportError.extractorFailed("Failed to encode sprite sheet PNG.")
        }

        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw AvatarImportError.extractorFailed("Failed to create PNG writer for \(url.path).")
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw AvatarImportError.extractorFailed("Failed to write PNG sprite sheet to \(url.path).")
        }
    }

    private func makeCGImage() -> CGImage? {
        let data = Data(displayPixels())
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)

        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    private func pixelIndex(x: Int, y: Int) -> Int {
        ((y * width) + x) * 4
    }

    private func displayPixels() -> [UInt8] {
        let bytesPerRow = width * 4
        guard height > 1 else { return pixels }

        var display = Array(repeating: UInt8(0), count: pixels.count)
        for row in 0..<height {
            let sourceStart = row * bytesPerRow
            let sourceEnd = sourceStart + bytesPerRow
            let targetStart = (height - row - 1) * bytesPerRow
            display.replaceSubrange(targetStart..<(targetStart + bytesPerRow), with: pixels[sourceStart..<sourceEnd])
        }
        return display
    }
}

private enum AvatarImportError: LocalizedError {
    case invalidSourceImage(String)
    case bitmapContextUnavailable
    case extractorFailed(String)
    case avatarMissing(String)

    var errorDescription: String? {
        switch self {
        case let .invalidSourceImage(path):
            return "Failed to read avatar source image at \(path)."
        case .bitmapContextUnavailable:
            return "Failed to prepare image buffer for avatar import."
        case let .extractorFailed(message):
            return message.isEmpty ? "Sprite extraction failed." : message
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
