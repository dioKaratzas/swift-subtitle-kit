import Foundation

struct SubtitleNormalizationResult: Sendable, Hashable {
    var text: String
    var lineEnding: LineEnding
    var hadByteOrderMark: Bool

    init(text: String, lineEnding: LineEnding, hadByteOrderMark: Bool) {
        self.text = text
        self.lineEnding = lineEnding
        self.hadByteOrderMark = hadByteOrderMark
    }
}

enum SubtitleNormalizer {
    static func normalizeInput(_ text: String) -> SubtitleNormalizationResult {
        let hadBOM = text.unicodeScalars.first == "\u{FEFF}"
        let stripped = stripByteOrderMark(text)
        let lineEnding = inferLineEnding(stripped)
        return SubtitleNormalizationResult(text: stripped, lineEnding: lineEnding, hadByteOrderMark: hadBOM)
    }

    static func stripByteOrderMark(_ text: String) -> String {
        TextSanitizer.stripByteOrderMark(from: text)
    }

    static func inferLineEnding(_ text: String) -> LineEnding {
        TextSanitizer.inferLineEnding(from: text)
    }
}
