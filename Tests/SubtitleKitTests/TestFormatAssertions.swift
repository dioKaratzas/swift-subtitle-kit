//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation
@testable import SubtitleKit

extension SubtitleFormat {
    func isEqual(_ other: SubtitleFormat) -> Bool {
        normalizedFormatName == other.normalizedFormatName
    }

    private var normalizedFormatName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

extension Optional where Wrapped == SubtitleFormat {
    func isEqual(_ other: SubtitleFormat) -> Bool {
        guard let format = self else {
            return false
        }
        return format.isEqual(other)
    }
}
