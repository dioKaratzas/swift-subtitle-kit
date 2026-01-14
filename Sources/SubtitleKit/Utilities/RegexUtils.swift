import Foundation

enum RegexUtils {
    static func firstMatch(_ regex: NSRegularExpression, in text: String) -> NSTextCheckingResult? {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range)
    }

    static func string(_ text: String, at index: Int, in match: NSTextCheckingResult) -> String? {
        guard index < match.numberOfRanges else {
            return nil
        }
        let range = match.range(at: index)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: text)
        else {
            return nil
        }
        return String(text[swiftRange])
    }
}
