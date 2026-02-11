import Foundation

/// WebVTT (`.vtt`) subtitle format adapter.
public struct VTTFormat: SubtitleFormat {
    public let name = "vtt"

    public func canParse(_ content: String) -> Bool {
        let text = TextSanitizer.stripByteOrderMark(from: content)
        return text.range(of: #"^\s*WEBVTT"#, options: [.regularExpression]) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let blocks = StringTransforms.splitBlocks(normalized)
        var entries: [SubtitleEntry] = []
        var cueIndex = 1
        var entryIndex = 1

        for block in blocks {
            let lines = StringTransforms.lines(block)
            guard !lines.isEmpty else { continue }

            if lines[0].trimmingCharacters(in: .whitespacesAndNewlines).uppercased().hasPrefix("WEBVTT") {
                entries.append(.metadata(SubtitleMetadata(id: entryIndex, key: "WEBVTT", value: .text(lines.joined(separator: "\n")))))
                entryIndex += 1
                continue
            }

            let timingRegex = try NSRegularExpression(
                pattern: #"^\s*(?:\d{1,2}:)?\d{1,2}:\d{1,2}(?:[.,]\d{1,3})?\s*-->\s*(?:\d{1,2}:)?\d{1,2}:\d{1,2}(?:[.,]\d{1,3})?.*$"#
            )
            let timingIndex = lines.firstIndex { line in
                RegexUtils.firstMatch(timingRegex, in: line) != nil
            }

            if let timingIndex, timingIndex < lines.count {
                let timingLine = lines[timingIndex]
                let parts = timingLine.components(separatedBy: "-->")
                guard parts.count == 2 else {
                    throw SubtitleError.malformedBlock(format: "vtt", details: timingLine)
                }

                let start = try TimestampCodec.parseVTT(parts[0])
                let rhs = parts[1].trimmingCharacters(in: .whitespaces)
                let rhsPieces = rhs.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                guard let endToken = rhsPieces.first else {
                    throw SubtitleError.malformedBlock(format: "vtt", details: timingLine)
                }
                let end = try TimestampCodec.parseVTT(String(endToken))

                let cueIdentifier = timingIndex > 0 ? lines[0..<timingIndex].joined(separator: "\n") : nil
                let settings = rhsPieces.count > 1 ? String(rhsPieces[1]) : nil
                let textLines = Array(lines.dropFirst(timingIndex + 1))
                let rawText = textLines.joined(separator: "\n")

                var attributes: [SubtitleAttribute] = []
                if let settings, !settings.isEmpty {
                    attributes.append(.init(key: "settings", value: settings))
                }

                let cue = SubtitleCue(
                    id: cueIndex,
                    cueIdentifier: cueIdentifier,
                    startTime: start,
                    endTime: end,
                    rawText: rawText,
                    plainText: StringTransforms.stripTags(rawText),
                    attributes: attributes
                )
                entries.append(.cue(cue))
                cueIndex += 1
                entryIndex += 1
                continue
            }

            if let meta = parseMetadata(block: block, id: entryIndex) {
                entries.append(.metadata(meta))
                entryIndex += 1
                continue
            }

            // WebVTT allows additional blocks (comments/regions/custom blocks). Keep parser permissive.
            continue
        }

        return SubtitleDocument(formatName: "vtt", entries: entries)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let eol = options.lineEnding.value
        var blocks: [String] = ["WEBVTT"]

        for entry in document.entries {
            switch entry {
            case let .metadata(meta):
                if meta.key == "WEBVTT" { continue }
                blocks.append(serializeMetadata(meta))
            case let .cue(cue):
                var lines: [String] = []
                if let cueIdentifier = cue.cueIdentifier, !cueIdentifier.isEmpty {
                    lines.append(cueIdentifier)
                }
                let settings = cue.attributes.first(where: { $0.key == "settings" })?.value
                let timing = "\(TimestampCodec.formatVTT(cue.startTime)) --> \(TimestampCodec.formatVTT(cue.endTime))" + (settings.map { " \($0)" } ?? "")
                lines.append(timing)
                lines.append(StringTransforms.cueText(from: cue))
                blocks.append(lines.joined(separator: eol))
            case .style:
                continue
            }
        }

        return blocks.joined(separator: eol + eol) + eol
    }

    private func parseMetadata(block: String, id: Int) -> SubtitleMetadata? {
        let lines = StringTransforms.lines(block)
        guard let firstLine = lines.first else { return nil }

        let first = firstLine.trimmingCharacters(in: .whitespaces)
        if let range = first.range(of: " ") {
            let key = String(first[..<range.lowerBound])
            let value = String(first[range.upperBound...])
            if key.range(of: #"^[A-Za-z]+$"#, options: .regularExpression) != nil {
                return SubtitleMetadata(id: id, key: key, value: .text(value))
            }
        }

        if first.range(of: #"^[A-Za-z][A-Za-z ]*$"#, options: .regularExpression) != nil {
            let remainder = lines.dropFirst().joined(separator: "\n")
            return SubtitleMetadata(id: id, key: first, value: .text(remainder))
        }

        return nil
    }

    private func serializeMetadata(_ metadata: SubtitleMetadata) -> String {
        switch metadata.value {
        case let .text(value):
            if value.isEmpty {
                return metadata.key
            }
            return metadata.key + "\n" + value
        case let .fields(fields):
            let body = fields.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            return metadata.key + (body.isEmpty ? "" : "\n\(body)")
        }
    }
}
