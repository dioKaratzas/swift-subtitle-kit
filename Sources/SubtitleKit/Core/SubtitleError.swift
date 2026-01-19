import Foundation

public enum SubtitleError: Error, Sendable, Hashable, LocalizedError {
    case unsupportedFormat(String)
    case unableToDetectFormat
    case malformedBlock(format: String, details: String)
    case invalidTimestamp(format: String, value: String)
    case unsupportedVariant(format: String, details: String)
    case invalidFrameRate(Double)

    public var errorDescription: String? {
        switch self {
        case let .unsupportedFormat(format):
            return "Unsupported subtitle format: \(format)"
        case .unableToDetectFormat:
            return "Unable to detect subtitle format"
        case let .malformedBlock(format, details):
            return "Malformed \(format.uppercased()) block: \(details)"
        case let .invalidTimestamp(format, value):
            return "Invalid \(format.uppercased()) timestamp: \(value)"
        case let .unsupportedVariant(format, details):
            return "Unsupported \(format.uppercased()) variant: \(details)"
        case let .invalidFrameRate(value):
            return "Invalid frame rate: \(value)"
        }
    }
}
