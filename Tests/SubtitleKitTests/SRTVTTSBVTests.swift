import Testing
@testable import SubtitleKit

@Suite("Core Format Adapters")
struct SRTVTTSBVTests {
    let kit = SubtitleKit()

    @Test("Detects by extension before sniffing")
    func extensionDetectionWins() {
        let content = "WEBVTT\n\n00:00.000 --> 00:01.000\nHello"
        let detected = kit.detectFormat(content: content, fileExtension: "srt")
        #expect(detected == .srt)
    }

    @Test("Parses and serializes SRT")
    func parseSerializeSRT() throws {
        let srt = "1\n00:00:00,500 --> 00:00:02,000\n>> JOHN: Hello <b>world</b>\n"
        let document = try kit.parse(srt, options: .init(format: .srt))
        let cue = try #require(document.cues.first)
        #expect(cue.startTime == 500)
        #expect(cue.endTime == 2000)
        #expect(cue.plainText == "Hello world")

        let rebuilt = try kit.serialize(document, options: .init(format: .srt, lineEnding: .lf))
        #expect(rebuilt.contains("00:00:00,500 --> 00:00:02,000"))
    }

    @Test("Parses and serializes VTT")
    func parseSerializeVTT() throws {
        let vtt = "WEBVTT\n\nNOTE\nMeta\n\nchapter-1\n00:01.000 --> 00:02.500 align:start\nHi <i>there</i>\n"
        let document = try kit.parse(vtt, options: .init(format: .vtt))
        #expect(document.entries.count == 3)

        let cue = try #require(document.cues.first)
        #expect(cue.cueIdentifier == "chapter-1")
        #expect(cue.attributes.first(where: { $0.key == "settings" })?.value == "align:start")
        #expect(cue.plainText == "Hi there")

        let rebuilt = try kit.serialize(document, options: .init(format: .vtt, lineEnding: .lf))
        #expect(rebuilt.hasPrefix("WEBVTT"))
    }

    @Test("Parses and serializes SBV")
    func parseSerializeSBV() throws {
        let sbv = "0:00:00.000,0:00:02.000\n>> ALICE: Line one[br]Line two\n"
        let document = try kit.parse(sbv, options: .init(format: .sbv))

        let cue = try #require(document.cues.first)
        #expect(cue.rawText == ">> ALICE: Line one\nLine two")
        #expect(cue.plainText == "Line one\nLine two")

        let rebuilt = try kit.serialize(document, options: .init(format: .sbv, lineEnding: .lf))
        #expect(rebuilt.contains("00:00:00.000,00:00:02.000"))
    }
}
