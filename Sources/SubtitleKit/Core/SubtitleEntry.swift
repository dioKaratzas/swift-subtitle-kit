//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

/// Unified subtitle document model used across all formats.
public struct SubtitleDocument: Sendable, Hashable {
    /// Canonical source format name when known.
    public var formatName: String?
    /// Ordered entries in the subtitle document.
    public var entries: [SubtitleEntry]

    public init(formatName: String? = nil, entries: [SubtitleEntry]) {
        self.formatName = formatName
        self.entries = entries
    }

    /// All cue entries, in document order.
    public var cues: [SubtitleCue] {
        entries.compactMap {
            if case let .cue(cue) = $0 {
                return cue
            }
            return nil
        }
    }
}

/// A document entry: cue, metadata, or style.
public enum SubtitleEntry: Sendable, Hashable, Identifiable {
    case cue(SubtitleCue)
    case metadata(SubtitleMetadata)
    case style(SubtitleStyle)

    /// Stable entry identifier.
    public var id: Int {
        switch self {
        case let .cue(value):
            value.id
        case let .metadata(value):
            value.id
        case let .style(value):
            value.id
        }
    }
}

/// A timed subtitle cue.
public struct SubtitleCue: Sendable, Hashable, Identifiable {
    /// Frame range for frame-based formats.
    public struct FrameRange: Sendable, Hashable {
        public var start: Int
        public var end: Int

        public init(start: Int, end: Int) {
            self.start = start
            self.end = end
        }

        /// Number of frames in the range.
        public var count: Int {
            end - start
        }
    }

    /// Cue identifier.
    public var id: Int
    /// Optional cue identifier token (for example, WebVTT cue id).
    public var cueIdentifier: String?
    /// Cue start time in milliseconds.
    public var startTime: Int
    /// Cue end time in milliseconds.
    public var endTime: Int
    /// Raw cue text as parsed from source.
    public var rawText: String
    /// Normalized plain-text cue body.
    public var plainText: String
    /// Optional frame range for frame-based formats.
    public var frameRange: FrameRange?
    /// Format-specific attributes/settings attached to the cue.
    public var attributes: [SubtitleAttribute]

    public init(
        id: Int,
        cueIdentifier: String? = nil,
        startTime: Int,
        endTime: Int,
        rawText: String,
        plainText: String,
        frameRange: FrameRange? = nil,
        attributes: [SubtitleAttribute] = []
    ) {
        self.id = id
        self.cueIdentifier = cueIdentifier
        self.startTime = startTime
        self.endTime = endTime
        self.rawText = rawText
        self.plainText = plainText
        self.frameRange = frameRange
        self.attributes = attributes
    }

    /// Cue duration in milliseconds.
    public var duration: Int {
        endTime - startTime
    }
}

/// Metadata entry in a subtitle document.
public struct SubtitleMetadata: Sendable, Hashable, Identifiable {
    /// Metadata value payload.
    public enum Value: Sendable, Hashable {
        case text(String)
        case fields([SubtitleAttribute])
    }

    /// Metadata identifier.
    public var id: Int
    /// Metadata key.
    public var key: String
    /// Metadata payload.
    public var value: Value

    public init(id: Int, key: String, value: Value) {
        self.id = id
        self.key = key
        self.value = value
    }
}

/// Style entry in a subtitle document.
public struct SubtitleStyle: Sendable, Hashable, Identifiable {
    /// Style identifier.
    public var id: Int
    /// Style name.
    public var name: String
    /// Style fields.
    public var fields: [SubtitleAttribute]

    public init(id: Int, name: String, fields: [SubtitleAttribute]) {
        self.id = id
        self.name = name
        self.fields = fields
    }
}

/// Key/value attribute used by metadata, styles, and cues.
public struct SubtitleAttribute: Sendable, Hashable {
    /// Attribute name.
    public var key: String
    /// Attribute value.
    public var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
