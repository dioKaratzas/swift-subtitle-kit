import Foundation

public enum SubtitleFormat: String, CaseIterable, Sendable, Hashable, Codable {
    case srt
    case vtt
    case sbv
    case sub
    case ssa
    case ass
    case lrc
    case smi

    public var preferredFileExtension: String {
        rawValue
    }

    public static func from(fileExtension: String) -> SubtitleFormat? {
        let ext = fileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return SubtitleFormat(rawValue: ext)
    }
}
