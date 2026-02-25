//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation

enum RegexUtils {
    private final class RegexCacheBox: @unchecked Sendable {
        let cache = NSCache<NSString, NSRegularExpression>()
    }

    private static let cacheBox = RegexCacheBox()

    static func compiled(
        pattern: String,
        options: NSRegularExpression.Options = []
    ) -> NSRegularExpression? {
        let key = "\(options.rawValue)::\(pattern)" as NSString
        if let cached = cacheBox.cache.object(forKey: key) {
            return cached
        }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        cacheBox.cache.setObject(regex, forKey: key)
        return regex
    }

    static func firstMatch(_ regex: NSRegularExpression, in text: String) -> NSTextCheckingResult? {
        let range = NSRange(text.startIndex ..< text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range)
    }

    static func string(_ text: String, at index: Int, in match: NSTextCheckingResult) -> String? {
        guard index < match.numberOfRanges else {
            return nil
        }
        let range = match.range(at: index)
        guard range.location != NSNotFound,
              let swiftRange = Range(range, in: text) else {
            return nil
        }
        return String(text[swiftRange])
    }
}
