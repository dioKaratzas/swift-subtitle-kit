import Foundation

struct LRCAdapter: SubtitleFormatAdapter {
    let format: SubtitleFormat = .lrc

    func canParse(_ content: String) -> Bool {
        let text = TextSanitizer.stripByteOrderMark(from: content)
        return text.range(of: #"\n\[\d+:\d{1,2}(?:[\.,]\d{1,3})?\].*\n"#, options: .regularExpression) != nil
    }

    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let lines = StringTransforms.lines(normalized)
        var entries: [SubtitleEntry] = []
        var previousCueIndex: Int?
        var entryID = 1

        let lyricRegex = try NSRegularExpression(pattern: #"^\[(\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?)\](.*)$"#)
        let metaRegex = try NSRegularExpression(pattern: #"^\[(\w+):([^\]]*)\]$"#)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if let match = RegexUtils.firstMatch(lyricRegex, in: line),
               let timeValue = RegexUtils.string(line, at: 1, in: match) {
                let start = try TimestampCodec.parseLRC(timeValue)
                let textValue = RegexUtils.string(line, at: 2, in: match) ?? ""
                let cue = SubtitleCue(
                    id: entryID,
                    startTime: start,
                    endTime: start + 2000,
                    rawText: textValue,
                    plainText: textValue
                )

                if let previousCueIndex, case let .cue(previous) = entries[previousCueIndex] {
                    var updated = previous
                    updated.endTime = start
                    entries[previousCueIndex] = .cue(updated)
                }

                entries.append(.cue(cue))
                previousCueIndex = entries.count - 1
                entryID += 1
                continue
            }

            if let match = RegexUtils.firstMatch(metaRegex, in: line),
               let key = RegexUtils.string(line, at: 1, in: match) {
                let value = RegexUtils.string(line, at: 2, in: match) ?? ""
                entries.append(.metadata(SubtitleMetadata(id: entryID, key: key, value: .text(value))))
                entryID += 1
                continue
            }

            throw SubtitleError.malformedBlock(format: .lrc, details: line)
        }

        return SubtitleDocument(format: .lrc, entries: entries)
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let eol = options.lineEnding.value
        var lines: [String] = []
        var wroteLyrics = false

        for entry in document.entries {
            switch entry {
            case let .metadata(meta):
                if case let .text(value) = meta.value {
                    lines.append("[\(meta.key):\(value.replacingOccurrences(of: "\n", with: " "))]")
                }
            case let .cue(cue):
                if !wroteLyrics {
                    lines.append("")
                    wroteLyrics = true
                }
                lines.append("[\(TimestampCodec.formatLRC(cue.startTime))]\(StringTransforms.cueText(from: cue))")
            case .style:
                continue
            }
        }

        return lines.joined(separator: eol) + (lines.isEmpty ? "" : eol)
    }
}
