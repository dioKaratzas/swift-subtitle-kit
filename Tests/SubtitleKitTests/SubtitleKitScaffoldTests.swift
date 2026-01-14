import Testing
@testable import SubtitleKit

@Suite("SubtitleKit Scaffold")
struct SubtitleKitScaffoldTests {
    @Test("Fails detection with empty registry")
    func emptyRegistryCannotDetect() {
        let kit = SubtitleKit()
        #expect(kit.detectFormat(content: "hello") == nil)
    }

    @Test("Throws for unknown format")
    func parseThrowsForUnknownFormat() {
        let kit = SubtitleKit()
        #expect(throws: SubtitleError.self) {
            _ = try kit.parse("hello")
        }
    }
}
