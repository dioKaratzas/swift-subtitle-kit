import Foundation
import Testing
@testable import SubtitleKit

@Suite("Subtitle Object API")
struct SubtitleObjectAPITests {
    @Test("Parses into Subtitle object and converts")
    func parseAndConvert() throws {
        let srt = "1\n00:00:00,250 --> 00:00:01,500\nHello\n"
        let subtitle = try Subtitle.parse(srt, format: .srt)
        #expect(subtitle.format == .srt)
        #expect(subtitle.cues.count == 1)

        let vtt = try subtitle.convertedText(to: .vtt, lineEnding: .lf)
        #expect(vtt.hasPrefix("WEBVTT"))

        let converted = try subtitle.convert(to: .vtt, lineEnding: .lf)
        #expect(converted.format == .vtt)
        #expect(converted.cues.count == 1)
    }

    @Test("Resyncs and serializes from Subtitle object")
    func resyncAndSerialize() throws {
        let subtitle = Subtitle(
            document: .init(format: .srt, entries: [
                .cue(.init(id: 1, startTime: 1000, endTime: 1500, rawText: "Hi", plainText: "Hi"))
            ])
        )

        let shifted = subtitle.resync(.init(offset: 500))
        #expect(shifted.cues[0].startTime == 1500)
        #expect(shifted.cues[0].endTime == 2000)

        let output = try shifted.text(format: .srt, lineEnding: .lf)
        #expect(output.contains("00:00:01,500 --> 00:00:02,000"))
    }

    @Test("Saves subtitle file")
    func saveToDisk() throws {
        let subtitle = Subtitle(
            document: .init(format: .srt, entries: [
                .cue(.init(id: 1, startTime: 0, endTime: 500, rawText: "Hello", plainText: "Hello"))
            ]),
            sourceLineEnding: .lf
        )

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("subtitlekit-save-test-\(UUID().uuidString).srt")
        defer { try? FileManager.default.removeItem(at: url) }

        try subtitle.save(to: url) // infers .srt from output extension

        let raw = try String(contentsOf: url, encoding: .utf8)
        #expect(raw.contains("00:00:00,000 --> 00:00:00,500"))
    }

    @Test("Save infers format from output extension")
    func saveInfersOutputFormat() throws {
        let subtitle = Subtitle(
            document: .init(format: nil, entries: [
                .cue(.init(id: 1, startTime: 1000, endTime: 2000, rawText: "Hello", plainText: "Hello"))
            ]),
            sourceLineEnding: .lf
        )

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("subtitlekit-save-infer-\(UUID().uuidString).vtt")
        defer { try? FileManager.default.removeItem(at: url) }

        try subtitle.save(to: url)
        let raw = try String(contentsOf: url, encoding: .utf8)
        #expect(raw.hasPrefix("WEBVTT"))
    }
}
