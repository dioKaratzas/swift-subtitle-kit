import Foundation
import Testing
@testable import SubtitleKit

@Suite("Fixture Parsing")
struct FixtureParsingTests {
    @Test("Parses real fixtures", arguments: SubtitleFormat.allCases)
    func parseFixture(for format: SubtitleFormat) throws {
        let content = try FixtureSupport.sampleText(for: format)
        let subtitle = try Subtitle.parse(content, options: .init(format: format))
        #expect(!subtitle.cues.isEmpty)
    }

    @Test("Round-trips real fixtures", arguments: SubtitleFormat.allCases)
    func roundTripFixture(for format: SubtitleFormat) throws {
        let content = try FixtureSupport.sampleText(for: format)
        let subtitle = try Subtitle.parse(content, options: .init(format: format))
        let serialized = try subtitle.text(format: format, lineEnding: .lf)
        let reparsed = try Subtitle.parse(serialized, options: .init(format: format))

        #expect(reparsed.cues.count == subtitle.cues.count)
        #expect(reparsed.cues.first?.startTime == subtitle.cues.first?.startTime)
        #expect(reparsed.cues.last?.endTime == subtitle.cues.last?.endTime)
    }

    @Test("Converts fixture to SRT and VTT", arguments: SubtitleFormat.allCases)
    func convertFixture(for format: SubtitleFormat) throws {
        let content = try FixtureSupport.sampleText(for: format)
        let subtitle = try Subtitle.parse(content, options: .init(format: format))

        let asSRT = try subtitle.convert(to: .srt, lineEnding: .lf)
        let asVTT = try subtitle.convert(to: .vtt, lineEnding: .lf)

        #expect(asSRT.format == .srt)
        #expect(asVTT.format == .vtt)
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
        let lrc = try FixtureSupport.sampleText(for: .lrc)
        let subtitle = try Subtitle.parse(lrc, options: .init(format: .lrc))
        let metaCount = subtitle.entries.filter {
            if case .metadata = $0 { return true }
            return false
        }.count
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
