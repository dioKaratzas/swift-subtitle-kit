import Foundation

struct SubtitleEngine: Sendable {
    let registry: SubtitleFormatRegistry

    init(registry: SubtitleFormatRegistry = .standard) {
        self.registry = registry
    }

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
        let resolvedFormat = options.format
            ?? options.fileName.flatMap(registry.resolve(fileName:))
            ?? options.fileExtension.flatMap(registry.resolve(fileExtension:))
            ?? detectFormat(
                content: content,
                fileName: options.fileName,
                fileExtension: options.fileExtension
            )

        guard let resolvedFormat else {
            throw SubtitleError.unableToDetectFormat
        }

        var parsed = try resolvedFormat.parse(content, options: options)
        if parsed.formatName == nil {
            parsed.formatName = resolvedFormat.name
        }
        return parsed
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        try options.format.serialize(document, options: options)
    }

    func resolveFormat(named name: String) -> SubtitleFormat? {
        registry.resolve(name: name)
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
