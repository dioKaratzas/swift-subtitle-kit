//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

func timestampString(from milliseconds: Int) -> String {
    let value = max(0, milliseconds)
    let hours = value / 3_600_000
    let minutes = (value / 60_000) % 60
    let seconds = (value / 1_000) % 60
    let ms = value % 1_000
    return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, ms)
}
