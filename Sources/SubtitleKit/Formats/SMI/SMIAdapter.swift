import Foundation

/// SAMI (`.smi`) subtitle format adapter.
public struct SMIFormat: SubtitleFormat {
    public let name = "smi"

    public func canParse(_ content: String) -> Bool {
        let text = TextSanitizer.stripByteOrderMark(from: content)
        return text.range(of: #"<SAMI[^>]*>[\s\S]*<BODY[^>]*>"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let normalized = TextSanitizer.stripByteOrderMark(from: content)
        let eol = "\n"
        var entries: [SubtitleEntry] = []
        var entryID = 1

        if let title = firstCapture(#"<TITLE[^>]*>([\s\S]*?)</TITLE>"#, in: normalized, options: [.caseInsensitive]) {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            entries.append(.metadata(.init(id: entryID, key: "title", value: .text(trimmed))))
            entryID += 1
        }

        if let style = firstCapture(#"<STYLE[^>]*>([\s\S]*?)</STYLE>"#, in: normalized, options: [.caseInsensitive]) {
            entries.append(.metadata(.init(id: entryID, key: "style", value: .text(style))))
            entryID += 1
        }

        let body = normalized
            .replacingOccurrences(of: #"^[\s\S]*<BODY[^>]*>"#, with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: #"</BODY[^>]*>[\s\S]*$"#, with: "", options: [.regularExpression, .caseInsensitive])

        var previousCueSlot: Int?
        let syncParts = body.components(separatedBy: "<SYNC")

        for rawPart in syncParts where !rawPart.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let part = "<SYNC" + rawPart
            guard let regex = try? NSRegularExpression(pattern: #"^<SYNC[^>]+Start\s*=\s*[\"']?(\d+)[^\d>]*>([\s\S]*)"#, options: [.caseInsensitive]),
                  let match = RegexUtils.firstMatch(regex, in: part),
                  let startValue = RegexUtils.string(part, at: 1, in: match),
                  let start = Int(startValue)
            else {
                throw SubtitleError.malformedBlock(format: "smi", details: part)
            }

            var cue = SubtitleCue(
                id: entryID,
                startTime: start,
                endTime: start + 2000,
                rawText: "",
                plainText: ""
            )

            let contentValue = RegexUtils.string(part, at: 2, in: match) ?? ""
                .replacingOccurrences(of: #"^</SYNC[^>]*>"#, with: "", options: [.regularExpression, .caseInsensitive])
            cue.rawText = contentValue

            let pRegex = try? NSRegularExpression(pattern: #"^<P[^>]*>([\s\S]*)"#, options: [.caseInsensitive])
            var blankCaption = true
            let pSource = contentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if let pRegex, let pMatch = RegexUtils.firstMatch(pRegex, in: pSource) {
                var html = RegexUtils.string(pSource, at: 1, in: pMatch) ?? ""
                html = html.replacingOccurrences(of: #"<P[\s\S]+$"#, with: "", options: [.regularExpression, .caseInsensitive])
                html = html.replacingOccurrences(of: #"<BR\s*/?>\s+"#, with: eol, options: [.regularExpression, .caseInsensitive])
                html = html.replacingOccurrences(of: #"<BR\s*/?>"#, with: eol, options: [.regularExpression, .caseInsensitive])
                html = html.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
                html = html.trimmingCharacters(in: .whitespacesAndNewlines)
                blankCaption = html.replacingOccurrences(of: "&nbsp;", with: " ", options: [.caseInsensitive]).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                cue.plainText = decodeHTML(html, eol: eol)
            }

            if let previousCueSlot, case let .cue(previousCue) = entries[previousCueSlot] {
                var updated = previousCue
                updated.endTime = start
                entries[previousCueSlot] = .cue(updated)
            }

            if options.preserveWhitespaceCaptions || !blankCaption {
                entries.append(.cue(cue))
                previousCueSlot = entries.count - 1
                entryID += 1
            } else {
                previousCueSlot = nil
            }
        }

        return SubtitleDocument(formatName: "smi", entries: entries)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let eol = options.lineEnding.value
        var output: [String] = []

        output.append("<SAMI>")
        output.append("<HEAD>")
        output.append("<TITLE>\(options.samiTitle ?? "")</TITLE>")
        output.append("<STYLE TYPE=\"text/css\">")
        output.append("<!--")
        output.append("P { font-family: Arial; font-weight: normal; color: white; background-color: black; text-align: center; }")
        output.append(".LANG { Name: \(options.samiLanguageName); lang: \(options.samiLanguageCode); SAMIType: CC; }")
        output.append("-->")
        output.append("</STYLE>")
        output.append("</HEAD>")
        output.append("<BODY>")

        for cue in document.cues {
            let cueText = cue.plainText.isEmpty ? StringTransforms.cueText(from: cue) : cue.plainText
            output.append("<SYNC Start=\(cue.startTime)>")
            output.append("  <P Class=LANG>\(encodeHTML(cueText))\(options.closeSMITags ? "</P>" : "")")
            if options.closeSMITags {
                output.append("</SYNC>")
            }

            output.append("<SYNC Start=\(cue.endTime)>")
            output.append("  <P Class=LANG>&nbsp;\(options.closeSMITags ? "</P>" : "")")
            if options.closeSMITags {
                output.append("</SYNC>")
            }
        }

        output.append("</BODY>")
        output.append("</SAMI>")

        return output.joined(separator: eol) + eol
    }

    private func firstCapture(_ pattern: String, in text: String, options: NSRegularExpression.Options = []) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options),
              let match = RegexUtils.firstMatch(regex, in: text)
        else {
            return nil
        }
        return RegexUtils.string(text, at: 1, in: match)
    }

    private func encodeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n", with: "<BR>")
    }

    private func decodeHTML(_ text: String, eol: String) -> String {
        text
            .replacingOccurrences(of: #"<BR\s*/?>"#, with: eol, options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
