import Foundation

/// Errors thrown by subtitle format detection, parsing, and serialization.
public enum SubtitleError: Error, Sendable, Hashable, LocalizedError {
    /// Requested format is not supported.
    case unsupportedFormat(String)
    /// No parser could be selected from explicit hints or content detection.
    case unableToDetectFormat
    /// Format-specific structural issue while parsing.
    case malformedBlock(format: String, details: String)
    /// Timestamp could not be parsed for the specified format.
    case invalidTimestamp(format: String, value: String)
    /// Encountered a known-but-unsupported format variant.
    case unsupportedVariant(format: String, details: String)
    /// Invalid frame-rate value.
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
