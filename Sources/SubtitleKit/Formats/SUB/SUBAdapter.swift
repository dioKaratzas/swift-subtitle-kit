import Foundation

/// MicroDVD (`.sub`) subtitle format adapter.
public struct SUBFormat: SubtitleFormat {
    public let name = "sub"

    public func canParse(_ content: String) -> Bool {
        let text = TextSanitizer.stripByteOrderMark(from: content)
        guard let regex = try? NSRegularExpression(pattern: #"^\{\d+\}\{\d+\}.*$"#, options: [.anchorsMatchLines]) else {
            return false
        }
        return RegexUtils.firstMatch(regex, in: text) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let fps = try normalizedFPS(options.fps)
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let lines = StringTransforms.lines(normalized)
        var entries: [SubtitleEntry] = []

        for (index, line) in lines.enumerated() {
            guard let regex = try? NSRegularExpression(pattern: #"^\{(\d+)\}\{(\d+)\}(.*)$"#),
                  let match = RegexUtils.firstMatch(regex, in: line),
                  let startFrame = Int(RegexUtils.string(line, at: 1, in: match) ?? ""),
                  let endFrame = Int(RegexUtils.string(line, at: 2, in: match) ?? "")
            else {
                if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    continue
                }
                throw SubtitleError.malformedBlock(format: "sub", details: line)
            }

            let body = RegexUtils.string(line, at: 3, in: match) ?? ""
            let rawText = body.replacingOccurrences(of: "|", with: "\n")
            let plainText = StringTransforms.stripTags(rawText)
            let cue = SubtitleCue(
                id: index + 1,
                startTime: Int((Double(startFrame) / fps).rounded()),
                endTime: Int((Double(endFrame) / fps).rounded()),
                rawText: rawText,
                plainText: plainText,
                frameRange: .init(start: startFrame, end: endFrame)
            )
            entries.append(.cue(cue))
        }

        return SubtitleDocument(formatName: "sub", entries: entries)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let fps = try normalizedFPS(options.fps)
        let eol = options.lineEnding.value
        var lines: [String] = []

        for cue in document.cues {
            let startFrame = cue.frameRange?.start ?? Int((Double(cue.startTime) * fps).rounded())
            let endFrame = cue.frameRange?.end ?? Int((Double(cue.endTime) * fps).rounded())
            var text = StringTransforms.cueText(from: cue)
            if let newline = text.firstIndex(of: "\n") {
                text.replaceSubrange(newline...newline, with: "|")
            }
            lines.append("{\(startFrame)}{\(endFrame)}\(text)")
        }

        return lines.joined(separator: eol) + (lines.isEmpty ? "" : eol)
    }

    private func normalizedFPS(_ fps: Double?) throws -> Double {
        let value = fps ?? 25
        guard value > 0 else {
            throw SubtitleError.invalidFrameRate(value)
        }
        return value
    }
}
