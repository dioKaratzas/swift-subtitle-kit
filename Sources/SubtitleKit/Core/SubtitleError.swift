//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

/// Errors thrown by subtitle format detection, parsing, and serialization.
///
/// All cases include enough context to produce useful diagnostics.
/// The ``errorDescription`` property returns a human-readable message
/// suitable for logging.
public enum SubtitleError: Error, Sendable, Hashable, LocalizedError {
    /// The named format is not registered in the current ``SubtitleFormatRegistry``.
    case unsupportedFormat(String)
    /// No parser could be selected from explicit hints or content-based detection.
    case unableToDetectFormat
    /// A structural issue was found while parsing a specific format block.
    case malformedBlock(format: String, details: String)
    /// A timestamp string could not be parsed for the expected format.
    case invalidTimestamp(format: String, value: String)
    /// The input uses a recognized but unsupported variant of a format.
    case unsupportedVariant(format: String, details: String)
    /// The provided frame rate is non-positive or otherwise invalid.
    case invalidFrameRate(Double)
    /// Reading input subtitle text from disk failed.
    case fileReadFailed(path: String, details: String)
    /// Writing output subtitle text to disk failed.
    case fileWriteFailed(path: String, details: String)
    /// Internal parser/serializer setup failed before processing input.
    case internalFailure(details: String)

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
        case let .fileReadFailed(path, details):
            return "Failed to read subtitle file at \(path): \(details)"
        case let .fileWriteFailed(path, details):
            return "Failed to write subtitle file at \(path): \(details)"
        case let .internalFailure(details):
            return "SubtitleKit internal failure: \(details)"
        }
    }
}
