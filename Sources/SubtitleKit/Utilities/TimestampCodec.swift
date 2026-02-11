import Foundation

enum TimestampCodec {
    static func parseSRT(_ value: String) throws -> Int {
        try parse(value, pattern: #"^\s*(\d{1,2}):(\d{1,2}):(\d{1,2})(?:[\.,](\d{1,3}))?\s*$"#, hundredths: false, format: .srt)
    }

    static func parseVTT(_ value: String) throws -> Int {
        let patterns = [
            #"^\s*(\d{1,2}):(\d{1,2}):(\d{1,2})(?:[\.,](\d{1,3}))?\s*$"#,
            #"^\s*(\d{1,2}):(\d{1,2})(?:[\.,](\d{1,3}))?\s*$"#,
        ]

        for pattern in patterns {
            if let milliseconds = try parseUsingFlexiblePattern(value, pattern: pattern, format: .vtt) {
                return milliseconds
            }
        }

        throw SubtitleError.invalidTimestamp(format: .vtt, value: value)
    }

    static func parseSBV(_ value: String) throws -> Int {
        try parse(value, pattern: #"^\s*(\d{1,2}):(\d{1,2}):(\d{1,2})(?:[\.,](\d{1,3}))?\s*$"#, hundredths: false, format: .sbv)
    }

    static func parseSSA(_ value: String) throws -> Int {
        try parse(value, pattern: #"^\s*(\d+):(\d{1,2}):(\d{1,2})(?:[\.,](\d{1,3}))?\s*$"#, hundredths: true, format: .ssa)
    }

    static func parseLRC(_ value: String) throws -> Int {
        try parse(value, pattern: #"^\s*(\d+):(\d{1,2})(?:[\.,](\d{1,3}))?\s*$"#, hundredths: true, format: .lrc, hasHours: false)
    }

    static func formatSRT(_ milliseconds: Int) -> String {
        let (h, m, s, ms) = split(milliseconds)
        return String(format: "%02d:%02d:%02d,%03d", h, m, s, ms)
    }

    static func formatVTT(_ milliseconds: Int) -> String {
        let (h, m, s, ms) = split(milliseconds)
        return String(format: "%02d:%02d:%02d.%03d", h, m, s, ms)
    }

    static func formatSBV(_ milliseconds: Int) -> String {
        formatVTT(milliseconds)
    }

    static func formatSSA(_ milliseconds: Int) -> String {
        let (h, m, s, ms) = split(milliseconds)
        return String(format: "%d:%02d:%02d.%02d", h, m, s, ms / 10)
    }

    static func formatLRC(_ milliseconds: Int) -> String {
        let totalSeconds = milliseconds / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let fraction = (milliseconds % 1000) / 10
        return String(format: "%02d:%02d.%02d", minutes, seconds, fraction)
    }

    private static func split(_ milliseconds: Int) -> (Int, Int, Int, Int) {
        let total = max(0, milliseconds)
        let hours = total / 3_600_000
        let minutes = (total / 60_000) % 60
        let seconds = (total / 1_000) % 60
        let ms = total % 1_000
        return (hours, minutes, seconds, ms)
    }

    private static func parse(
        _ value: String,
        pattern: String,
        hundredths: Bool,
        format: SubtitleFormat,
        hasHours: Bool = true
    ) throws -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = RegexUtils.firstMatch(regex, in: value)
        else {
            throw SubtitleError.invalidTimestamp(format: format, value: value)
        }

        if hasHours {
            let h = Int(RegexUtils.string(value, at: 1, in: match) ?? "") ?? -1
            let m = Int(RegexUtils.string(value, at: 2, in: match) ?? "") ?? -1
            let s = Int(RegexUtils.string(value, at: 3, in: match) ?? "") ?? -1
            let f = Int(RegexUtils.string(value, at: 4, in: match) ?? "0") ?? 0
            if h < 0 || m < 0 || s < 0 {
                throw SubtitleError.invalidTimestamp(format: format, value: value)
            }
            let fraction = hundredths ? (f * 10) : f
            return h * 3_600_000 + m * 60_000 + s * 1_000 + fraction
        }

        let m = Int(RegexUtils.string(value, at: 1, in: match) ?? "") ?? -1
        let s = Int(RegexUtils.string(value, at: 2, in: match) ?? "") ?? -1
        let f = Int(RegexUtils.string(value, at: 3, in: match) ?? "0") ?? 0
        if m < 0 || s < 0 {
            throw SubtitleError.invalidTimestamp(format: format, value: value)
        }
        let fraction = hundredths ? (f * 10) : f
        return m * 60_000 + s * 1_000 + fraction
    }

    private static func parseUsingFlexiblePattern(
        _ value: String,
        pattern: String,
        format: SubtitleFormat
    ) throws -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = RegexUtils.firstMatch(regex, in: value)
        else {
            return nil
        }

        if match.numberOfRanges == 5 {
            let h = Int(RegexUtils.string(value, at: 1, in: match) ?? "") ?? -1
            let m = Int(RegexUtils.string(value, at: 2, in: match) ?? "") ?? -1
            let s = Int(RegexUtils.string(value, at: 3, in: match) ?? "") ?? -1
            let f = Int(RegexUtils.string(value, at: 4, in: match) ?? "0") ?? 0
            if h >= 0, m >= 0, s >= 0 {
                return h * 3_600_000 + m * 60_000 + s * 1_000 + f
            }
        }

        if match.numberOfRanges == 4 {
            let m = Int(RegexUtils.string(value, at: 1, in: match) ?? "") ?? -1
            let s = Int(RegexUtils.string(value, at: 2, in: match) ?? "") ?? -1
            let f = Int(RegexUtils.string(value, at: 3, in: match) ?? "0") ?? 0
            if m >= 0, s >= 0 {
                return m * 60_000 + s * 1_000 + f
            }
        }

        throw SubtitleError.invalidTimestamp(format: format, value: value)
    }
}
