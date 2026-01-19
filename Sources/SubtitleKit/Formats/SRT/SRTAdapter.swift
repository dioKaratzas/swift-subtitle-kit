import Foundation

public struct SRTFormat: SubtitleFormat {
    public let name = "srt"

    public func canParse(_ content: String) -> Bool {
        let text = TextSanitizer.stripByteOrderMark(from: content)
        return text.range(of: #"\d+\s*\n\s*\d{1,2}:\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?\s*-->\s*\d{1,2}:\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?"#, options: .regularExpression) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let blocks = StringTransforms.splitBlocks(normalized)
        var cues: [SubtitleEntry] = []
        var index = 1

        for block in blocks {
            let lines = StringTransforms.lines(block)
            guard !lines.isEmpty else { continue }

            var timingLineIndex = 0
            var cueID = index

            if let parsedIndex = Int(lines[0].trimmingCharacters(in: .whitespaces)), lines.count > 1 {
                cueID = parsedIndex
                timingLineIndex = 1
            }

            guard timingLineIndex < lines.count else {
                throw SubtitleError.malformedBlock(format: "srt", details: block)
            }

            let timingLine = lines[timingLineIndex]
            let timingParts = timingLine.components(separatedBy: "-->")
            guard timingParts.count == 2 else {
                throw SubtitleError.malformedBlock(format: "srt", details: timingLine)
            }

            let start = try TimestampCodec.parseSRT(timingParts[0])
            let end = try TimestampCodec.parseSRT(timingParts[1])
            let textLines = Array(lines.dropFirst(timingLineIndex + 1))
            let rawText = textLines.joined(separator: "\n")

            let cue = SubtitleCue(
                id: cueID,
                startTime: start,
                endTime: end,
                rawText: rawText,
                plainText: StringTransforms.stripSpeakerPrefix(StringTransforms.stripTags(rawText))
            )
            cues.append(.cue(cue))
            index += 1
        }

        return SubtitleDocument(formatName: "srt", entries: cues)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let eol = options.lineEnding.value
        let cues = document.entries.compactMap { entry -> SubtitleCue? in
            if case let .cue(cue) = entry {
                return cue
            }
            return nil
        }

        var output: [String] = []
        for (idx, cue) in cues.enumerated() {
            output.append(String(idx + 1))
            output.append("\(TimestampCodec.formatSRT(cue.startTime)) --> \(TimestampCodec.formatSRT(cue.endTime))")
            output.append(StringTransforms.cueText(from: cue))
            output.append("")
        }

        return output.joined(separator: eol)
    }
}
