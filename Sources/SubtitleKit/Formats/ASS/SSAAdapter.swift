import Foundation

struct SSAAdapter: SubtitleFormatAdapter {
    let format: SubtitleFormat = .ssa

    func canParse(_ content: String) -> Bool {
        SSACommon.isSSAContent(content)
    }

    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        try SSACommon.parse(content, hintedFormat: .ssa)
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        SSACommon.serialize(document, format: .ssa, lineEnding: options.lineEnding)
    }
}
