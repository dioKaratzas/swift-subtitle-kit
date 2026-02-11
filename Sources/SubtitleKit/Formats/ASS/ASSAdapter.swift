import Foundation

/// ASS (`.ass`) subtitle format adapter.
public struct ASSFormat: SubtitleFormat {
    public let name = "ass"

    public func canParse(_ content: String) -> Bool {
        SSACommon.isASSContent(content)
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        try SSACommon.parse(content, hintedFormatName: name)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        SSACommon.serialize(document, formatName: name, lineEnding: options.lineEnding)
    }
}
