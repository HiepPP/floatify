import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct AvatarsTab: View {
    @Environment(FloatifySettings.self) private var settings
    @Environment(FloaterVisualCatalog.self) private var visualCatalog

    @State private var message = ""
    @State private var messageLevel: SetupHealthLevel = .good

    @State private var importAvatarName = ""
    @State private var isImportingAvatar = false

    @State private var managedPackID = FloaterVisualConstants.personalPackID
    @State private var managedAvatarID = ""
    @State private var managedAvatarName = ""
    @State private var managedAvatarOrientation: FloaterAvatarOrientation = .upright
    @State private var isManagingAvatar = false

    @State private var pendingDeleteAvatarID: String?
    @State private var pendingDeleteAvatarName = ""

    var body: some View {
        @Bindable var settings = settings
        let selectedPack = visualCatalog.resolvedPack(id: settings.selectedVisualPackID)
        let customPacks = visualCatalog.packs.filter { !$0.isBuiltIn }
        let resolvedManagedPack = resolvedManagedPack(customPacks: customPacks, selectedPackID: settings.selectedVisualPackID)
        let manageableAvatars = manageableAvatars(in: resolvedManagedPack)
        let selectedManagedAvatar = selectedManagedAvatar(in: resolvedManagedPack)
        let hasCustomPacks = !customPacks.isEmpty
        let canImportAvatar = !trimmedImportAvatarName.isEmpty
        let canSaveManagedAvatar = selectedManagedAvatar != nil
            && !trimmedManagedAvatarName.isEmpty
            && (
                trimmedManagedAvatarName != (selectedManagedAvatar?.displayName ?? "")
                || managedAvatarOrientation != (selectedManagedAvatar?.orientation ?? .upright)
            )

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TabHeader(
                    title: "Avatars",
                    subtitle: "Manage floater avatars and effect presets.",
                    symbol: "person.crop.square.fill"
                )

                Form {
                    Section {
                        SettingRow("Avatar pack") {
                            Picker(
                                "Avatar pack",
                                selection: Binding(
                                    get: { settings.selectedVisualPackID },
                                    set: { settings.selectVisualPack($0, catalog: visualCatalog) }
                                )
                            ) {
                                ForEach(visualCatalog.packs, id: \.id) { pack in
                                    Text(pack.displayName).tag(pack.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        SettingRow("Avatar") {
                            Picker("Avatar", selection: $settings.selectedAvatarID) {
                                ForEach(selectedPack.avatars, id: \.id) { avatar in
                                    Text(avatar.displayName).tag(avatar.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }

                        SettingRow("Effect style") {
                            Picker("Effect style", selection: $settings.selectedEffectPresetID) {
                                ForEach(selectedPack.effectPresets, id: \.id) { preset in
                                    Text(preset.displayName).tag(preset.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    } header: {
                        SectionHeader("Current Selection")
                    }

                    Section {
                        SettingRow("Avatar name", subtitle: "Required before import.") {
                            TextField("e.g. Sprinkles", text: $importAvatarName)
                                .textFieldStyle(.roundedBorder)
                        }

                        HStack(spacing: 10) {
                            Button {
                                openAvatarImportPanel(for: selectedPack)
                            } label: {
                                Label("Import Image...", systemImage: "photo.badge.plus")
                            }
                            .disabled(isImportingAvatar || !canImportAvatar)

                            Button {
                                importAvatarFromPasteboard(into: selectedPack)
                            } label: {
                                Label("Paste Image", systemImage: "doc.on.clipboard")
                            }
                            .disabled(isImportingAvatar || !canImportAvatar)

                            if isImportingAvatar {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.leading, 4)
                            }

                            Spacer()
                        }
                        .buttonStyle(.bordered)
                    } header: {
                        SectionHeader("Import Avatar")
                    } footer: {
                        Text("Built-in pack imports land in Personal. Paste reads the clipboard image.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        if !hasCustomPacks {
                            EmptyStateView(
                                icon: "tray",
                                title: "No custom packs yet",
                                message: "Import an avatar above to create your Personal pack."
                            )
                        } else if let resolvedManagedPack {
                            SettingRow("Pack") {
                                Picker(
                                    "Pack",
                                    selection: Binding(
                                        get: { resolvedManagedPack.id },
                                        set: { newValue in
                                            managedPackID = newValue
                                            syncManagedAvatarSelection(
                                                customPacks: customPacks,
                                                selectedPackID: settings.selectedVisualPackID
                                            )
                                        }
                                    )
                                ) {
                                    ForEach(customPacks) { pack in
                                        Text(pack.displayName).tag(pack.id)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                            }

                            if manageableAvatars.isEmpty {
                                EmptyStateView(
                                    icon: "person.crop.circle.badge.questionmark",
                                    title: "No uploaded avatars",
                                    message: "This pack has no uploaded avatars yet."
                                )
                            } else if let selectedManagedAvatar {
                                SettingRow("Uploaded avatar") {
                                    Picker(
                                        "Uploaded avatar",
                                        selection: Binding(
                                            get: { selectedManagedAvatar.id },
                                            set: { newValue in
                                                managedAvatarID = newValue
                                                managedAvatarName = manageableAvatars.first(where: { $0.id == newValue })?.displayName ?? ""
                                                managedAvatarOrientation = manageableAvatars.first(where: { $0.id == newValue })?.orientation ?? .upright
                                            }
                                        )
                                    ) {
                                        ForEach(manageableAvatars) { avatar in
                                            Text(avatar.displayName).tag(avatar.id)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.menu)
                                }

                                SettingRow("Display name") {
                                    TextField("Display name", text: $managedAvatarName)
                                        .textFieldStyle(.roundedBorder)
                                }

                                SettingRow("Direction") {
                                    Picker("Direction", selection: $managedAvatarOrientation) {
                                        ForEach(FloaterAvatarOrientation.allCases, id: \.self) { orientation in
                                            Text(orientation.displayName).tag(orientation)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.segmented)
                                }

                                HStack(spacing: 10) {
                                    Button {
                                        saveManagedAvatar(
                                            avatarID: selectedManagedAvatar.id,
                                            pack: resolvedManagedPack
                                        )
                                    } label: {
                                        Label("Save", systemImage: "checkmark")
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isManagingAvatar || !canSaveManagedAvatar)

                                    Button(role: .destructive) {
                                        pendingDeleteAvatarID = selectedManagedAvatar.id
                                        pendingDeleteAvatarName = selectedManagedAvatar.displayName
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.red)
                                    .disabled(isManagingAvatar)

                                    if isManagingAvatar {
                                        ProgressView()
                                            .controlSize(.small)
                                            .padding(.leading, 4)
                                    }

                                    Spacer()
                                }
                            } else {
                                Text("Pick an uploaded avatar to rename or delete it.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        SectionHeader("Manage Uploaded Avatar")
                    }

                    Section {
                        HStack(spacing: 10) {
                            Button {
                                visualCatalog.revealPacksDirectory()
                                setMessage("Opened \(visualCatalog.packsDirectoryPath).", level: .good)
                            } label: {
                                Label("Reveal Folder", systemImage: "folder")
                            }

                            Button {
                                visualCatalog.reload()
                                settings.normalizeVisualSelection(catalog: visualCatalog)
                                setMessage(visualCatalog.lastReloadMessage ?? "Reloaded visual packs.", level: .good)
                            } label: {
                                Label("Reload Packs", systemImage: "arrow.clockwise")
                            }

                            Spacer()
                        }
                        .buttonStyle(.bordered)

                        if let sourceURL = selectedPack.sourceURL {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected pack path")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(sourceURL.path)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            .padding(.top, 4)
                        }

                        InlineMessage(message: message, level: messageLevel)
                            .task(id: message) {
                                guard !message.isEmpty else { return }
                                try? await Task.sleep(nanoseconds: 4_000_000_000)
                                withAnimation { message = "" }
                            }
                    } header: {
                        SectionHeader("Pack Folder")
                    } footer: {
                        Text("Drop custom packs into ~/.floatify/packs. Import Image and Paste Image auto-run the sprite extractor.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
            }
            .padding(24)
        }
        .onAppear {
            settings.normalizeVisualSelection(catalog: visualCatalog)
            syncManagedAvatarSelection(
                customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                selectedPackID: settings.selectedVisualPackID
            )
        }
        .onChange(of: settings.selectedVisualPackID) { _, _ in
            syncManagedAvatarSelection(
                customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                selectedPackID: settings.selectedVisualPackID
            )
        }
        .onChange(of: visualCatalog.packs) { _, packs in
            syncManagedAvatarSelection(
                customPacks: packs.filter { !$0.isBuiltIn },
                selectedPackID: settings.selectedVisualPackID
            )
        }
        .alert("Delete uploaded avatar?", isPresented: deleteAvatarAlertBinding) {
            Button("Delete", role: .destructive) {
                confirmDeleteManagedAvatar()
            }
            Button("Cancel", role: .cancel) {
                clearPendingDeleteAvatar()
            }
        } message: {
            Text("Delete '\(pendingDeleteAvatarName)' from this pack?")
        }
    }

    private func setMessage(_ text: String, level: SetupHealthLevel) {
        withAnimation { message = text; messageLevel = level }
    }

    private func openAvatarImportPanel(for pack: FloaterVisualPack) {
        guard validateAvatarNameInput() else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            importAvatar(from: url, cleanupURL: nil, requestedPack: pack)
        }
    }

    private func importAvatarFromPasteboard(into pack: FloaterVisualPack) {
        guard validateAvatarNameInput() else { return }

        do {
            let temporaryURL = try writePasteboardImageToTemporaryFile()
            importAvatar(from: temporaryURL, cleanupURL: temporaryURL, requestedPack: pack)
        } catch {
            setMessage("Paste image failed: \(error.localizedDescription)", level: .error)
        }
    }

    private func importAvatar(from sourceURL: URL, cleanupURL: URL?, requestedPack: FloaterVisualPack) {
        guard validateAvatarNameInput() else { return }

        isImportingAvatar = true
        setMessage("Importing avatar sprite...", level: .good)

        let requestedPackID = requestedPack.id
        let requestedPackName = requestedPack.displayName
        let requestedPackDirectoryURL = requestedPack.sourceURL
        let requestedPackIsBuiltIn = requestedPack.isBuiltIn
        let packsDirectoryURL = visualCatalog.packsDirectoryURL
        let displayName = trimmedImportAvatarName

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                if let cleanupURL {
                    try? FileManager.default.removeItem(at: cleanupURL)
                }
            }

            do {
                let result = try FloaterVisualCatalog.importAvatarAsset(
                    from: sourceURL,
                    preferredPackID: requestedPackID,
                    preferredPackName: requestedPackName,
                    preferredPackDirectoryURL: requestedPackDirectoryURL,
                    preferredPackIsBuiltIn: requestedPackIsBuiltIn,
                    packsDirectoryURL: packsDirectoryURL,
                    displayName: displayName
                )

                DispatchQueue.main.async {
                    visualCatalog.reload()
                    settings.selectVisualPack(result.packID, catalog: visualCatalog)
                    settings.selectedAvatarID = result.avatarID
                    importAvatarName = ""
                    isImportingAvatar = false
                    managedPackID = result.packID
                    managedAvatarID = result.avatarID
                    syncManagedAvatarSelection(
                        customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                        selectedPackID: settings.selectedVisualPackID
                    )

                    let destinationNote = result.packID == requestedPackID
                        ? result.packName
                        : "\(result.packName) (fallback from \(requestedPackName))"
                    setMessage(
                        "Imported \(result.avatarName) to \(destinationNote). \(result.frameCount) frame(s) ready.",
                        level: .good
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    isImportingAvatar = false
                    setMessage("Avatar import failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func writePasteboardImageToTemporaryFile() throws -> URL {
        let pasteboard = NSPasteboard.general
        if let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
           let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("floatify-avatar-\(UUID().uuidString).png")
            try png.write(to: url, options: .atomic)
            return url
        }

        throw AvatarImportUIError.pasteboardImageMissing
    }

    private var trimmedImportAvatarName: String {
        importAvatarName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func validateAvatarNameInput() -> Bool {
        guard !trimmedImportAvatarName.isEmpty else {
            setMessage("Avatar name is required before import.", level: .warning)
            return false
        }
        return true
    }

    private var trimmedManagedAvatarName: String {
        managedAvatarName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var deleteAvatarAlertBinding: Binding<Bool> {
        Binding(
            get: { pendingDeleteAvatarID != nil },
            set: { isPresented in
                if !isPresented {
                    clearPendingDeleteAvatar()
                }
            }
        )
    }

    private func resolvedManagedPack(
        customPacks: [FloaterVisualPack],
        selectedPackID: String
    ) -> FloaterVisualPack? {
        if let explicit = customPacks.first(where: { $0.id == managedPackID }) {
            return explicit
        }
        if let selected = customPacks.first(where: { $0.id == selectedPackID }) {
            return selected
        }
        if let personal = customPacks.first(where: { $0.id == FloaterVisualConstants.personalPackID }) {
            return personal
        }
        return customPacks.first
    }

    private func manageableAvatars(in pack: FloaterVisualPack?) -> [FloaterAvatarDefinition] {
        guard let pack else { return [] }
        return pack.avatars.filter { !$0.isAutomatic }
    }

    private func selectedManagedAvatar(in pack: FloaterVisualPack?) -> FloaterAvatarDefinition? {
        let avatars = manageableAvatars(in: pack)
        return avatars.first(where: { $0.id == managedAvatarID }) ?? avatars.first
    }

    private func syncManagedAvatarSelection(
        customPacks: [FloaterVisualPack],
        selectedPackID: String
    ) {
        guard let pack = resolvedManagedPack(customPacks: customPacks, selectedPackID: selectedPackID) else {
            managedPackID = FloaterVisualConstants.personalPackID
            managedAvatarID = ""
            managedAvatarName = ""
            managedAvatarOrientation = .upright
            return
        }

        managedPackID = pack.id

        let avatars = manageableAvatars(in: pack)
        let avatar = avatars.first(where: { $0.id == managedAvatarID }) ?? avatars.first
        managedAvatarID = avatar?.id ?? ""
        managedAvatarName = avatar?.displayName ?? ""
        managedAvatarOrientation = avatar?.orientation ?? .upright
    }

    private func saveManagedAvatar(avatarID: String, pack: FloaterVisualPack) {
        guard let packDirectoryURL = pack.sourceURL else {
            setMessage("This pack cannot be edited.", level: .warning)
            return
        }

        let nextName = trimmedManagedAvatarName
        let nextOrientation = managedAvatarOrientation
        guard !nextName.isEmpty else {
            setMessage("Avatar display name is required.", level: .warning)
            return
        }

        isManagingAvatar = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try FloaterVisualCatalog.updateAvatarAsset(
                    avatarID: avatarID,
                    in: packDirectoryURL,
                    displayName: nextName,
                    orientation: nextOrientation
                )

                DispatchQueue.main.async {
                    visualCatalog.reload()
                    managedPackID = result.packID
                    if let avatarID = result.avatarID {
                        managedAvatarID = avatarID
                    }
                    settings.normalizeVisualSelection(catalog: visualCatalog)
                    syncManagedAvatarSelection(
                        customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                        selectedPackID: settings.selectedVisualPackID
                    )
                    isManagingAvatar = false
                    setMessage("Saved avatar \(result.avatarName ?? nextName).", level: .good)
                }
            } catch {
                DispatchQueue.main.async {
                    isManagingAvatar = false
                    setMessage("Save avatar failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func confirmDeleteManagedAvatar() {
        guard
            let avatarID = pendingDeleteAvatarID,
            let packDirectoryURL = visualCatalog.resolvedPack(id: managedPackID).sourceURL
        else {
            clearPendingDeleteAvatar()
            return
        }

        let shouldFallbackToBuiltIn =
            settings.selectedVisualPackID == managedPackID
            && settings.selectedAvatarID == avatarID

        clearPendingDeleteAvatar()
        isManagingAvatar = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let result = try FloaterVisualCatalog.deleteAvatarAsset(
                    avatarID: avatarID,
                    in: packDirectoryURL
                )

                DispatchQueue.main.async {
                    visualCatalog.reload()
                    managedPackID = result.packID
                    managedAvatarID = result.avatarID ?? ""
                    if shouldFallbackToBuiltIn {
                        settings.selectVisualPack(FloaterVisualConstants.builtInPackID, catalog: visualCatalog)
                    } else {
                        settings.normalizeVisualSelection(catalog: visualCatalog)
                    }
                    syncManagedAvatarSelection(
                        customPacks: visualCatalog.packs.filter { !$0.isBuiltIn },
                        selectedPackID: settings.selectedVisualPackID
                    )
                    isManagingAvatar = false
                    setMessage("Deleted avatar \(result.avatarName ?? avatarID).", level: .good)
                }
            } catch {
                DispatchQueue.main.async {
                    isManagingAvatar = false
                    setMessage("Delete failed: \(error.localizedDescription)", level: .error)
                }
            }
        }
    }

    private func clearPendingDeleteAvatar() {
        pendingDeleteAvatarID = nil
        pendingDeleteAvatarName = ""
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

enum AvatarImportUIError: LocalizedError {
    case pasteboardImageMissing

    var errorDescription: String? {
        switch self {
        case .pasteboardImageMissing:
            return "Pasteboard does not contain an image."
        }
    }
}
