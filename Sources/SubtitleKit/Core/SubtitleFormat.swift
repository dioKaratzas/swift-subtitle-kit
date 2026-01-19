import Foundation

/// A subtitle format adapter that can detect, parse, and serialize subtitle content.
public protocol SubtitleFormat: Sendable {
    /// Canonical lowercase format name (for example, `"srt"` or `"vtt"`).
    var name: String { get }
    /// Alternate names and extensions accepted by format resolution.
    var aliases: [String] { get }

    /// Returns `true` when the format can parse the provided raw subtitle text.
    func canParse(_ content: String) -> Bool
    /// Parses raw subtitle text into the unified ``SubtitleDocument`` model.
    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument
    /// Serializes a unified subtitle document into this format's text representation.
    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String
}

public extension SubtitleFormat {
    /// Uses the canonical name as the only alias by default.
    var aliases: [String] { [name] }

    /// Registers this format in the current global format registry.
    func register() {
        SubtitleFormatRegistry.register(self)
    }
}

public extension SubtitleFormat where Self == SRTFormat {
    /// Built-in SubRip (`.srt`) format.
    static var srt: SubtitleFormat { SRTFormat() }
}

public extension SubtitleFormat where Self == VTTFormat {
    /// Built-in WebVTT (`.vtt`) format.
    static var vtt: SubtitleFormat { VTTFormat() }
}

public extension SubtitleFormat where Self == SBVFormat {
    /// Built-in SubViewer (`.sbv`) format.
    static var sbv: SubtitleFormat { SBVFormat() }
}

public extension SubtitleFormat where Self == SUBFormat {
    /// Built-in MicroDVD (`.sub`) format.
    static var sub: SubtitleFormat { SUBFormat() }
}

public extension SubtitleFormat where Self == SSAFormat {
    /// Built-in SSA (`.ssa`) format.
    static var ssa: SubtitleFormat { SSAFormat() }
}

public extension SubtitleFormat where Self == ASSFormat {
    /// Built-in ASS (`.ass`) format.
    static var ass: SubtitleFormat { ASSFormat() }
}

public extension SubtitleFormat where Self == LRCFormat {
    /// Built-in LRC (`.lrc`) format.
    static var lrc: SubtitleFormat { LRCFormat() }
}

public extension SubtitleFormat where Self == SMIFormat {
    /// Built-in SAMI (`.smi`) format.
    static var smi: SubtitleFormat { SMIFormat() }
}

public extension SubtitleFormat where Self == JSONFormat {
    /// Built-in JSON compatibility format.
    static var json: SubtitleFormat { JSONFormat() }
}
