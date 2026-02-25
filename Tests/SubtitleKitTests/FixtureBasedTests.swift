//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Testing
import Foundation
@testable import SubtitleKit

@Suite("Fixture Parsing")
struct FixtureParsingTests {
    @Test("Parses embedded BOM SRT fixture")
    func parseEmbeddedBOMSRTFixture() throws {
        let content = try FixtureSupport.fixtureText(
            "embedded-bom-srt-fixture",
            ext: "srt"
        )
        let subtitle = try Subtitle.parse(content, options: .init(format: .srt))
        #expect(!subtitle.cues.isEmpty)
    }

    @Test("Parses real fixtures", arguments: FixtureSupport.fixtureFormatNames)
    func parseFixture(for formatName: String) throws {
        let format = FixtureSupport.format(named: formatName)
        let content = try FixtureSupport.sampleText(for: formatName)
        let subtitle = try Subtitle.parse(content, options: .init(format: format))
        #expect(!subtitle.cues.isEmpty)
    }

    @Test("Round-trips real fixtures", arguments: FixtureSupport.fixtureFormatNames)
    func roundTripFixture(for formatName: String) throws {
        let format = FixtureSupport.format(named: formatName)
        let content = try FixtureSupport.sampleText(for: formatName)
        let subtitle = try Subtitle.parse(content, options: .init(format: format))
        let serialized = try subtitle.text(format: format, lineEnding: .lf)
        let reparsed = try Subtitle.parse(serialized, options: .init(format: format))

        #expect(reparsed.cues.count == subtitle.cues.count)
        #expect(reparsed.cues.first?.startTime == subtitle.cues.first?.startTime)
        #expect(reparsed.cues.last?.endTime == subtitle.cues.last?.endTime)
    }

    @Test("Converts fixture to SRT and VTT", arguments: FixtureSupport.fixtureFormatNames)
    func convertFixture(for formatName: String) throws {
        let format = FixtureSupport.format(named: formatName)
        let content = try FixtureSupport.sampleText(for: formatName)
        let subtitle = try Subtitle.parse(content, options: .init(format: format))

        let asSRT = try subtitle.convert(to: .srt, lineEnding: .lf)
        let asVTT = try subtitle.convert(to: .vtt, lineEnding: .lf)

        #expect(asSRT.format.isEqual(.srt))
        #expect(asVTT.format.isEqual(.vtt))
        #expect(!asSRT.cues.isEmpty)
        #expect(!asVTT.cues.isEmpty)
    }
}

@Suite("Edge Cases")
struct EdgeCaseTests {
    @Test("Handles BOM and CRLF")
    func bomAndCRLF() throws {
        let input = "\u{FEFF}1\r\n00:00:00,500 --> 00:00:02,000\r\nHello\r\n"
        let subtitle = try Subtitle.parse(input, options: .init(format: .srt))

        #expect(subtitle.sourceHadByteOrderMark)
        #expect(subtitle.sourceLineEnding == .crlf)
        #expect(subtitle.cues.count == 1)

        let output = try subtitle.text(format: .srt)
        #expect(output.contains("\r\n"))
    }

    @Test("Handles embedded BOM inside SRT stream")
    func embeddedBOMInSRTStream() throws {
        let input = "0\n00:00:00,000 --> 00:00:01,000\nLead in\n\n\u{FEFF}1\n00:00:01,500 --> 00:00:03,000\nHello\n"
        let subtitle = try Subtitle.parse(input, options: .init(format: .srt))
        #expect(subtitle.cues.count == 2)
        #expect(subtitle.cues[1].startTime == 1500)
    }

    @Test("Throws on malformed timestamp")
    func malformedTimestampThrows() {
        let broken = "1\n00:AB:00,500 --> 00:00:02,000\nHello\n"
        #expect(throws: SubtitleError.self) {
            _ = try Subtitle.parse(broken, options: .init(format: .srt))
        }
    }

    @Test("Handles empty metadata sections")
    func emptyMetadataSections() throws {
        let vtt = "WEBVTT\n\nNOTE\n\n00:00.000 --> 00:01.000\nHello\n"
        let subtitle = try Subtitle.parse(vtt, options: .init(format: .vtt))
        #expect(subtitle.cues.count == 1)
        #expect(subtitle.entries.count >= 2)
    }

    @Test("Handles metadata quirks")
    func metadataQuirks() throws {
        let lrc = try FixtureSupport.sampleText(for: "lrc")
        let subtitle = try Subtitle.parse(lrc, options: .init(format: .lrc))
        let metaCount = subtitle.entries.count(where: {
            if case .metadata = $0 {
                return true
            }
            return false
        })
        #expect(metaCount > 0)
    }
}

@Suite("Performance Sanity")
struct PerformanceSanityTests {
    @Test("Parses and serializes large SRT within sanity threshold")
    func largeSRTPerformance() throws {
        let cueCount = 8_000
        let srt = FixtureSupport.generatedSRT(cueCount: cueCount)
        let clock = ContinuousClock()

        let parseStart = clock.now
        let subtitle = try Subtitle.parse(srt, options: .init(format: .srt))
        let parseEnd = clock.now
        #expect(subtitle.cues.count == cueCount)
        #expect(parseEnd < parseStart.advanced(by: .seconds(8)))

        let serializeStart = clock.now
        let output = try subtitle.text(format: .srt, lineEnding: .lf)
        let serializeEnd = clock.now
        #expect(!output.isEmpty)
        #expect(serializeEnd < serializeStart.advanced(by: .seconds(8)))
    }
}
