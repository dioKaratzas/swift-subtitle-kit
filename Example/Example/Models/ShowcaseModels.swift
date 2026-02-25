//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation
import SubtitleKit

struct FormatChoice: Identifiable, Hashable {
    let name: String
    var id: String {
        name
    }

    var label: String {
        name.uppercased()
    }
}

struct FullDiffSheetModel: Identifiable {
    struct Stats {
        var total: Int
        var remaining: Int
        var modified: Int
        var removed: Int
    }

    let id = UUID()
    let title: String
    let originalText: String
    let cleanedText: String
    let stats: Stats
}

struct ShowcaseDocument: Identifiable {
    let id = UUID()
    var fileURL: URL?
    var subtitle: Subtitle
    var lastSavedSnapshot: Subtitle
    var cleanOptions: Set<SubtitleCleanOption>
    var cleanPreview: SubtitleCleanResult?
    var selectedCueID: Int?
    var selectedChangeID: Int?
    var showChangedChangesOnly: Bool
    var cueSearchQuery: String
    var exportFormatName: String
    var subtitleRevision: Int

    static let defaultCleanOptions: Set<SubtitleCleanOption> = [
        .removeSDH,
        .removeWatermarks,
        .removeSpeakerLabels,
        .removeCurlyBracketTags,
        .removeHTMLTags,
    ]

    init(fileURL: URL?, subtitle: Subtitle) {
        self.fileURL = fileURL
        self.subtitle = subtitle
        self.lastSavedSnapshot = subtitle
        self.cleanOptions = Self.defaultCleanOptions
        self.cleanPreview = nil
        self.selectedCueID = subtitle.cues.first?.id
        self.selectedChangeID = nil
        self.showChangedChangesOnly = true
        self.cueSearchQuery = ""
        self.exportFormatName = subtitle.formatName ?? "srt"
        self.subtitleRevision = 0
    }

    var displayName: String {
        fileURL?.lastPathComponent ?? "Untitled Subtitle"
    }

    var suggestedFileStem: String {
        if let fileURL {
            return fileURL.deletingPathExtension().lastPathComponent
        }
        return "subtitle"
    }

    var currentFormatLabel: String {
        subtitle.formatName ?? fileURL?.pathExtension ?? exportFormatName
    }

    var isDirty: Bool {
        subtitle != lastSavedSnapshot
    }

    func cue(id: Int) -> SubtitleCue? {
        subtitle.cues.first(where: { $0.id == id })
    }

    mutating func sanitizeSelection() {
        if let selectedCueID, cue(id: selectedCueID) == nil {
            self.selectedCueID = subtitle.cues.first?.id
        }
        if let selectedChangeID,
           !(cleanPreview?.report.changes.contains(where: { $0.id == selectedChangeID }) ?? false) {
            self.selectedChangeID = nil
        }
    }

    mutating func invalidatePreview(preserveSelection: Bool) {
        cleanPreview = nil
        selectedChangeID = nil
        if !preserveSelection {
            selectedCueID = subtitle.cues.first?.id
        }
        sanitizeSelection()
    }

    mutating func updateCue(id: Int, mutate: (inout SubtitleCue) -> Void) {
        guard let index = subtitle.entries.firstIndex(where: {
            guard case let .cue(cue) = $0 else {
                return false
            }
            return cue.id == id
        }) else {
            return
        }

        guard case let .cue(existingCue) = subtitle.entries[index] else {
            return
        }
        var cue = existingCue
        mutate(&cue)
        cue.startTime = max(0, cue.startTime)
        cue.endTime = max(cue.startTime, cue.endTime)
        subtitle.entries[index] = .cue(cue)
        subtitleRevision &+= 1
        invalidatePreview(preserveSelection: true)
    }

    mutating func deleteSelectedCue() {
        guard let selectedCueID else {
            return
        }
        subtitle.entries.removeAll { entry in
            guard case let .cue(cue) = entry else {
                return false
            }
            return cue.id == selectedCueID
        }
        subtitleRevision &+= 1
        invalidatePreview(preserveSelection: false)
    }

    mutating func generateCleanPreview() {
        let orderedOptions = SubtitleCleanOption.allCases.filter(cleanOptions.contains)
        let preview = subtitle.cleanWithReport(orderedOptions)
        cleanPreview = preview
        selectedChangeID = preview.report.changes.first(where: { $0.status != .unchanged })?.id
            ?? preview.report.changes.first?.id
    }

    mutating func applyCleanPreviewOrCleanNow() {
        if let preview = cleanPreview {
            subtitle = preview.subtitle
        } else {
            let orderedOptions = SubtitleCleanOption.allCases.filter(cleanOptions.contains)
            subtitle = subtitle.clean(orderedOptions)
        }
        subtitleRevision &+= 1
        invalidatePreview(preserveSelection: true)
        sanitizeSelection()
    }

    mutating func applyResync(_ options: SubtitleResyncOptions) {
        subtitle.applyResync(options)
        subtitleRevision &+= 1
        invalidatePreview(preserveSelection: true)
        sanitizeSelection()
    }

    mutating func markSaved(fileURL: URL) {
        self.fileURL = fileURL
        self.lastSavedSnapshot = subtitle
    }

    func suggestedExportName(defaultExtension: String) -> String {
        "\(suggestedFileStem).\(defaultExtension)"
    }
}

struct CleanOptionDescriptor: Identifiable, CaseIterable {
    let option: SubtitleCleanOption
    let title: String
    let subtitle: String

    var id: SubtitleCleanOption {
        option
    }

    static let allCases: [Self] = [
        .init(
            option: .removeSDH,
            title: "Remove SDH (hearing-impaired descriptions)",
            subtitle: "Removes [music], (laughing), and similar SDH annotations."
        ),
        .init(
            option: .removeWatermarks,
            title: "Remove watermarks",
            subtitle: "Strips links, promotional text, and email lines."
        ),
        .init(
            option: .removeSpeakerLabels,
            title: "Remove speaker labels",
            subtitle: "Removes prefixes like GEORGE: and >> JOHN:."
        ),
        .init(
            option: .removeCuesContainingMusicNotes,
            title: "Remove cues containing music notes",
            subtitle: "Drops cues containing ♪, ♫, ♬, or ♩."
        ),
        .init(
            option: .removeAllLineBreaks,
            title: "Remove all line breaks",
            subtitle: "Collapses multi-line cue text into a single line."
        ),
        .init(
            option: .mergeCuesWithSameText,
            title: "Merge cues with same text",
            subtitle: "Combines overlapping consecutive cues with identical text."
        ),
        .init(
            option: .fixUppercaseText,
            title: "Fix uppercase text",
            subtitle: "Converts mostly uppercase captions into sentence case."
        ),
        .init(
            option: .removeCurlyBracketTags,
            title: "Remove curly bracket tags",
            subtitle: "Removes SubStation-style tags like {\\an8}."
        ),
        .init(option: .removeHTMLTags, title: "Remove HTML tags", subtitle: "Removes inline HTML tags like <i> and <b>."),
    ]
}
