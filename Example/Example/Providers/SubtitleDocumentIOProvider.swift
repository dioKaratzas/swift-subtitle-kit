//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation
import SubtitleKit

struct SubtitleDocumentIOProvider {
    func loadSubtitle(from url: URL) throws -> Subtitle {
        try Subtitle.load(from: url)
    }

    func saveSubtitle(
        _ subtitle: Subtitle,
        to url: URL,
        format: (any SubtitleFormat)?
    ) throws {
        try subtitle.save(to: url, format: format)
    }

    func serializedText(for subtitle: Subtitle, preferredFormat: (any SubtitleFormat)?) -> String {
        do {
            return try subtitle.text(format: preferredFormat)
        } catch {
            return subtitle.cues.map { cue in
                let header = "\(cue.id)  [\(timestampString(from: cue.startTime)) → \(timestampString(from: cue.endTime))]"
                return header + "\n" + cue.rawText
            }
            .joined(separator: "\n\n")
        }
    }
}
