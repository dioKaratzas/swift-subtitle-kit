//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation

/// SubRip (`.srt`) subtitle format adapter.
public struct SRTFormat: SubtitleFormat {
    public let name = "srt"

    public func canParse(_ content: String) -> Bool {
        content.range(
            of: #"\d+\s*\n\s*\d{1,2}:\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?\s*-->\s*\d{1,2}:\d{1,2}:\d{1,2}(?:[\.,]\d{1,3})?"#,
            options: .regularExpression
        ) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument {
        let lines = StringTransforms.lines(content)
        var cues = [SubtitleEntry]()
        var nextAutoID = 1
        var cursor = 0

        while cursor < lines.count {
            while cursor < lines.count, lines[cursor].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                cursor += 1
            }
            guard cursor < lines.count else {
                break
            }

            var timingLineIndex = cursor
            var cueID = nextAutoID

            if cursor + 1 < lines.count,
               let parsedIndex = Int(lines[cursor].trimmingCharacters(in: .whitespaces)),
               Self.isTimingLine(lines[cursor + 1]) {
                cueID = parsedIndex
                timingLineIndex = cursor + 1
            }

            guard timingLineIndex < lines.count else {
                throw SubtitleError.malformedBlock(format: "srt", details: lines[cursor])
            }

            let timingLine = lines[timingLineIndex]
            let (start, end) = try Self.parseTimingLine(timingLine)

            var textLines = [String]()
            var nextCursor = timingLineIndex + 1

            while nextCursor < lines.count {
                let line = lines[nextCursor]
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    while nextCursor < lines.count,
                          lines[nextCursor].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        nextCursor += 1
                    }
                    break
                }
                if Self.isCueBoundary(lines, at: nextCursor) {
                    break
                }
                textLines.append(line)
                nextCursor += 1
            }

            let rawText = textLines.joined(separator: "\n")

            let cue = SubtitleCue(
                id: cueID,
                startTime: start,
                endTime: end,
                rawText: rawText,
                plainText: StringTransforms.stripSpeakerPrefix(StringTransforms.stripTags(rawText))
            )
            cues.append(.cue(cue))
            nextAutoID += 1
            cursor = nextCursor
        }

        return SubtitleDocument(formatName: "srt", entries: cues)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        let eol = options.lineEnding.value
        let cues = document.entries.compactMap { entry -> SubtitleCue? in
            if case let .cue(cue) = entry {
                return cue
            }
            return nil
        }

        var output = [String]()
        for (idx, cue) in cues.enumerated() {
            output.append(String(idx + 1))
            output.append("\(TimestampCodec.formatSRT(cue.startTime)) --> \(TimestampCodec.formatSRT(cue.endTime))")
            output.append(StringTransforms.cueText(from: cue))
            output.append("")
        }

        return output.joined(separator: eol)
    }
}

private extension SRTFormat {
    static func isCueBoundary(_ lines: [String], at index: Int) -> Bool {
        guard index < lines.count else {
            return false
        }
        if isTimingLine(lines[index]) {
            return true
        }
        if index + 1 < lines.count,
           Int(lines[index].trimmingCharacters(in: .whitespaces)) != nil,
           isTimingLine(lines[index + 1]) {
            return true
        }
        return false
    }

    static func isTimingLine(_ line: String) -> Bool {
        (try? parseTimingLine(line)) != nil
    }

    static func parseTimingLine(_ line: String) throws(SubtitleError) -> (Int, Int) {
        let timingParts = line.components(separatedBy: "-->")
        guard timingParts.count == 2 else {
            throw SubtitleError.malformedBlock(format: "srt", details: line)
        }

        let start = try TimestampCodec.parseSRT(timingParts[0])
        let end = try TimestampCodec.parseSRT(timingParts[1])
        return (start, end)
    }
}
