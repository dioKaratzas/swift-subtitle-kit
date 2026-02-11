import Foundation

enum TextSanitizer {
    static func stripByteOrderMark(from text: String) -> String {
        guard text.unicodeScalars.first == "\u{FEFF}" else {
            return text
        }
        return String(text.unicodeScalars.dropFirst())
    }

    static func inferLineEnding(from text: String) -> LineEnding {
        text.contains("\r\n") ? .crlf : .lf
    }
}
