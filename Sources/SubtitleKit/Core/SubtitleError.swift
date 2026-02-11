import Foundation

public enum SubtitleError: Error, Sendable, Hashable, LocalizedError {
    case unsupportedFormat(String)
    case unableToDetectFormat
    case malformedBlock(format: SubtitleFormat, details: String)
    case invalidTimestamp(format: SubtitleFormat, value: String)
    case unsupportedVariant(format: SubtitleFormat, details: String)
    case invalidFrameRate(Double)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported subtitle format: \(format)"
        case .unableToDetectFormat:
            return "Unable to detect subtitle format"
        case let .malformedBlock(format, details):
            return "Malformed \(format.rawValue.uppercased()) block: \(details)"
        case let .invalidTimestamp(format, value):
            return "Invalid \(format.rawValue.uppercased()) timestamp: \(value)"
        case let .unsupportedVariant(format, details):
            return "Unsupported \(format.rawValue.uppercased()) variant: \(details)"
        case let .invalidFrameRate(value):
            return "Invalid frame rate: \(value)"
        }
    }
}
