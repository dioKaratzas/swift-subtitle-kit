//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Combine
import Foundation
import SubtitleKit

@MainActor
final class ShowcaseAppModel: ObservableObject {
    @Published var documents = [ShowcaseDocument]()
    @Published var selectedDocumentID: ShowcaseDocument.ID?
    @Published var alertMessage: String?
    @Published var fullDiffSheet: FullDiffSheetModel?

    let formatCatalog: SubtitleFormatCatalogProvider
    private let panelProvider: SubtitleFilePanelProvider
    private let documentIO: SubtitleDocumentIOProvider

    init(
        formatCatalog: SubtitleFormatCatalogProvider = .init(),
        panelProvider: SubtitleFilePanelProvider = .init(),
        documentIO: SubtitleDocumentIOProvider = .init()
    ) {
        self.formatCatalog = formatCatalog
        self.panelProvider = panelProvider
        self.documentIO = documentIO
    }

    var selectedDocumentIndex: Int? {
        guard let selectedDocumentID else {
            return nil
        }
        return documents.firstIndex(where: { $0.id == selectedDocumentID })
    }

    func clearAllDocuments() {
        documents.removeAll()
        selectedDocumentID = nil
    }

    func closeDocument(id: ShowcaseDocument.ID) {
        documents.removeAll { $0.id == id }
        if selectedDocumentID == id {
            selectedDocumentID = documents.first?.id
        }
    }

    func saveSelectedDocument() {
        guard let index = selectedDocumentIndex else {
            return
        }
        guard let fileURL = documents[index].fileURL else {
            exportSelectedDocument()
            return
        }

        let currentFormat = documents[index].subtitle.format
            ?? formatCatalog.resolveFormat(named: documents[index].exportFormatName)

        do {
            try documentIO.saveSubtitle(documents[index].subtitle, to: fileURL, format: currentFormat)
            documents[index].markSaved(fileURL: fileURL)
        } catch {
            presentError(error.localizedDescription)
        }
    }

    func exportSelectedDocument() {
        guard let index = selectedDocumentIndex else {
            return
        }
        let availableFormats = formatCatalog.formatChoices.map(\.name)
        let currentFormatName = documents[index].subtitle.formatName ?? documents[index].exportFormatName

        guard let selection = panelProvider.saveSubtitleFileWithFormat(
            suggestedBaseName: documents[index].suggestedFileStem,
            availableFormatNames: availableFormats,
            selectedFormatName: currentFormatName
        ) else {
            return
        }

        guard let targetFormat = formatCatalog.resolveFormat(named: selection.formatName) else {
            presentError("Unable to resolve format '\(selection.formatName)'.")
            return
        }

        do {
            try documentIO.saveSubtitle(documents[index].subtitle, to: selection.url, format: targetFormat)
            documents[index].exportFormatName = targetFormat.name
        } catch {
            presentError(error.localizedDescription)
        }
    }

    func openFiles() {
        guard let urls = panelProvider.openSubtitleFiles(allowedContentTypes: formatCatalog.openContentTypes) else {
            return
        }
        open(urls: urls)
    }

    func open(urls: [URL]) {
        guard !urls.isEmpty else {
            return
        }

        var openedAny = false
        for url in urls where url.isFileURL {
            if let existing = documents.firstIndex(where: { $0.fileURL?.standardizedFileURL == url.standardizedFileURL }) {
                selectedDocumentID = documents[existing].id
                openedAny = true
                continue
            }

            do {
                let subtitle = try documentIO.loadSubtitle(from: url)
                let document = ShowcaseDocument(fileURL: url, subtitle: subtitle)
                documents.append(document)
                selectedDocumentID = document.id
                openedAny = true
            } catch {
                presentError("Failed to open \(url.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if !openedAny, documents.isEmpty {
            selectedDocumentID = nil
        }
    }

    func presentFullDiff(for document: ShowcaseDocument) {
        guard let preview = document.cleanPreview else {
            presentError("Generate a clean preview before opening the diff view.")
            return
        }

        let format = document.subtitle.format ?? formatCatalog.resolveFormat(named: document.exportFormatName)
        let originalText = documentIO.serializedText(for: document.subtitle, preferredFormat: format)
        let cleanedText = documentIO.serializedText(for: preview.subtitle, preferredFormat: format)

        fullDiffSheet = FullDiffSheetModel(
            title: document.displayName,
            originalText: originalText,
            cleanedText: cleanedText,
            stats: .init(
                total: preview.report.originalCueCount,
                remaining: preview.report.remainingCueCount,
                modified: preview.report.modifiedCueCount,
                removed: preview.report.removedCueCount
            )
        )
    }

    func clearAlert() {
        alertMessage = nil
    }

    private func presentError(_ message: String) {
        alertMessage = message
    }
}
