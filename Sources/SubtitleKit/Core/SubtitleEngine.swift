import Foundation

struct SubtitleEngine: Sendable {
    let registry: SubtitleRegistry

    init(registry: SubtitleRegistry = .default) {
        self.registry = registry
    }

    static let `default` = SubtitleEngine()

    func supportedFormats() -> [SubtitleFormat] {
        registry.supportedFormats
    }

    func detectFormat(
        content: String,
        fileName: String? = nil,
        fileExtension: String? = nil
    ) -> SubtitleFormat? {
        SubtitleDetector.detectFormat(
            content: content,
            registry: registry,
            fileName: fileName,
            fileExtension: fileExtension
        )
    }

    func parse(_ content: String, options: SubtitleParseOptions = .init()) throws -> SubtitleDocument {
        let format = options.format
            ?? (options.fileName.flatMap(SubtitleFormat.from(fileName:)))
            ?? (options.fileExtension.flatMap(SubtitleFormat.from(fileExtension:)))
            ?? detectFormat(
                content: content,
                fileName: options.fileName,
                fileExtension: options.fileExtension
            )

        guard let format else {
            throw SubtitleError.unableToDetectFormat
        }
        guard let adapter = registry.adapter(for: format) else {
            throw SubtitleError.unsupportedFormat(format.rawValue)
        }

        var parsed = try adapter.parse(content, options: options)
        if parsed.format == nil {
            parsed.format = format
        }
        return parsed
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        guard let adapter = registry.adapter(for: options.format) else {
            throw SubtitleError.unsupportedFormat(options.format.rawValue)
        }
        return try adapter.serialize(document, options: options)
    }

    func resyncDocument(_ document: SubtitleDocument, options: SubtitleResyncOptions) -> SubtitleDocument {
        resyncDocument(document) { start, end, frame in
            if options.useFrameValues, let frame {
                let shiftedStart = Int((Double(frame.start) * options.ratio).rounded()) + options.offset
                let shiftedEnd = Int((Double(frame.end) * options.ratio).rounded()) + options.offset
                return (start, end, .init(start: shiftedStart, end: shiftedEnd))
            }

            let shiftedStart = Int((Double(start) * options.ratio).rounded()) + options.offset
            let shiftedEnd = Int((Double(end) * options.ratio).rounded()) + options.offset
            return (shiftedStart, shiftedEnd, frame)
        }
    }

    func resyncDocument(
        _ document: SubtitleDocument,
        using transform: @Sendable (_ start: Int, _ end: Int, _ frame: SubtitleCue.FrameRange?) -> (Int, Int, SubtitleCue.FrameRange?)
    ) -> SubtitleDocument {
        var updated = document
        updated.entries = updated.entries.map { entry in
            guard case let .cue(cue) = entry else { return entry }
            let (newStart, newEnd, newFrame) = transform(cue.startTime, cue.endTime, cue.frameRange)
            var next = cue
            next.startTime = newStart
            next.endTime = newEnd
            next.frameRange = newFrame
            return .cue(next)
        }
        return updated
    }
}
