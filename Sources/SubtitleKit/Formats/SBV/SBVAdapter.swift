import Foundation

/// SubViewer (`.sbv`) subtitle format adapter.
public struct SBVFormat: SubtitleFormat {
    public let name = "sbv"

    public func canParse(_ content: String) -> Bool {
        let text = TextSanitizer.stripByteOrderMark(from: content)
        return text.range(of: #"\d{1,2}:\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?\s*[,;]\s*\d{1,2}:\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?"#, options: .regularExpression) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let blocks = StringTransforms.splitBlocks(normalized)
        var entries: [SubtitleEntry] = []

        for (index, block) in blocks.enumerated() {
            let lines = StringTransforms.lines(block)
            guard let timingLine = lines.first else { continue }

            let timingParts = timingLine.components(separatedBy: CharacterSet(charactersIn: ",;"))
            guard timingParts.count == 2 else {
                throw SubtitleError.malformedBlock(format: "sbv", details: timingLine)
            }

            let start = try TimestampCodec.parseSBV(timingParts[0])
            let end = try TimestampCodec.parseSBV(timingParts[1])
            let textLines = Array(lines.dropFirst()).map {
                $0.replacingOccurrences(of: "[br]", with: "\n", options: [.caseInsensitive])
            }
            let rawText = textLines.joined(separator: "\n")

            let cue = SubtitleCue(
                id: index + 1,
                startTime: start,
                endTime: end,
                rawText: rawText,
                plainText: StringTransforms.stripSpeakerPrefix(rawText)
            )
            entries.append(.cue(cue))
        }

        return SubtitleDocument(formatName: "sbv", entries: entries)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let eol = options.lineEnding.value
        var blocks: [String] = []

        for entry in document.entries {
            guard case let .cue(cue) = entry else { continue }
            var lines: [String] = []
            lines.append("\(TimestampCodec.formatSBV(cue.startTime)),\(TimestampCodec.formatSBV(cue.endTime))")
            lines.append(StringTransforms.cueText(from: cue))
            blocks.append(lines.joined(separator: eol))
        }

        return blocks.joined(separator: eol + eol) + (blocks.isEmpty ? "" : eol)
    }
}
