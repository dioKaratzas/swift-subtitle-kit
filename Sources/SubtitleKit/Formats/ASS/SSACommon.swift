import Foundation

enum SSACommon {
    static func parse(_ content: String, hintedFormat: SubtitleFormat) throws -> SubtitleDocument {
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let blocks = StringTransforms.splitBlocks(normalized)

        var entries: [SubtitleEntry] = []
        var cueIndex = 1
        var entryIndex = 1

        for block in blocks {
            let lines = StringTransforms.lines(block)
            guard let header = lines.first?.trimmingCharacters(in: .whitespaces),
                  header.hasPrefix("["),
                  header.hasSuffix("]")
            else {
                continue
            }

            let section = String(header.dropFirst().dropLast())
            let bodyLines = Array(lines.dropFirst())

            switch section {
            case "Script Info":
                let fields = parseKeyValueLines(bodyLines)
                entries.append(.metadata(SubtitleMetadata(id: entryIndex, key: "Script Info", value: .fields(fields))))
                entryIndex += 1

            case "V4 Styles", "V4+ Styles":
                var columns: [String] = []
                for line in bodyLines {
                    guard let pair = splitNamedLine(line) else { continue }
                    if pair.name.caseInsensitiveCompare("Format") == .orderedSame {
                        columns = pair.value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                    } else if pair.name.caseInsensitiveCompare("Style") == .orderedSame, !columns.isEmpty {
                        let values = splitCommaValues(pair.value, limit: columns.count)
                        let fields = zip(columns, values).map { SubtitleAttribute(key: $0.0, value: $0.1) }
                        let styleName = fields.first(where: { $0.key.caseInsensitiveCompare("Name") == .orderedSame })?.value ?? "Style"
                        entries.append(.style(.init(id: entryIndex, name: styleName, fields: fields)))
                        entryIndex += 1
                    }
                }

            case "Events":
                var columns: [String] = []
                for line in bodyLines {
                    guard let pair = splitNamedLine(line) else { continue }
                    if pair.name.caseInsensitiveCompare("Format") == .orderedSame {
                        columns = pair.value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        continue
                    }
                    guard pair.name.caseInsensitiveCompare("Dialogue") == .orderedSame else { continue }
                    guard !columns.isEmpty else {
                        throw SubtitleError.malformedBlock(format: hintedFormat, details: "Missing Events format line")
                    }

                    let values = splitCommaValues(pair.value, limit: columns.count)
                    let fields = zip(columns, values).map { SubtitleAttribute(key: $0.0, value: $0.1) }

                    guard let startValue = field("Start", in: fields), let endValue = field("End", in: fields) else {
                        throw SubtitleError.malformedBlock(format: hintedFormat, details: line)
                    }

                    let start = try TimestampCodec.parseSSA(startValue)
                    let end = try TimestampCodec.parseSSA(endValue)
                    let rawText = field("Text", in: fields) ?? ""
                    let plainText = StringTransforms.replacing(pattern: #"\\N"#, in: StringTransforms.stripTags(rawText), with: "\n")

                    let cue = SubtitleCue(
                        id: cueIndex,
                        startTime: start,
                        endTime: end,
                        rawText: rawText,
                        plainText: plainText,
                        attributes: fields
                    )
                    entries.append(.cue(cue))
                    cueIndex += 1
                    entryIndex += 1
                }

            default:
                let text = bodyLines.joined(separator: "\n")
                entries.append(.metadata(.init(id: entryIndex, key: section, value: .text(text))))
                entryIndex += 1
            }
        }

        return SubtitleDocument(format: hintedFormat, entries: entries)
    }

    static func serialize(_ document: SubtitleDocument, format: SubtitleFormat, lineEnding: LineEnding) -> String {
        let eol = lineEnding.value
        let isASS = format == .ass

        var scriptInfoLines = ["ScriptType: v4.00" + (isASS ? "+" : ""), "Collisions: Normal"]
        if let scriptInfo = document.entries.compactMap(scriptInfoMetadata).first {
            scriptInfoLines = scriptInfo.map { "\($0.key): \($0.value)" }
        }

        let styles = document.entries.compactMap { entry -> SubtitleStyle? in
            if case let .style(style) = entry {
                return style
            }
            return nil
        }

        var output: [String] = []
        output.append("[Script Info]")
        output.append("; Script generated by SubtitleKit")
        output.append(contentsOf: scriptInfoLines)
        output.append("")

        if isASS {
            output.append("[V4+ Styles]")
            output.append("Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding")
            if styles.isEmpty {
                output.append("Style: DefaultVCD, Arial,28,&H00B4FCFC,&H00B4FCFC,&H00000008,&H80000008,-1,0,0,0,100,100,0.00,0.00,1,1.00,2.00,2,30,30,30,0")
            } else {
                output.append(contentsOf: styles.map(styleLine(from:)))
            }
        } else {
            output.append("[V4 Styles]")
            output.append("Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding")
            if styles.isEmpty {
                output.append("Style: DefaultVCD, Arial,28,11861244,11861244,11861244,-2147483640,-1,0,1,1,2,2,30,30,30,0,0")
            } else {
                output.append(contentsOf: styles.map(styleLine(from:)))
            }
        }

        output.append("")
        output.append("[Events]")
        let eventColumns = isASS
            ? ["Layer", "Start", "End", "Style", "Name", "MarginL", "MarginR", "MarginV", "Effect", "Text"]
            : ["Marked", "Start", "End", "Style", "Name", "MarginL", "MarginR", "MarginV", "Effect", "Text"]
        output.append("Format: " + eventColumns.joined(separator: ", "))

        for cue in document.cues {
            let attributes = cue.attributes
            var values: [String] = []
            for column in eventColumns {
                switch column {
                case "Start":
                    values.append(TimestampCodec.formatSSA(cue.startTime))
                case "End":
                    values.append(TimestampCodec.formatSSA(cue.endTime))
                case "Text":
                    values.append(StringTransforms.cueText(from: cue).replacingOccurrences(of: "\n", with: "\\N"))
                case "Layer":
                    values.append(field("Layer", in: attributes) ?? "0")
                case "Marked":
                    values.append(field("Marked", in: attributes) ?? "Marked=0")
                case "Style":
                    values.append(field("Style", in: attributes) ?? "DefaultVCD")
                case "Name":
                    values.append(field("Name", in: attributes) ?? "NTP")
                case "MarginL":
                    values.append(field("MarginL", in: attributes) ?? "0000")
                case "MarginR":
                    values.append(field("MarginR", in: attributes) ?? "0000")
                case "MarginV":
                    values.append(field("MarginV", in: attributes) ?? "0000")
                case "Effect":
                    values.append(field("Effect", in: attributes) ?? "")
                default:
                    values.append(field(column, in: attributes) ?? "")
                }
            }
            output.append("Dialogue: " + values.joined(separator: ","))
        }

        return output.joined(separator: eol) + eol
    }

    static func isASSContent(_ content: String) -> Bool {
        content.range(of: #"^\s*\[Script Info\]"#, options: .regularExpression) != nil
            && content.range(of: #"\[Events\]"#, options: .regularExpression) != nil
            && content.contains("[V4+ Styles]")
    }

    static func isSSAContent(_ content: String) -> Bool {
        content.range(of: #"^\s*\[Script Info\]"#, options: .regularExpression) != nil
            && content.range(of: #"\[Events\]"#, options: .regularExpression) != nil
            && !content.contains("[V4+ Styles]")
    }

    private static func splitNamedLine(_ line: String) -> (name: String, value: String)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix(";") else {
            return nil
        }
        guard let separator = trimmed.firstIndex(of: ":") else {
            return nil
        }
        let name = String(trimmed[..<separator]).trimmingCharacters(in: .whitespaces)
        let value = String(trimmed[trimmed.index(after: separator)...]).trimmingCharacters(in: .whitespaces)
        return (name, value)
    }

    private static func parseKeyValueLines(_ lines: [String]) -> [SubtitleAttribute] {
        lines.compactMap(splitNamedLine).map { SubtitleAttribute(key: $0.name, value: $0.value) }
    }

    private static func splitCommaValues(_ value: String, limit: Int) -> [String] {
        guard limit > 1 else { return [value] }
        var parts: [String] = []
        var remaining = value[...]

        for _ in 0..<(limit - 1) {
            guard let comma = remaining.firstIndex(of: ",") else { break }
            let part = remaining[..<comma]
            parts.append(String(part).trimmingCharacters(in: .whitespaces))
            remaining = remaining[remaining.index(after: comma)...]
        }

        parts.append(String(remaining).trimmingCharacters(in: .whitespaces))

        if parts.count < limit {
            parts.append(contentsOf: Array(repeating: "", count: limit - parts.count))
        }

        return parts
    }

    private static func field(_ key: String, in fields: [SubtitleAttribute]) -> String? {
        fields.first(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame })?.value
    }

    private static func scriptInfoMetadata(_ entry: SubtitleEntry) -> [SubtitleAttribute]? {
        guard case let .metadata(meta) = entry,
              meta.key.caseInsensitiveCompare("Script Info") == .orderedSame,
              case let .fields(fields) = meta.value
        else {
            return nil
        }
        return fields
    }

    private static func styleLine(from style: SubtitleStyle) -> String {
        let values = style.fields.map(\.value).joined(separator: ",")
        return "Style: " + values
    }
}
