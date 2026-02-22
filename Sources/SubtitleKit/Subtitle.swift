//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

/// Main object-first API for parsing, converting, resyncing, and saving subtitles.
public struct Subtitle: Sendable, Hashable {
    private static var engine: SubtitleEngine {
        SubtitleEngine(registry: .current)
    }

    private static func performBlockingFileIO<T: Sendable>(
        _ operation: @escaping @Sendable () throws -> T
    ) async throws -> T {
        try await Task.detached(operation: operation).value
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
        guard let formatName else {
            return nil
        }
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

    // MARK: - Static Helpers

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

    // MARK: - Parse

    /// Parses raw subtitle text into a ``Subtitle`` value.
    public static func parse(
        _ content: String,
        options: SubtitleParseOptions = .init()
    ) throws(SubtitleError) -> Subtitle {
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
    ) throws(SubtitleError) -> Subtitle {
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

    // MARK: - Load

    /// Loads and parses subtitle content from disk.
    public static func load(
        from fileURL: URL,
        options: SubtitleParseOptions = .init(),
        encoding: String.Encoding = .utf8
    ) throws(SubtitleError) -> Subtitle {
        var parseOptions = options
        if parseOptions.fileName == nil {
            parseOptions.fileName = fileURL.lastPathComponent
        }
        if parseOptions.fileExtension == nil {
            parseOptions.fileExtension = fileURL.pathExtension
        }

        let content: String
        do {
            content = try String(contentsOf: fileURL, encoding: encoding)
        } catch {
            throw SubtitleError.fileReadFailed(path: fileURL.path, details: error.localizedDescription)
        }
        return try parse(content, options: parseOptions)
    }

    /// Loads and parses subtitle content from disk without blocking the caller's executor.
    public static func load(
        from fileURL: URL,
        options: SubtitleParseOptions = .init(),
        encoding: String.Encoding = .utf8
    ) async throws(SubtitleError) -> Subtitle {
        var parseOptions = options
        if parseOptions.fileName == nil {
            parseOptions.fileName = fileURL.lastPathComponent
        }
        if parseOptions.fileExtension == nil {
            parseOptions.fileExtension = fileURL.pathExtension
        }

        let content: String
        do {
            let encodingRawValue = encoding.rawValue
            content = try await performBlockingFileIO {
                try String(
                    contentsOf: fileURL,
                    encoding: .init(rawValue: encodingRawValue)
                )
            }
        } catch {
            throw SubtitleError.fileReadFailed(path: fileURL.path, details: error.localizedDescription)
        }
        return try parse(content, options: parseOptions)
    }

    /// Convenience load overload with direct format options.
    public static func load(
        from fileURL: URL,
        format: SubtitleFormat? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil,
        encoding: String.Encoding = .utf8
    ) throws(SubtitleError) -> Subtitle {
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

    /// Convenience async load overload with direct format options.
    public static func load(
        from fileURL: URL,
        format: SubtitleFormat? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil,
        encoding: String.Encoding = .utf8
    ) async throws(SubtitleError) -> Subtitle {
        try await load(
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

    // MARK: - Convert (static one-shot)

    /// One-shot convert API from source text to target format text.
    public static func convert(
        _ content: String,
        from sourceFormat: SubtitleFormat? = nil,
        to targetFormat: SubtitleFormat,
        lineEnding: LineEnding = .crlf,
        fps: Double? = nil,
        preserveWhitespaceCaptions: Bool = false,
        resync: SubtitleResyncOptions? = nil
    ) throws(SubtitleError) -> String {
        try convert(
            content,
            from: sourceFormat,
            using: .init(
                format: targetFormat,
                lineEnding: lineEnding,
                fps: fps
            ),
            preserveWhitespaceCaptions: preserveWhitespaceCaptions,
            resync: resync
        )
    }

    /// One-shot convert API using full serialization options.
    ///
    /// Use this overload when target formats require additional settings
    /// (for example, SAMI title/language/tag options).
    public static func convert(
        _ content: String,
        from sourceFormat: SubtitleFormat? = nil,
        using options: SubtitleSerializeOptions,
        preserveWhitespaceCaptions: Bool = false,
        resync: SubtitleResyncOptions? = nil
    ) throws(SubtitleError) -> String {
        var subtitle = try parse(
            content,
            options: SubtitleParseOptions(
                format: sourceFormat,
                preserveWhitespaceCaptions: preserveWhitespaceCaptions,
                fps: options.fps
            )
        )
        if let resync {
            subtitle = subtitle.resync(resync)
        }
        return try subtitle.text(using: options)
    }

    // MARK: - Serialize

    /// Serializes this subtitle value to text using full options.
    ///
    /// This is the primary serialization entry point. All format-specific
    /// options (such as SAMI settings) live in ``SubtitleSerializeOptions``.
    public func text(using options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        try Self.engine.serialize(document, options: options)
    }

    /// Serializes this subtitle value to text.
    ///
    /// When `format` is `nil`, the source format is used. When `lineEnding`
    /// is `nil`, the source line ending is preserved.
    ///
    /// For SAMI-specific options, use ``text(using:)`` with a
    /// ``SubtitleSerializeOptions`` value instead.
    public func text(
        format: SubtitleFormat? = nil,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil
    ) throws(SubtitleError) -> String {
        let resolvedFormat = format
            ?? (formatName.flatMap { Self.engine.resolveFormat(named: $0) })

        guard let resolvedFormat else {
            throw SubtitleError.unableToDetectFormat
        }

        return try text(using: SubtitleSerializeOptions(
            format: resolvedFormat,
            lineEnding: lineEnding ?? sourceLineEnding,
            fps: fps
        ))
    }

    /// Converts this subtitle value to another format and returns a new ``Subtitle``.
    public func convert(
        to format: SubtitleFormat,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil
    ) throws(SubtitleError) -> Subtitle {
        let convertedText = try text(
            format: format,
            lineEnding: lineEnding,
            fps: fps
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

    // MARK: - Clean

    /// Returns a new subtitle with cue text cleaned by the provided options.
    ///
    /// Option order matters when using the array overload. To apply all built-in
    /// operations in default order, call `clean()` with no arguments.
    public func clean(
        _ options: [SubtitleCleanOption] = SubtitleCleanOption.allCases
    ) -> Subtitle {
        cleanWithReport(options).subtitle
    }

    /// Returns a new subtitle with cue text cleaned by the provided option set.
    ///
    /// Set-based options are applied in ``SubtitleCleanOption.allCases`` order.
    public func clean(
        _ options: Set<SubtitleCleanOption>
    ) -> Subtitle {
        cleanWithReport(options).subtitle
    }

    /// Returns a cleaned subtitle plus a per-cue report of what changed.
    public func cleanWithReport(
        _ options: [SubtitleCleanOption] = SubtitleCleanOption.allCases
    ) -> SubtitleCleanResult {
        let output = SubtitleCleaner.cleanWithReport(document: document, options: options)
        var next = self
        next.document = output.document
        return .init(subtitle: next, report: output.report)
    }

    /// Returns a cleaned subtitle plus report using set-based options.
    ///
    /// Set-based options are applied in ``SubtitleCleanOption.allCases`` order.
    public func cleanWithReport(
        _ options: Set<SubtitleCleanOption>
    ) -> SubtitleCleanResult {
        cleanWithReport(SubtitleCleanOption.allCases.filter(options.contains))
    }

    /// Mutates this subtitle by applying cue text cleaning options in order.
    public mutating func applyClean(
        _ options: [SubtitleCleanOption] = SubtitleCleanOption.allCases
    ) {
        _ = applyCleanWithReport(options)
    }

    /// Mutates this subtitle by applying a set of cue text cleaning options.
    ///
    /// Set-based options are applied in ``SubtitleCleanOption.allCases`` order.
    public mutating func applyClean(
        _ options: Set<SubtitleCleanOption>
    ) {
        _ = applyCleanWithReport(options)
    }

    /// Mutates this subtitle and returns a per-cue report of what changed.
    @discardableResult
    public mutating func applyCleanWithReport(
        _ options: [SubtitleCleanOption] = SubtitleCleanOption.allCases
    ) -> SubtitleCleanReport {
        let output = SubtitleCleaner.cleanWithReport(document: document, options: options)
        document = output.document
        return output.report
    }

    /// Mutates this subtitle and returns report using set-based options.
    ///
    /// Set-based options are applied in ``SubtitleCleanOption.allCases`` order.
    @discardableResult
    public mutating func applyCleanWithReport(
        _ options: Set<SubtitleCleanOption>
    ) -> SubtitleCleanReport {
        applyCleanWithReport(SubtitleCleanOption.allCases.filter(options.contains))
    }

    // MARK: - Resync

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
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (
            Int,
            Int,
            SubtitleCue.FrameRange?
        )
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
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (
            Int,
            Int,
            SubtitleCue.FrameRange?
        )
    ) {
        document = Self.engine.resyncDocument(document, using: transform)
    }

    // MARK: - Save

    /// Serializes and writes this subtitle to disk.
    ///
    /// When `format` is `nil`, SubtitleKit infers from the file extension.
    /// For SAMI-specific options, use the ``save(to:using:encoding:)`` overload.
    public func save(
        to fileURL: URL,
        format: SubtitleFormat? = nil,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        encoding: String.Encoding = .utf8
    ) throws(SubtitleError) {
        let extensionGuess = fileURL.pathExtension.isEmpty
            ? nil
            : Self.engine.detectFormat(content: "", fileExtension: fileURL.pathExtension)

        let output = try text(
            format: format ?? extensionGuess,
            lineEnding: lineEnding,
            fps: fps
        )

        do {
            try output.write(to: fileURL, atomically: true, encoding: encoding)
        } catch {
            throw SubtitleError.fileWriteFailed(path: fileURL.path, details: error.localizedDescription)
        }
    }

    /// Serializes and writes this subtitle to disk without blocking the caller's executor.
    ///
    /// When `format` is `nil`, SubtitleKit infers from the file extension.
    /// For SAMI-specific options, use the async ``save(to:using:encoding:)`` overload.
    public func save(
        to fileURL: URL,
        format: SubtitleFormat? = nil,
        lineEnding: LineEnding? = nil,
        fps: Double? = nil,
        encoding: String.Encoding = .utf8
    ) async throws(SubtitleError) {
        let extensionGuess = fileURL.pathExtension.isEmpty
            ? nil
            : Self.engine.detectFormat(content: "", fileExtension: fileURL.pathExtension)

        let output = try text(
            format: format ?? extensionGuess,
            lineEnding: lineEnding,
            fps: fps
        )

        do {
            let encodingRawValue = encoding.rawValue
            try await Self.performBlockingFileIO {
                try output.write(
                    to: fileURL,
                    atomically: true,
                    encoding: .init(rawValue: encodingRawValue)
                )
            }
        } catch {
            throw SubtitleError.fileWriteFailed(path: fileURL.path, details: error.localizedDescription)
        }
    }

    /// Serializes and writes this subtitle to disk using full options.
    public func save(
        to fileURL: URL,
        using options: SubtitleSerializeOptions,
        encoding: String.Encoding = .utf8
    ) throws(SubtitleError) {
        let output = try text(using: options)
        do {
            try output.write(to: fileURL, atomically: true, encoding: encoding)
        } catch {
            throw SubtitleError.fileWriteFailed(path: fileURL.path, details: error.localizedDescription)
        }
    }

    /// Serializes and writes this subtitle to disk using full options without blocking the caller's executor.
    public func save(
        to fileURL: URL,
        using options: SubtitleSerializeOptions,
        encoding: String.Encoding = .utf8
    ) async throws(SubtitleError) {
        let output = try text(using: options)
        do {
            let encodingRawValue = encoding.rawValue
            try await Self.performBlockingFileIO {
                try output.write(
                    to: fileURL,
                    atomically: true,
                    encoding: .init(rawValue: encodingRawValue)
                )
            }
        } catch {
            throw SubtitleError.fileWriteFailed(path: fileURL.path, details: error.localizedDescription)
        }
    }
}
