import Foundation

public protocol SubtitleFormat: Sendable {
    var name: String { get }
    var aliases: [String] { get }

    func canParse(_ content: String) -> Bool
    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument
    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String
}

public extension SubtitleFormat {
    var aliases: [String] { [name] }

    func register() {
        SubtitleFormatRegistry.register(self)
    }
}

public extension SubtitleFormat where Self == SRTFormat {
    static var srt: SubtitleFormat { SRTFormat() }
}

public extension SubtitleFormat where Self == VTTFormat {
    static var vtt: SubtitleFormat { VTTFormat() }
}

public extension SubtitleFormat where Self == SBVFormat {
    static var sbv: SubtitleFormat { SBVFormat() }
}

public extension SubtitleFormat where Self == SUBFormat {
    static var sub: SubtitleFormat { SUBFormat() }
}

public extension SubtitleFormat where Self == SSAFormat {
    static var ssa: SubtitleFormat { SSAFormat() }
}

public extension SubtitleFormat where Self == ASSFormat {
    static var ass: SubtitleFormat { ASSFormat() }
}

public extension SubtitleFormat where Self == LRCFormat {
    static var lrc: SubtitleFormat { LRCFormat() }
}

public extension SubtitleFormat where Self == SMIFormat {
    static var smi: SubtitleFormat { SMIFormat() }
}

public extension SubtitleFormat where Self == JSONFormat {
    static var json: SubtitleFormat { JSONFormat() }
}
