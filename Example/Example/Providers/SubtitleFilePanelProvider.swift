//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import AppKit
import UniformTypeIdentifiers

struct SubtitleFilePanelProvider {
    private final class SaveFormatAccessoryView: NSView {
        private weak var panel: NSSavePanel?
        private let formats: [String]
        let popup: NSPopUpButton

        init(panel: NSSavePanel, formats: [String], initialIndex: Int) {
            self.panel = panel
            self.formats = formats
            self.popup = NSPopUpButton(frame: .zero, pullsDown: false)
            super.init(frame: .zero)

            let label = NSTextField(labelWithString: "Format:")
            popup.addItems(withTitles: formats.map { $0.uppercased() })
            popup.selectItem(at: initialIndex)
            popup.setContentHuggingPriority(.required, for: .horizontal)
            popup.target = self
            popup.action = #selector(formatChanged)

            let stack = NSStackView(views: [label, popup])
            stack.orientation = .horizontal
            stack.spacing = 8
            stack.alignment = .centerY
            stack.edgeInsets = NSEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            stack.translatesAutoresizingMaskIntoConstraints = false

            addSubview(stack)
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: leadingAnchor),
                stack.trailingAnchor.constraint(equalTo: trailingAnchor),
                stack.topAnchor.constraint(equalTo: topAnchor),
                stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func formatChanged() {
            guard let panel else {
                return
            }
            let index = max(0, popup.indexOfSelectedItem)
            let format = formats[index]

            let currentName = panel.nameFieldStringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let baseName = SubtitleFilePanelProvider.normalizedBaseName(
                from: currentName,
                knownFormatNames: formats
            )

            panel.allowedContentTypes = [UTType(filenameExtension: format) ?? .plainText]
            // Let AppKit manage the visible extension for the selected content type.
            // Setting a full filename here can lead to duplicated extensions (e.g. ".srt.srt").
            panel.nameFieldStringValue = baseName
        }
    }

    struct SaveSelection {
        var url: URL
        var formatName: String
    }

    func openSubtitleFiles(allowedContentTypes: [UTType]) -> [URL]? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = allowedContentTypes

        guard panel.runModal() == .OK else {
            return nil
        }
        return panel.urls
    }

    func saveSubtitleFile(suggestedName: String, fileExtension: String) -> URL? {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = [UTType(filenameExtension: fileExtension) ?? .plainText]

        guard panel.runModal() == .OK else {
            return nil
        }
        return panel.url
    }

    func saveSubtitleFileWithFormat(
        suggestedBaseName: String,
        availableFormatNames: [String],
        selectedFormatName: String
    ) -> SaveSelection? {
        let formats = availableFormatNames.isEmpty ? [selectedFormatName] : availableFormatNames
        let initialIndex = formats.firstIndex { $0.caseInsensitiveCompare(selectedFormatName) == .orderedSame } ?? 0
        let initialFormat = formats[initialIndex]

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        let normalizedSuggestedBaseName = Self.normalizedBaseName(
            from: suggestedBaseName,
            knownFormatNames: formats
        )
        panel.allowedContentTypes = [UTType(filenameExtension: initialFormat) ?? .plainText]
        // Provide the base name only; NSSavePanel will render/apply the selected extension.
        panel.nameFieldStringValue = normalizedSuggestedBaseName
        let accessory = SaveFormatAccessoryView(panel: panel, formats: formats, initialIndex: initialIndex)
        panel.accessoryView = accessory

        guard panel.runModal() == .OK, let panelURL = panel.url else {
            return nil
        }

        let selectedIndex = max(0, accessory.popup.indexOfSelectedItem)
        let selectedFormat = formats[selectedIndex]
        let normalizedURL = Self.normalizedURL(
            from: panelURL,
            selectedFormat: selectedFormat,
            knownFormatNames: formats
        )
        return SaveSelection(url: normalizedURL, formatName: selectedFormat)
    }

    private static func filename(forBaseName baseName: String, formatName: String) -> String {
        let trimmedBaseName = baseName.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeBaseName = trimmedBaseName.isEmpty ? "subtitle" : trimmedBaseName
        return "\(safeBaseName).\(formatName)"
    }

    private static func normalizedBaseName(from rawName: String, knownFormatNames: [String]) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "subtitle"
        }

        let knownFormats = Set(knownFormatNames.map { $0.lowercased() })
        var candidate = trimmed

        while true {
            let nsCandidate = NSString(string: candidate)
            let ext = nsCandidate.pathExtension.lowercased()
            guard !ext.isEmpty, knownFormats.contains(ext) else {
                break
            }
            candidate = nsCandidate.deletingPathExtension
        }

        return candidate.isEmpty ? "subtitle" : candidate
    }

    private static func normalizedURL(from rawURL: URL, selectedFormat: String, knownFormatNames: [String]) -> URL {
        let directoryURL = rawURL.deletingLastPathComponent()
        let baseName = normalizedBaseName(
            from: rawURL.lastPathComponent,
            knownFormatNames: knownFormatNames
        )
        let filename = filename(forBaseName: baseName, formatName: selectedFormat)
        return directoryURL.appendingPathComponent(filename)
    }
}
