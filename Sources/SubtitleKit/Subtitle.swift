import Foundation

/// Main object-first API for parsing, converting, resyncing, and saving subtitles.
public struct Subtitle: Sendable, Hashable {
    private static var engine: SubtitleEngine {
        SubtitleEngine(registry: .current)
    }

    /// Underlying unified subtitle document.
    public var document: SubtitleDocument
    /// Line ending detected from the source text.
    public var sourceLineEnding: LineEnding
    /// Whether the source text started with a UTF BOM.
    public var sourceHadByteOrderMark: Bool

    /// Creates a subtitle value from an existing unified document.
    public init(
        document: SubtitleDocument,
        sourceLineEnding: LineEnding = .lf,
        sourceHadByteOrderMark: Bool = false
    ) {
        self.document = document
        self.sourceLineEnding = sourceLineEnding
        self.sourceHadByteOrderMark = sourceHadByteOrderMark
    }

    /// Canonical format name when known.
    public var formatName: String? {
        document.formatName
    }

    /// Resolved format adapter for ``formatName`` when available.
    public var format: SubtitleFormat? {
        guard let formatName else { return nil }
        return Self.engine.resolveFormat(named: formatName)
    }

    /// Full entry list (cues + metadata + styles).
    public var entries: [SubtitleEntry] {
        get { document.entries }
        set { document.entries = newValue }
    }

    /// Cue-only projection of ``entries``.
    public var cues: [SubtitleCue] {
        document.cues
    }

    /// Returns all currently registered formats in detection order.
    public static func supportedFormats() -> [SubtitleFormat] {
        engine.supportedFormats()
    }

    /// Returns canonical names of all currently registered formats.
    public static func supportedFormatNames() -> [String] {
        SubtitleFormatRegistry.current.supportedFormatNames
    }

    /// Detects format from extension hints first, then by content sniffing.
    public static func detectFormat(
        in content: String,
        fileName: String? = nil,
        fileExtension: String? = nil
    ) -> SubtitleFormat? {
        engine.detectFormat(content: content, fileName: fileName, fileExtension: fileExtension)
    }

    /// Parses raw subtitle text into a ``Subtitle`` value.
    public static func parse(
        _ content: String,
        options: SubtitleParseOptions = .init()
    ) throws -> Subtitle {
        let normalized = SubtitleNormalizer.normalizeInput(content)
        let document = try engine.parse(normalized.text, options: options)
        return Subtitle(
            document: document,
            sourceLineEnding: normalized.lineEnding,
            sourceHadByteOrderMark: normalized.hadByteOrderMark
        )
    }

    /// Convenience parse overload with direct format/detection parameters.
    public static func parse(
        _ content: String,
        format: SubtitleFormat? = nil,
        fileName: String? = nil,
        fileExtension: String? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil
    ) throws -> Subtitle {
        try parse(
            content,
            options: SubtitleParseOptions(
                format: format,
                fileName: fileName,
                fileExtension: fileExtension,
                preserveWhitespaceCaptions: preserveWhitespaceCaptions,
                fps: fps
            )
        )
    }

    /// Loads and parses subtitle content from disk.
    public static func load(
        from fileURL: URL,
        options: SubtitleParseOptions = .init(),
        encoding: String.Encoding = .utf8
    ) throws -> Subtitle {
        var parseOptions = options
        if parseOptions.fileName == nil {
            parseOptions.fileName = fileURL.lastPathComponent
        }
        if parseOptions.fileExtension == nil {
            parseOptions.fileExtension = fileURL.pathExtension
        }

        let content = try String(contentsOf: fileURL, encoding: encoding)
        return try parse(content, options: parseOptions)
    }

    /// Convenience load overload with direct format options.
    public static func load(
        from fileURL: URL,
        format: SubtitleFormat? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil,
        encoding: String.Encoding = .utf8
    ) throws -> Subtitle {
        try load(
            from: fileURL,
            options: SubtitleParseOptions(
                format: format,
                fileName: fileURL.lastPathComponent,
                fileExtension: fileURL.pathExtension,
                preserveWhitespaceCaptions: preserveWhitespaceCaptions,
                fps: fps
            ),
            encoding: encoding
        )
    }

    /// One-shot convert API from source text to target format text.
    public static func convert(
        _ content: String,
        from sourceFormat: SubtitleFormat? = nil,
        to targetFormat: SubtitleFormat,
        lineEnding: LineEnding = .crlf,
        fps: Double? = nil,
        preserveWhitespaceCaptions: Bool = false,
        resync: SubtitleResyncOptions? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) throws -> String {
        var subtitle = try parse(
            content,
            options: SubtitleParseOptions(
                format: sourceFormat,
                preserveWhitespaceCaptions: preserveWhitespaceCaptions,
                fps: fps
            )
        )
        if let resync {
            subtitle = subtitle.resync(resync)
        }
        return try subtitle.convertedText(
            to: targetFormat,
            lineEnding: lineEnding,
            fps: fps,
            samiTitle: samiTitle,
            samiLanguageName: samiLanguageName,
            samiLanguageCode: samiLanguageCode,
            closeSMITags: closeSMITags
        )
    }

    /// Serializes this subtitle value to text.
    public func text(
        format: SubtitleFormat? = nil,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) throws -> String {
        let resolvedFormat = format
            ?? (formatName.flatMap { Self.engine.resolveFormat(named: $0) })

        guard let resolvedFormat else {
            throw SubtitleError.unableToDetectFormat
        }

        return try Self.engine.serialize(
            document,
            options: SubtitleSerializeOptions(
                format: resolvedFormat,
                lineEnding: lineEnding ?? sourceLineEnding,
                fps: fps,
                samiTitle: samiTitle,
                samiLanguageName: samiLanguageName,
                samiLanguageCode: samiLanguageCode,
                closeSMITags: closeSMITags
            )
        )
    }

    /// Converts this subtitle value to another format and returns a parsed object.
    public func convert(
        to format: SubtitleFormat,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) throws -> Subtitle {
        let convertedText = try text(
            format: format,
            lineEnding: lineEnding,
            fps: fps,
            samiTitle: samiTitle,
            samiLanguageName: samiLanguageName,
            samiLanguageCode: samiLanguageCode,
            closeSMITags: closeSMITags
        )
        let parsed = try Self.engine.parse(
            convertedText,
            options: .init(format: format, fps: fps)
        )
        return Subtitle(
            document: parsed,
            sourceLineEnding: lineEnding ?? sourceLineEnding,
            sourceHadByteOrderMark: false
        )
    }

    /// Converts this subtitle value to another format and returns serialized text.
    public func convertedText(
        to format: SubtitleFormat,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) throws -> String {
        try text(
            format: format,
            lineEnding: lineEnding,
            fps: fps,
            samiTitle: samiTitle,
            samiLanguageName: samiLanguageName,
            samiLanguageCode: samiLanguageCode,
            closeSMITags: closeSMITags
        )
    }

    /// Returns a new subtitle with timing resync applied.
    public func resync(
        _ options: SubtitleResyncOptions
    ) -> Subtitle {
        var next = self
        next.document = Self.engine.resyncDocument(document, options: options)
        return next
    }

    /// Returns a new subtitle with timing transformed by a custom closure.
    public func resync(
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (Int, Int, SubtitleCue.FrameRange?)
    ) -> Subtitle {
        var next = self
        next.document = Self.engine.resyncDocument(document, using: transform)
        return next
    }

    /// Mutates this subtitle by applying timing resync options.
    public mutating func applyResync(
        _ options: SubtitleResyncOptions
    ) {
        document = Self.engine.resyncDocument(document, options: options)
    }

    /// Mutates this subtitle by applying a custom timing transform.
    public mutating func applyResync(
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (Int, Int, SubtitleCue.FrameRange?)
    ) {
        document = Self.engine.resyncDocument(document, using: transform)
    }

    /// Serializes and writes this subtitle to disk.
    public func save(
        to fileURL: URL,
        format: SubtitleFormat? = nil,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false,
        encoding: String.Encoding = .utf8
    ) throws {
        let extensionGuess = fileURL.pathExtension.isEmpty
            ? nil
            : Self.engine.detectFormat(content: "", fileExtension: fileURL.pathExtension)

        let output = try text(
            format: format ?? extensionGuess,
            lineEnding: lineEnding,
            fps: fps,
            samiTitle: samiTitle,
            samiLanguageName: samiLanguageName,
            samiLanguageCode: samiLanguageCode,
            closeSMITags: closeSMITags
        )

        try output.write(to: fileURL, atomically: true, encoding: encoding)
    }
}
