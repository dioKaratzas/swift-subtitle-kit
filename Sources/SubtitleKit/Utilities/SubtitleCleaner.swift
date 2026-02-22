//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

enum SubtitleCleaner {
    struct Output {
        var document: SubtitleDocument
        var report: SubtitleCleanReport
    }

    private struct ChangeTracker {
        var modifiedByCueID = [Int: Set<SubtitleCleanOption>]()
        var removedByCueID = [Int: Set<SubtitleCleanOption>]()

        mutating func noteModified(cueID: Int, by option: SubtitleCleanOption) {
            modifiedByCueID[cueID, default: []].insert(option)
        }

        mutating func noteRemoved(cueID: Int, by option: SubtitleCleanOption) {
            removedByCueID[cueID, default: []].insert(option)
        }

        func options(for cueID: Int) -> Set<SubtitleCleanOption> {
            modifiedByCueID[cueID, default: []].union(removedByCueID[cueID, default: []])
        }
    }

    static func clean(
        document: SubtitleDocument,
        options: [SubtitleCleanOption]
    ) -> SubtitleDocument {
        cleanWithReport(document: document, options: options).document
    }

    static func cleanWithReport(
        document: SubtitleDocument,
        options: [SubtitleCleanOption]
    ) -> Output {
        let orderedOptions = deduplicated(options)
        let originalCues = document.cues

        var updated = document
        var tracker = ChangeTracker()

        for option in orderedOptions {
            updated = apply(
                option: option,
                to: updated,
                tracker: &tracker
            )
        }

        let report = buildReport(
            originalCues: originalCues,
            cleanedDocument: updated,
            tracker: tracker
        )

        return Output(document: updated, report: report)
    }

    private static func deduplicated(_ options: [SubtitleCleanOption]) -> [SubtitleCleanOption] {
        var seen = Set<SubtitleCleanOption>()
        return options.filter { seen.insert($0).inserted }
    }

    private static func apply(
        option: SubtitleCleanOption,
        to document: SubtitleDocument,
        tracker: inout ChangeTracker
    ) -> SubtitleDocument {
        switch option {
        case .removeSDH:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: removingSDH(from: sourceText(for: cue)),
                    plain: removingSDH(from: plainSourceText(for: cue))
                )
            }
        case .removeWatermarks:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: removingWatermarkLines(from: sourceText(for: cue)),
                    plain: removingWatermarkLines(from: plainSourceText(for: cue))
                )
            }
        case .removeSpeakerLabels:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: removingSpeakerLabels(from: sourceText(for: cue)),
                    plain: removingSpeakerLabels(from: plainSourceText(for: cue))
                )
            }
        case .removeCuesContainingMusicNotes:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                let text = sourceText(for: cue)
                return containsMusicNotes(text) ? nil : cue
            }
        case .removeAllLineBreaks:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: removingLineBreaks(from: sourceText(for: cue)),
                    plain: removingLineBreaks(from: plainSourceText(for: cue))
                )
            }
        case .mergeCuesWithSameText:
            return mergingCuesWithSameText(in: document, tracker: &tracker)
        case .fixUppercaseText:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: fixingUppercaseText(in: sourceText(for: cue)),
                    plain: fixingUppercaseText(in: plainSourceText(for: cue))
                )
            }
        case .removeCurlyBracketTags:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: removingCurlyBracketTags(from: sourceText(for: cue)),
                    plain: removingCurlyBracketTags(from: plainSourceText(for: cue))
                )
            }
        case .removeHTMLTags:
            return transformCues(in: document, option: option, tracker: &tracker) { cue in
                updateCue(
                    cue,
                    raw: removingHTMLTags(from: sourceText(for: cue)),
                    plain: removingHTMLTags(from: plainSourceText(for: cue))
                )
            }
        }
    }

    private static func transformCues(
        in document: SubtitleDocument,
        option: SubtitleCleanOption,
        tracker: inout ChangeTracker,
        transform: (SubtitleCue) -> SubtitleCue?
    ) -> SubtitleDocument {
        var updated = document
        updated.entries = updated.entries.compactMap { entry in
            guard case let .cue(cue) = entry else {
                return entry
            }
            guard let transformed = transform(cue) else {
                tracker.noteRemoved(cueID: cue.id, by: option)
                return nil
            }
            if transformed != cue {
                tracker.noteModified(cueID: cue.id, by: option)
            }
            return .cue(transformed)
        }
        return updated
    }

    private static func sourceText(for cue: SubtitleCue) -> String {
        cue.rawText.isEmpty ? cue.plainText : cue.rawText
    }

    private static func plainSourceText(for cue: SubtitleCue) -> String {
        cue.plainText.isEmpty ? sourceText(for: cue) : cue.plainText
    }

    private static func updateCue(
        _ cue: SubtitleCue,
        raw: String,
        plain: String
    ) -> SubtitleCue? {
        let normalizedRaw = normalizeMultilineText(raw)
        let normalizedPlain = normalizeMultilineText(plain)
        let resolvedRaw = normalizedRaw.isEmpty ? normalizedPlain : normalizedRaw

        var resolvedPlain = normalizedPlain.isEmpty ? normalizedRaw : normalizedPlain
        if resolvedPlain.isEmpty {
            resolvedPlain = StringTransforms.stripTags(resolvedRaw)
        }

        guard !resolvedRaw.isEmpty || !resolvedPlain.isEmpty else {
            return nil
        }

        var next = cue
        next.rawText = resolvedRaw
        next.plainText = resolvedPlain.isEmpty ? resolvedRaw : resolvedPlain
        return next
    }

    private static func normalizeMultilineText(_ text: String) -> String {
        StringTransforms.lines(text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeSingleLineText(_ text: String) -> String {
        StringTransforms.replacing(pattern: #"\s+"#, in: text, with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removingSDH(from text: String) -> String {
        let withoutSquare = StringTransforms.replacing(pattern: #"\[[^\]\n]{1,120}\]"#, in: text, with: "")
        let withoutRound = StringTransforms.replacing(pattern: #"\((?:[^)\n]{1,120})\)"#, in: withoutSquare, with: "")
        return StringTransforms.replacing(pattern: #"\s{2,}"#, in: withoutRound, with: " ")
    }

    private static func removingWatermarkLines(from text: String) -> String {
        let lines = StringTransforms.lines(text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !isWatermarkLine($0) }
            .filter { !$0.isEmpty }
        return lines.joined(separator: "\n")
    }

    private static func isWatermarkLine(_ line: String) -> Bool {
        guard !line.isEmpty else {
            return false
        }
        let patterns = [
            #"(?:https?://|www\.)\S+"#,
            #"[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}"#,
            #"\b(?:subtitles?\s+by|synced?\s+by|sync\s+by|translated\s+by|downloaded\s+from|opensubtitles|subscene|addic7ed)\b"#
        ]

        return patterns.contains { pattern in
            StringTransforms.replacing(pattern: pattern, in: line, with: "", regexOptions: [.caseInsensitive]) != line
        }
    }

    private static func removingSpeakerLabels(from text: String) -> String {
        StringTransforms.lines(text)
            .map { line in
                StringTransforms.replacing(
                    pattern: #"^\s*(?:>>\s*)?(?:[A-Z][A-Z0-9 .'\-]{1,40}|[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2})\s*:\s*"#,
                    in: line,
                    with: "",
                    regexOptions: []
                )
            }
            .joined(separator: "\n")
    }

    private static func containsMusicNotes(_ text: String) -> Bool {
        text.contains { character in
            character == "♪" || character == "♫" || character == "♬" || character == "♩"
        }
    }

    private static func removingLineBreaks(from text: String) -> String {
        let joined = StringTransforms.lines(text)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return normalizeSingleLineText(joined)
    }

    private static func fixingUppercaseText(in text: String) -> String {
        guard isMostlyUppercase(text) else {
            return text
        }

        let lowercased = text.lowercased()
        var output = ""
        var shouldCapitalize = true

        for character in lowercased {
            if shouldCapitalize, isLetter(character) {
                output += String(character).uppercased()
                shouldCapitalize = false
            } else {
                output.append(character)
            }

            if character == "." || character == "!" || character == "?" || character == "\n" {
                shouldCapitalize = true
            }
        }

        return output
    }

    private static func isMostlyUppercase(_ text: String) -> Bool {
        let letters = text.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        guard letters.count >= 3 else {
            return false
        }

        let uppercaseCount = letters.count(where: { scalar in
            let string = String(scalar)
            return string == string.uppercased() && string != string.lowercased()
        })

        return Double(uppercaseCount) / Double(letters.count) >= 0.8
    }

    private static func isLetter(_ character: Character) -> Bool {
        character.unicodeScalars.contains { CharacterSet.letters.contains($0) }
    }

    private static func removingCurlyBracketTags(from text: String) -> String {
        StringTransforms.replacing(pattern: #"\{[^}\n]+\}"#, in: text, with: "")
    }

    private static func removingHTMLTags(from text: String) -> String {
        StringTransforms.replacing(pattern: #"<[^>\n]+>"#, in: text, with: "")
    }

    private static func mergingCuesWithSameText(
        in document: SubtitleDocument,
        tracker: inout ChangeTracker
    ) -> SubtitleDocument {
        var mergedEntries = [SubtitleEntry]()

        for entry in document.entries {
            guard case let .cue(incomingCue) = entry else {
                mergedEntries.append(entry)
                continue
            }

            guard let lastEntry = mergedEntries.last,
                  case let .cue(previousCue) = lastEntry,
                  canMerge(previousCue, incomingCue) else {
                mergedEntries.append(.cue(incomingCue))
                continue
            }

            var updated = previousCue
            updated.endTime = max(previousCue.endTime, incomingCue.endTime)

            if let previousFrame = previousCue.frameRange, let incomingFrame = incomingCue.frameRange {
                updated.frameRange = .init(
                    start: min(previousFrame.start, incomingFrame.start),
                    end: max(previousFrame.end, incomingFrame.end)
                )
            }

            if updated != previousCue {
                tracker.noteModified(cueID: previousCue.id, by: .mergeCuesWithSameText)
            }
            tracker.noteRemoved(cueID: incomingCue.id, by: .mergeCuesWithSameText)
            mergedEntries[mergedEntries.count - 1] = .cue(updated)
        }

        var updated = document
        updated.entries = mergedEntries
        return updated
    }

    private static func canMerge(_ lhs: SubtitleCue, _ rhs: SubtitleCue) -> Bool {
        guard lhs.startTime <= rhs.startTime else {
            return false
        }
        guard rhs.startTime <= lhs.endTime else {
            return false
        }
        return normalizedTextForMerge(lhs) == normalizedTextForMerge(rhs)
    }

    private static func normalizedTextForMerge(_ cue: SubtitleCue) -> String {
        normalizeSingleLineText(plainSourceText(for: cue))
    }

    private static func buildReport(
        originalCues: [SubtitleCue],
        cleanedDocument: SubtitleDocument,
        tracker: ChangeTracker
    ) -> SubtitleCleanReport {
        let cleanedByID = Dictionary(uniqueKeysWithValues: cleanedDocument.cues.map { ($0.id, $0) })

        let changes = originalCues.map { originalCue -> SubtitleCleanReport.CueChange in
            let changedBy = orderedOptions(from: tracker.options(for: originalCue.id))
            guard let cleanedCue = cleanedByID[originalCue.id] else {
                return .init(
                    cueID: originalCue.id,
                    status: .removed,
                    original: originalCue,
                    cleaned: nil,
                    changedBy: changedBy
                )
            }

            let status: SubtitleCleanReport.Status =
                (cleanedCue == originalCue && changedBy.isEmpty) ? .unchanged : .modified

            return .init(
                cueID: originalCue.id,
                status: status,
                original: originalCue,
                cleaned: cleanedCue,
                changedBy: changedBy
            )
        }

        return .init(
            originalCueCount: originalCues.count,
            remainingCueCount: cleanedDocument.cues.count,
            changes: changes
        )
    }

    private static func orderedOptions(from options: Set<SubtitleCleanOption>) -> [SubtitleCleanOption] {
        SubtitleCleanOption.allCases.filter(options.contains)
    }
}
