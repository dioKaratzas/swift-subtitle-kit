//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation

/// ASS (`.ass`) subtitle format adapter.
public struct ASSFormat: SubtitleFormat {
    public let name = "ass"

    public func canParse(_ content: String) -> Bool {
        SSACommon.isASSContent(content)
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument {
        try SSACommon.parse(content, hintedFormatName: name)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        SSACommon.serialize(document, formatName: name, lineEnding: options.lineEnding)
    }
}
