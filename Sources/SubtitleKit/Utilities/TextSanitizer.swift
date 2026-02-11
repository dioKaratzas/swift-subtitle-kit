import Foundation

enum TextSanitizer {
    static func stripByteOrderMark(from text: String) -> String {
        guard text.unicodeScalars.first == "\u{FEFF}" else {
            return text
        }
        return String(text.unicodeScalars.dropFirst())
    }

    static func normalizeLineEndings(_ text: String, to lineEnding: LineEnding) -> String {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        return lineEnding == .lf ? normalized : normalized.replacingOccurrences(of: "\n", with: "\r\n")
    }

    static func inferLineEnding(from text: String) -> LineEnding {
        text.contains("\r\n") ? .crlf : .lf
    }
}
