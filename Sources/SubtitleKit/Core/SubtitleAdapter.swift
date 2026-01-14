import Foundation

public protocol SubtitleFormatAdapter: Sendable {
    var format: SubtitleFormat { get }
    var aliases: [SubtitleFormat] { get }

    func canParse(_ content: String) -> Bool
    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument
    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String
}

extension SubtitleFormatAdapter {
    public var aliases: [SubtitleFormat] {
        [format]
    }

    public func supports(_ format: SubtitleFormat) -> Bool {
        aliases.contains(format)
    }
}
