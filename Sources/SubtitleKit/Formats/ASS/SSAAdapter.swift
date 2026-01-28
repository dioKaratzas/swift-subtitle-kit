import Foundation

/// SSA (`.ssa`) subtitle format adapter.
public struct SSAFormat: SubtitleFormat {
    public let name = "ssa"

    public func canParse(_ content: String) -> Bool {
        SSACommon.isSSAContent(content)
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument {
        try SSACommon.parse(content, hintedFormatName: name)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        SSACommon.serialize(document, formatName: name, lineEnding: options.lineEnding)
    }
}
