import Foundation

protocol SubtitleFormatAdapter: Sendable {
    var format: SubtitleFormat { get }
    var aliases: [SubtitleFormat] { get }

    func canParse(_ content: String) -> Bool
    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument
    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String
}

extension SubtitleFormatAdapter {
    var aliases: [SubtitleFormat] {
        [format]
    }
}
