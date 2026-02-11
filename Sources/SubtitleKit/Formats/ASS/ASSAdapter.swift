import Foundation

struct ASSAdapter: SubtitleFormatAdapter {
    let format: SubtitleFormat = .ass

    func canParse(_ content: String) -> Bool {
        SSACommon.isASSContent(content)
    }

    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        try SSACommon.parse(content, hintedFormat: .ass)
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        SSACommon.serialize(document, format: .ass, lineEnding: options.lineEnding)
    }
}
