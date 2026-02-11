import Foundation

public struct SubtitleKit: Sendable {
    public struct Registry: Sendable {
        private let adaptersByFormat: [SubtitleFormat: any SubtitleFormatAdapter]
        private let detectionOrder: [any SubtitleFormatAdapter]

        public init(adapters: [any SubtitleFormatAdapter]) {
            var map: [SubtitleFormat: any SubtitleFormatAdapter] = [:]
            for adapter in adapters {
                for format in adapter.aliases {
                    map[format] = adapter
                }
            }
            self.adaptersByFormat = map
            self.detectionOrder = adapters
        }

        public func adapter(for format: SubtitleFormat) -> (any SubtitleFormatAdapter)? {
            adaptersByFormat[format]
        }

        public func detect(content: String) -> SubtitleFormat? {
            for adapter in detectionOrder where adapter.canParse(content) {
                return adapter.format
            }
            return nil
        }
    }

    public let registry: Registry

    public init(registry: Registry = .default) {
        self.registry = registry
    }

    public func detectFormat(content: String, fileExtension: String? = nil) -> SubtitleFormat? {
        if let fileExtension,
           let format = SubtitleFormat.from(fileExtension: fileExtension),
           registry.adapter(for: format) != nil {
            return format
        }
        return registry.detect(content: content)
    }

    public func parse(_ content: String, options: SubtitleParseOptions = .init()) throws -> SubtitleDocument {
        let format = options.format
            ?? (options.fileExtension.flatMap(SubtitleFormat.from(fileExtension:)))
            ?? detectFormat(content: content, fileExtension: options.fileExtension)

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

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        guard let adapter = registry.adapter(for: options.format) else {
            throw SubtitleError.unsupportedFormat(options.format.rawValue)
        }
        return try adapter.serialize(document, options: options)
    }
}

extension SubtitleKit.Registry {
    public static let `default`: Self = .init(adapters: [
        VTTAdapter(),
        SRTAdapter(),
        SBVAdapter(),
    ])
}
