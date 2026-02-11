import Foundation

struct SubtitleRegistry: Sendable {
    private let adaptersByFormat: [SubtitleFormat: any SubtitleFormatAdapter]
    private let detectionOrder: [any SubtitleFormatAdapter]

    init(adapters: [any SubtitleFormatAdapter]) {
        var map: [SubtitleFormat: any SubtitleFormatAdapter] = [:]
        for adapter in adapters {
            for format in adapter.aliases {
                map[format] = adapter
            }
        }
        self.adaptersByFormat = map
        self.detectionOrder = adapters
    }

    func adapter(for format: SubtitleFormat) -> (any SubtitleFormatAdapter)? {
        adaptersByFormat[format]
    }

    func detect(content: String) -> SubtitleFormat? {
        for adapter in detectionOrder where adapter.canParse(content) {
            return adapter.format
        }
        return nil
    }

    var supportedFormats: [SubtitleFormat] {
        Array(adaptersByFormat.keys).sorted { $0.rawValue < $1.rawValue }
    }
}

extension SubtitleRegistry {
    static let `default`: Self = .init(adapters: [
        VTTAdapter(),
        LRCAdapter(),
        SMIAdapter(),
        ASSAdapter(),
        SSAAdapter(),
        SUBAdapter(),
        SRTAdapter(),
        SBVAdapter(),
    ])
}
