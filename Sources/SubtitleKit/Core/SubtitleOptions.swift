import Foundation

/// Parsing options for subtitle input.
public struct SubtitleParseOptions: Sendable {
    /// Explicit source format. When `nil`, format detection is used.
    public var format: SubtitleFormat?
    /// Optional input filename used for extension-based detection.
    public var fileName: String?
    /// Optional file extension used for extension-based detection.
    public var fileExtension: String?
    /// Controls whether blank/whitespace SAMI cues are preserved.
    public var preserveWhitespaceCaptions: Bool
    /// Frame rate used by frame-based formats such as MicroDVD (`.sub`).
    public var fps: Double?

    public init(
        format: SubtitleFormat? = nil,
        fileName: String? = nil,
        fileExtension: String? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil
    ) {
        self.format = format
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.preserveWhitespaceCaptions = preserveWhitespaceCaptions
        self.fps = fps
    }
}

/// Serialization options for writing subtitle output.
public struct SubtitleSerializeOptions: Sendable {
    /// Target subtitle format.
    public var format: SubtitleFormat
    /// Line ending for the generated text.
    public var lineEnding: LineEnding
    /// Frame rate used by frame-based formats such as MicroDVD (`.sub`).
    public var fps: Double?
    /// Optional `<TITLE>` for SAMI output.
    public var samiTitle: String?
    /// SAMI language display name.
    public var samiLanguageName: String
    /// SAMI language code.
    public var samiLanguageCode: String
    /// Controls whether SAMI tags are explicitly closed.
    public var closeSMITags: Bool

    public init(
        format: SubtitleFormat,
        lineEnding: LineEnding = .crlf,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) {
        self.format = format
        self.lineEnding = lineEnding
        self.fps = fps
        self.samiTitle = samiTitle
        self.samiLanguageName = samiLanguageName
        self.samiLanguageCode = samiLanguageCode
        self.closeSMITags = closeSMITags
    }
}

/// Timing-shift options for resynchronizing subtitle cues.
public struct SubtitleResyncOptions: Sendable, Hashable {
    /// Millisecond offset added after ratio transform.
    public var offset: Int
    /// Multiplicative ratio applied to times.
    public var ratio: Double
    /// Uses frame ranges instead of millisecond times when available.
    public var useFrameValues: Bool

    public init(offset: Int = 0, ratio: Double = 1.0, useFrameValues: Bool = false) {
        self.offset = offset
        self.ratio = ratio
        self.useFrameValues = useFrameValues
    }
}

/// Supported output line endings.
public enum LineEnding: String, Sendable, Hashable, Codable {
    case lf = "\n"
    case crlf = "\r\n"

    public var value: String { rawValue }
}
