//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation

struct SubtitleNormalizationResult: Sendable, Hashable {
    var text: String
    var lineEnding: LineEnding
    var hadByteOrderMark: Bool
}

enum SubtitleNormalizer {
    static func normalizeInput(_ text: String) -> SubtitleNormalizationResult {
        let hadBOM = text.unicodeScalars.first == "\u{FEFF}"
        let stripped = stripByteOrderMark(text)
        let lineEnding = inferLineEnding(stripped)
        return SubtitleNormalizationResult(text: stripped, lineEnding: lineEnding, hadByteOrderMark: hadBOM)
    }

    static func stripByteOrderMark(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{FEFF}", with: "")
    }

    static func inferLineEnding(_ text: String) -> LineEnding {
        text.contains("\r\n") ? .crlf : .lf
    }
}
