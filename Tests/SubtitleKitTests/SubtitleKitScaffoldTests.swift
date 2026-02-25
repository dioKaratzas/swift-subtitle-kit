//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Testing
@testable import SubtitleKit

@Suite("Basic API")
struct SubtitleKitScaffoldTests {
    @Test("Returns nil when format cannot be detected")
    func undetectedFormat() {
        #expect(Subtitle.detectFormat(in: "hello") == nil)
    }

    @Test("Throws for unknown format")
    func parseThrowsForUnknownFormat() {
        #expect(throws: SubtitleError.self) {
            _ = try Subtitle.parse("hello")
        }
    }
}
