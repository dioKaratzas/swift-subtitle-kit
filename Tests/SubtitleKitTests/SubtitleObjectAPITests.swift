//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Testing
import Foundation
@testable import SubtitleKit

@Suite("Subtitle Object API")
struct SubtitleObjectAPITests {
    @Test("Parses into Subtitle object and converts")
    func parseAndConvert() throws {
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
    func resyncAndSerialize() throws {
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
    func saveToDisk() throws {
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
    func saveInfersOutputFormat() throws {
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
        } catch {
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
        } catch {
            switch error {
            case let .fileWriteFailed(path, details):
                #expect(path == directoryURL.path)
                #expect(!details.isEmpty)
            default:
                Issue.record("Expected SubtitleError.fileWriteFailed, got \(error)")
            }
        }
    }

    @Test("Async load and save round-trip")
    func asyncLoadAndSaveRoundTrip() async throws {
        let subtitle = Subtitle(
            document: .init(formatName: "srt", entries: [
                .cue(.init(id: 1, startTime: 0, endTime: 500, rawText: "Hello", plainText: "Hello")),
                .cue(.init(id: 2, startTime: 750, endTime: 1500, rawText: "World", plainText: "World")),
            ]),
            sourceLineEnding: .lf
        )

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("subtitlekit-async-roundtrip-\(UUID().uuidString).srt")
        defer { try? FileManager.default.removeItem(at: url) }

        try await subtitle.save(to: url)
        let loaded = try await Subtitle.load(from: url)

        #expect(loaded.cues.count == subtitle.cues.count)
        #expect(loaded.cues.first?.plainText == "Hello")
        #expect(loaded.cues.last?.plainText == "World")
    }

    @Test("Async load and save support concurrent batch processing")
    func asyncConcurrentBatchProcessing() async throws {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("subtitlekit-batch-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDirectory) }

        let fileURLs = (1 ... 6).map { index in
            tempDirectory.appendingPathComponent("sample-\(index).srt")
        }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, url) in fileURLs.enumerated() {
                group.addTask {
                    let subtitle = Subtitle(
                        document: .init(formatName: "srt", entries: [
                            .cue(.init(
                                id: index + 1,
                                startTime: index * 1_000,
                                endTime: (index * 1_000) + 750,
                                rawText: "Line \(index + 1)",
                                plainText: "Line \(index + 1)"
                            ))
                        ]),
                        sourceLineEnding: .lf
                    )
                    try await subtitle.save(to: url)
                }
            }
            try await group.waitForAll()
        }

        let loaded = try await withThrowingTaskGroup(of: Subtitle.self, returning: [Subtitle].self) { group in
            for url in fileURLs {
                group.addTask {
                    try await Subtitle.load(from: url)
                }
            }

            var subtitles = [Subtitle]()
            for try await subtitle in group {
                subtitles.append(subtitle)
            }
            return subtitles
        }

        #expect(loaded.count == fileURLs.count)
        #expect(loaded.allSatisfy { $0.cues.count == 1 })
    }
}
