import Foundation

public struct SubtitleDocument: Sendable, Hashable {
    public var format: SubtitleFormat?
    public var entries: [SubtitleEntry]

    public init(format: SubtitleFormat? = nil, entries: [SubtitleEntry]) {
        self.format = format
        self.entries = entries
    }

    public var cues: [SubtitleCue] {
        entries.compactMap {
            if case let .cue(cue) = $0 {
                return cue
            }
            return nil
        }
    }
}

public enum SubtitleEntry: Sendable, Hashable, Identifiable {
    case cue(SubtitleCue)
    case metadata(SubtitleMetadata)
    case style(SubtitleStyle)

    public var id: Int {
        switch self {
        case let .cue(value):
            return value.id
        case let .metadata(value):
            return value.id
        case let .style(value):
            return value.id
        }
    }
}

public struct SubtitleCue: Sendable, Hashable, Identifiable {
    public struct FrameRange: Sendable, Hashable {
        public var start: Int
        public var end: Int

        public init(start: Int, end: Int) {
            self.start = start
            self.end = end
        }

        public var count: Int {
            end - start
        }
    }

    public var id: Int
    public var cueIdentifier: String?
    public var startTime: Int
    public var endTime: Int
    public var rawText: String
    public var plainText: String
    public var frameRange: FrameRange?
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

    public var duration: Int {
        endTime - startTime
    }
}

public struct SubtitleMetadata: Sendable, Hashable, Identifiable {
    public enum Value: Sendable, Hashable {
        case text(String)
        case fields([SubtitleAttribute])
    }

    public var id: Int
    public var key: String
    public var value: Value

    public init(id: Int, key: String, value: Value) {
        self.id = id
        self.key = key
        self.value = value
    }
}

public struct SubtitleStyle: Sendable, Hashable, Identifiable {
    public var id: Int
    public var name: String
    public var fields: [SubtitleAttribute]

    public init(id: Int, name: String, fields: [SubtitleAttribute]) {
        self.id = id
        self.name = name
        self.fields = fields
    }
}

public struct SubtitleAttribute: Sendable, Hashable {
    public var key: String
    public var value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
