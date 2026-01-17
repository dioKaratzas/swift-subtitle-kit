import Foundation

public struct Subtitle: Sendable, Hashable {
    private static let engine = SubtitleEngine.default

    public var document: SubtitleDocument
    public var sourceLineEnding: LineEnding
    public var sourceHadByteOrderMark: Bool

    public init(
        document: SubtitleDocument,
        sourceLineEnding: LineEnding = .lf,
        sourceHadByteOrderMark: Bool = false
    ) {
        self.document = document
        self.sourceLineEnding = sourceLineEnding
        self.sourceHadByteOrderMark = sourceHadByteOrderMark
    }

    public var format: SubtitleFormat? {
        document.format
    }

    public var entries: [SubtitleEntry] {
        get { document.entries }
        set { document.entries = newValue }
    }

    public var cues: [SubtitleCue] {
        document.cues
    }

    public static func supportedFormats() -> [SubtitleFormat] {
        engine.supportedFormats()
    }

    public static func detectFormat(
        in content: String,
        fileName: String? = nil,
        fileExtension: String? = nil
    ) -> SubtitleFormat? {
        engine.detectFormat(content: content, fileName: fileName, fileExtension: fileExtension)
    }

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

    public func text(
        format: SubtitleFormat? = nil,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) throws -> String {
        let resolvedFormat = format ?? document.format
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
        let parsed = try Self.engine.parse(convertedText, options: .init(format: format, fps: fps))
        return Subtitle(
            document: parsed,
            sourceLineEnding: lineEnding ?? sourceLineEnding,
            sourceHadByteOrderMark: false
        )
    }

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

    public func resync(
        _ options: SubtitleResyncOptions
    ) -> Subtitle {
        var next = self
        next.document = Self.engine.resyncDocument(document, options: options)
        return next
    }

    public func resync(
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (Int, Int, SubtitleCue.FrameRange?)
    ) -> Subtitle {
        var next = self
        next.document = Self.engine.resyncDocument(document, using: transform)
        return next
    }

    public mutating func applyResync(
        _ options: SubtitleResyncOptions
    ) {
        document = Self.engine.resyncDocument(document, options: options)
    }

    public mutating func applyResync(
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (Int, Int, SubtitleCue.FrameRange?)
    ) {
        document = Self.engine.resyncDocument(document, using: transform)
    }

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
        let output = try text(
            format: format,
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
