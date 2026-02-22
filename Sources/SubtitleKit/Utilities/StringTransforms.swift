import Foundation

enum StringTransforms {
    static func stripTags(_ text: String) -> String {
        var output = text
        output = replacing(pattern: #"<[^>]+>"#, in: output, with: "")
        output = replacing(pattern: #"\{[^}]+\}"#, in: output, with: "")
        return output
    }

    static func stripSpeakerPrefix(_ text: String) -> String {
        replacing(pattern: #">>[^:\n]*:\s*"#, in: text, with: "")
    }

    static func replacing(
        pattern: String,
        in text: String,
        with replacement: String,
        regexOptions: NSRegularExpression.Options = [.caseInsensitive]
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: regexOptions) else {
            return text
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }

    static func splitBlocks(_ text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        guard let separator = try? NSRegularExpression(pattern: #"\n\s*\n"#) else {
            return [normalized]
        }

        let fullRange = NSRange(normalized.startIndex..<normalized.endIndex, in: normalized)
        var parts: [String] = []
        var currentStart = normalized.startIndex

        separator.enumerateMatches(in: normalized, options: [], range: fullRange) { match, _, _ in
            guard let match, let range = Range(match.range, in: normalized) else {
                return
            }
            let chunk = String(normalized[currentStart..<range.lowerBound])
            parts.append(chunk)
            currentStart = range.upperBound
        }

        parts.append(String(normalized[currentStart...]))

        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func lines(_ text: String) -> [String] {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }

    static func cueText(from cue: SubtitleCue) -> String {
        cue.rawText.isEmpty ? cue.plainText : cue.rawText
    }
}
