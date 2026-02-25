//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SubtitleKit
import UniformTypeIdentifiers

struct SubtitleFormatCatalogProvider {
    let supportedFormats: [any SubtitleFormat]

    init(formats: [any SubtitleFormat] = Subtitle.supportedFormats()) {
        self.supportedFormats = formats.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var formatChoices: [FormatChoice] {
        supportedFormats.map { FormatChoice(name: $0.name) }
    }

    var openContentTypes: [UTType] {
        let extensions = Set(supportedFormats.flatMap { [$0.name] + $0.aliases })
        let contentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        return contentTypes.isEmpty ? [.plainText, .json] : contentTypes
    }

    func resolveFormat(named name: String) -> (any SubtitleFormat)? {
        supportedFormats.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}
