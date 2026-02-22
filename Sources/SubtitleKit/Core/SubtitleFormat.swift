//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

/// A subtitle format adapter that can detect, parse, and serialize subtitle content.
///
/// Implement this protocol to add support for a new subtitle format.
/// Built-in formats include ``SRTFormat``, ``VTTFormat``, ``SBVFormat``,
/// ``SUBFormat``, ``SSAFormat``, ``ASSFormat``, ``LRCFormat``, ``SMIFormat``,
/// and ``JSONFormat``.
///
/// Conforming types must be `Sendable` and safe to use from any thread.
///
/// ## See Also
/// - <doc:CustomFormats>
public protocol SubtitleFormat: Sendable {
    /// Canonical lowercase format name (for example, `"srt"` or `"vtt"`).
    ///
    /// Used as the primary key for format resolution and as the
    /// ``SubtitleDocument/formatName`` stored after parsing.
    var name: String { get }

    /// Alternate names and file extensions accepted by format resolution.
    ///
    /// Defaults to `[name]`. Override to accept additional extensions
    /// (for example, `["line", "lines"]`).
    var aliases: [String] { get }

    /// Returns `true` when the format recognizes the provided raw subtitle text.
    ///
    /// Called during content-based format detection. Implementations should
    /// be fast (ideally a single regex check) and avoid throwing.
    func canParse(_ content: String) -> Bool

    /// Parses raw subtitle text into the unified ``SubtitleDocument`` model.
    ///
    /// When called through ``Subtitle/parse(_:options:)``, the input has
    /// already been BOM-stripped by the engine. Line endings are **not**
    /// normalized — implementations must handle both `\r\n` and `\n`.
    ///
    /// - Parameters:
    ///   - content: Subtitle text (BOM-stripped when called via the engine).
    ///   - options: Parsing options including frame rate and detection hints.
    /// - Throws: ``SubtitleError`` on malformed input.
    func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument

    /// Serializes a unified subtitle document into this format's text representation.
    ///
    /// - Parameters:
    ///   - document: The document to serialize.
    ///   - options: Serialization options including line ending and frame rate.
    /// - Throws: ``SubtitleError`` if serialization fails (for example, invalid frame rate).
    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String
}

public extension SubtitleFormat {
    /// Uses the canonical name as the only alias by default.
    var aliases: [String] {
        [name]
    }

    /// Registers this format in the current global ``SubtitleFormatRegistry``.
    func register() {
        SubtitleFormatRegistry.register(self)
    }
}

public extension SubtitleFormat where Self == SRTFormat {
    /// Built-in SubRip (`.srt`) format.
    static var srt: SubtitleFormat {
        SRTFormat()
    }
}

public extension SubtitleFormat where Self == VTTFormat {
    /// Built-in WebVTT (`.vtt`) format.
    static var vtt: SubtitleFormat {
        VTTFormat()
    }
}

public extension SubtitleFormat where Self == SBVFormat {
    /// Built-in SubViewer (`.sbv`) format.
    static var sbv: SubtitleFormat {
        SBVFormat()
    }
}

public extension SubtitleFormat where Self == SUBFormat {
    /// Built-in MicroDVD (`.sub`) format.
    static var sub: SubtitleFormat {
        SUBFormat()
    }
}

public extension SubtitleFormat where Self == SSAFormat {
    /// Built-in SSA (`.ssa`) format.
    static var ssa: SubtitleFormat {
        SSAFormat()
    }
}

public extension SubtitleFormat where Self == ASSFormat {
    /// Built-in ASS (`.ass`) format.
    static var ass: SubtitleFormat {
        ASSFormat()
    }
}

public extension SubtitleFormat where Self == LRCFormat {
    /// Built-in LRC (`.lrc`) format.
    static var lrc: SubtitleFormat {
        LRCFormat()
    }
}

public extension SubtitleFormat where Self == SMIFormat {
    /// Built-in SAMI (`.smi`) format.
    static var smi: SubtitleFormat {
        SMIFormat()
    }
}

public extension SubtitleFormat where Self == JSONFormat {
    /// Built-in JSON compatibility format.
    static var json: SubtitleFormat {
        JSONFormat()
    }
}
