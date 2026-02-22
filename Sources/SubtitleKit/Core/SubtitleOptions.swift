//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

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
    /// SAMI-specific serialization options.
    public struct SAMIOptions: Sendable, Hashable {
        /// Optional `<TITLE>` for SAMI output.
        public var title: String?
        /// SAMI language display name.
        public var languageName: String
        /// SAMI language code.
        public var languageCode: String
        /// Controls whether SAMI tags are explicitly closed.
        public var closeTags: Bool

        public init(
            title: String? = nil,
            languageName: String = "English",
            languageCode: String = "en-US",
            closeTags: Bool = false
        ) {
            self.title = title
            self.languageName = languageName
            self.languageCode = languageCode
            self.closeTags = closeTags
        }
    }

    /// Target subtitle format.
    public var format: SubtitleFormat
    /// Line ending for the generated text.
    public var lineEnding: LineEnding
    /// Frame rate used by frame-based formats such as MicroDVD (`.sub`).
    public var fps: Double?
    /// SAMI-specific options. Only used when the target format is `.smi`.
    public var sami: SAMIOptions

    public init(
        format: SubtitleFormat,
        lineEnding: LineEnding = .crlf,
        fps: Double? = nil,
        sami: SAMIOptions = .init()
    ) {
        self.format = format
        self.lineEnding = lineEnding
        self.fps = fps
        self.sami = sami
    }

    // MARK: - Internal convenience accessors (used by SMIAdapter)

    var samiTitle: String? {
        sami.title
    }

    var samiLanguageName: String {
        sami.languageName
    }

    var samiLanguageCode: String {
        sami.languageCode
    }

    var closeSMITags: Bool {
        sami.closeTags
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

/// Cleaning operations for subtitle cue text.
public enum SubtitleCleanOption: String, Sendable, Hashable, Codable, CaseIterable {
    /// Removes hearing-impaired annotations like `[music]` and `(laughing)`.
    case removeSDH
    /// Removes promotional text, website links, and email lines.
    case removeWatermarks
    /// Removes speaker prefixes such as `GEORGE:` and `>> JOHN:`.
    case removeSpeakerLabels
    /// Drops cues containing music note symbols (`♪`, `♫`, `♬`, `♩`).
    case removeCuesContainingMusicNotes
    /// Collapses multi-line cue text into a single line.
    case removeAllLineBreaks
    /// Merges consecutive overlapping cues with identical text.
    case mergeCuesWithSameText
    /// Converts mostly uppercase cue text into sentence case.
    case fixUppercaseText
    /// Removes SubStation-style curly tags like `{\an8}`.
    case removeCurlyBracketTags
    /// Removes HTML-style tags like `<i>` and `<b>`.
    case removeHTMLTags
}

/// Supported output line endings.
public enum LineEnding: String, Sendable, Hashable, Codable {
    case lf = "\n"
    case crlf = "\r\n"

    public var value: String {
        rawValue
    }
}
