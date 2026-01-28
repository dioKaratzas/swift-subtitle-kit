import Foundation
import Testing
@testable import SubtitleKit

@Suite("Subtitle Object API")
struct SubtitleObjectAPITests {
    @Test("Parses into Subtitle object and converts")
    func parseAndConvert() throws(any Error) {
        let srt = "1\n00:00:00,250 --> 00:00:01,500\nHello\n"
        let subtitle = try Subtitle.parse(srt, format: .srt)
        #expect(subtitle.format.isEqual(.srt))
        #expect(subtitle.cues.count == 1)

        let vtt = try subtitle.text(format: .vtt, lineEnding: .lf)
        #expect(vtt.hasPrefix("WEBVTT"))

        let converted = try subtitle.convert(to: .vtt, lineEnding: .lf)
        #expect(converted.format.isEqual(.vtt))
        #expect(converted.cues.count == 1)
    }

    @Test("Resyncs and serializes from Subtitle object")
    func resyncAndSerialize() throws(any Error) {
        let subtitle = Subtitle(
            document: .init(formatName: "srt", entries: [
                .cue(.init(id: 1, startTime: 1000, endTime: 1500, rawText: "Hi", plainText: "Hi"))
            ])
        )

        let shifted = subtitle.resync(SubtitleResyncOptions(offset: 500))
        #expect(shifted.cues[0].startTime == 1500)
        #expect(shifted.cues[0].endTime == 2000)

        let output = try shifted.text(format: .srt, lineEnding: .lf)
        #expect(output.contains("00:00:01,500 --> 00:00:02,000"))
    }

    @Test("Saves subtitle file")
    func saveToDisk() throws(any Error) {
        let subtitle = Subtitle(
            document: .init(formatName: "srt", entries: [
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
    func saveInfersOutputFormat() throws(any Error) {
        let subtitle = Subtitle(
            document: .init(entries: [
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

    @Test("Load maps file IO errors to SubtitleError.fileReadFailed")
    func loadMapsReadErrors() {
        let missingURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("subtitlekit-missing-\(UUID().uuidString).srt")

        do {
            _ = try Subtitle.load(from: missingURL)
            Issue.record("Expected loading a missing file to throw")
        } catch let error {
            switch error {
            case let .fileReadFailed(path, details):
                #expect(path == missingURL.path)
                #expect(!details.isEmpty)
            default:
                Issue.record("Expected SubtitleError.fileReadFailed, got \(error)")
            }
        }
    }

    @Test("Save maps file IO errors to SubtitleError.fileWriteFailed")
    func saveMapsWriteErrors() {
        let subtitle = Subtitle(
            document: .init(formatName: "srt", entries: [
                .cue(.init(id: 1, startTime: 0, endTime: 500, rawText: "Hello", plainText: "Hello"))
            ]),
            sourceLineEnding: .lf
        )
        let directoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        do {
            try subtitle.save(to: directoryURL)
            Issue.record("Expected writing to a directory URL to throw")
        } catch let error {
            switch error {
            case let .fileWriteFailed(path, details):
                #expect(path == directoryURL.path)
                #expect(!details.isEmpty)
            default:
                Issue.record("Expected SubtitleError.fileWriteFailed, got \(error)")
            }
        }
    }
}
