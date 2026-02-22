//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Testing
@testable import SubtitleKit

@Suite("Conversion and Detection")
struct ConversionDetectionTests {
    @Test("Detects by file name")
    func detectsByFileName() {
        let content = "Hello world"
        let detected = Subtitle.detectFormat(in: content, fileName: "track.srt")
        #expect(detected.isEqual(.srt))
    }

    @Test("Normalizes BOM and reports line ending")
    func parseTracksInputShape() throws {
        let input = "\u{FEFF}1\r\n00:00:00,000 --> 00:00:01,000\r\nHi"
        let subtitle = try Subtitle.parse(input, options: .init(format: .srt))
        #expect(subtitle.sourceHadByteOrderMark)
        #expect(subtitle.sourceLineEnding == .crlf)
    }

    @Test("Converts SRT to VTT")
    func convertSRTToVTT() throws {
        let srt = "1\n00:00:00,500 --> 00:00:02,000\nHello\n"
        let subtitle = try Subtitle.parse(srt, options: .init(format: .srt))
        let converted = try subtitle.text(format: .vtt, lineEnding: .lf)
        #expect(converted.hasPrefix("WEBVTT"))
        #expect(converted.contains("00:00:00.500 --> 00:00:02.000"))
    }

    @Test("Static one-shot convert API")
    func staticConvertAPI() throws {
        let srt = "1\n00:00:00,500 --> 00:00:02,000\nHello\n"
        let converted = try Subtitle.convert(
            srt,
            from: .srt,
            to: .vtt,
            lineEnding: .lf
        )
        #expect(converted.hasPrefix("WEBVTT"))
        #expect(converted.contains("00:00:00.500 --> 00:00:02.000"))
    }

    @Test("Static one-shot convert supports full serialize options")
    func staticConvertWithSerializeOptions() throws {
        let srt = "1\n00:00:01,000 --> 00:00:02,000\nHello\n"
        let converted = try Subtitle.convert(
            srt,
            from: .srt,
            using: .init(
                format: .smi,
                lineEnding: .lf,
                sami: .init(title: "Episode 1", languageName: "English", languageCode: "en-US", closeTags: true)
            )
        )
        #expect(converted.contains("<TITLE>Episode 1</TITLE>"))
        #expect(converted.contains("</SYNC>"))
    }

    @Test("Converts with resync offset")
    func convertWithResync() throws {
        let srt = "1\n00:00:00,500 --> 00:00:02,000\nHello\n"
        let subtitle = try Subtitle.parse(srt, options: .init(format: .srt))
        let converted = try subtitle
            .resync(.init(offset: 3000))
            .text(format: .srt, lineEnding: .lf)

        #expect(converted.contains("00:00:03,500 --> 00:00:05,000"))
    }

    @Test("Resync by transform closure")
    func resyncUsingTransform() {
        let subtitle = Subtitle(document: SubtitleDocument(formatName: "srt", entries: [
            .cue(.init(id: 1, startTime: 1000, endTime: 2000, rawText: "Hi", plainText: "Hi"))
        ]))
        let shifted = subtitle.resync { start, end, frame in
            (start, end + 250, frame)
        }
        #expect(shifted.cues[0].startTime == 1000)
        #expect(shifted.cues[0].endTime == 2250)
    }

    @Test("JSON serialization handles duplicate attribute keys")
    func jsonDuplicateAttributeKeys() throws {
        let doc = SubtitleDocument(formatName: "json", entries: [
            .cue(.init(
                id: 1, startTime: 0, endTime: 1000,
                rawText: "Hello", plainText: "Hello",
                attributes: [
                    .init(key: "Style", value: "Default"),
                    .init(key: "Style", value: "Override") // Duplicate key
                ]
            ))
        ])
        let subtitle = Subtitle(document: doc)
        // Should not crash; last value wins
        let output = try subtitle.text(format: .json, lineEnding: .lf)
        #expect(output.contains("Override"))
    }
}
