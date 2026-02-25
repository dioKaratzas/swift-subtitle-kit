//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Testing
@testable import SubtitleKit

@Suite("Cleaning Options")
struct CleaningOptionsTests {
    @Test("Removes SDH markers")
    func removeSDH() {
        let subtitle = makeSubtitle(cues: [
            .init(
                id: 1,
                startTime: 0,
                endTime: 1_000,
                rawText: "[MUSIC] (laughing) Hello there",
                plainText: "[MUSIC] (laughing) Hello there"
            )
        ])

        let cleaned = subtitle.clean([.removeSDH])
        let cue = cleaned.cues[0]
        #expect(cue.rawText == "Hello there")
        #expect(cue.plainText == "Hello there")
    }

    @Test("Removes watermark cues and lines")
    func removeWatermarks() {
        let subtitle = makeSubtitle(cues: [
            .init(
                id: 1,
                startTime: 0,
                endTime: 1_000,
                rawText: "Subtitles by OpenSubtitles.org",
                plainText: "Subtitles by OpenSubtitles.org"
            ),
            .init(id: 2, startTime: 1_000, endTime: 2_000, rawText: "Hello world", plainText: "Hello world"),
            .init(
                id: 3,
                startTime: 2_000,
                endTime: 3_000,
                rawText: "Visit www.example.com",
                plainText: "Visit www.example.com"
            )
        ])

        let cleaned = subtitle.clean([.removeWatermarks])
        #expect(cleaned.cues.count == 1)
        #expect(cleaned.cues[0].plainText == "Hello world")
    }

    @Test("Removes speaker labels")
    func removeSpeakerLabels() {
        let subtitle = makeSubtitle(cues: [
            .init(
                id: 1,
                startTime: 0,
                endTime: 1_000,
                rawText: "GEORGE: Hello\n>> ANNA: Hi",
                plainText: "GEORGE: Hello\n>> ANNA: Hi"
            )
        ])

        let cleaned = subtitle.clean([.removeSpeakerLabels])
        #expect(cleaned.cues[0].plainText == "Hello\nHi")
    }

    @Test("Removes cues with music note symbols")
    func removeMusicCues() {
        let subtitle = makeSubtitle(cues: [
            .init(id: 1, startTime: 0, endTime: 1_000, rawText: "♪ We sing ♪", plainText: "♪ We sing ♪"),
            .init(id: 2, startTime: 1_000, endTime: 2_000, rawText: "Spoken line", plainText: "Spoken line")
        ])

        let cleaned = subtitle.clean([.removeCuesContainingMusicNotes])
        #expect(cleaned.cues.count == 1)
        #expect(cleaned.cues[0].plainText == "Spoken line")
    }

    @Test("Removes all line breaks from cue text")
    func removeAllLineBreaks() {
        let subtitle = makeSubtitle(cues: [
            .init(id: 1, startTime: 0, endTime: 1_000, rawText: "Line one\nLine two", plainText: "Line one\nLine two")
        ])

        let cleaned = subtitle.clean([.removeAllLineBreaks])
        #expect(cleaned.cues[0].rawText == "Line one Line two")
    }

    @Test("Merges overlapping cues with same text")
    func mergeCuesWithSameText() {
        let subtitle = makeSubtitle(cues: [
            .init(id: 1, startTime: 0, endTime: 1_000, rawText: "Hello", plainText: "Hello"),
            .init(id: 2, startTime: 900, endTime: 2_000, rawText: "Hello", plainText: "Hello"),
            .init(id: 3, startTime: 2_100, endTime: 3_000, rawText: "Hello", plainText: "Hello")
        ])

        let cleaned = subtitle.clean([.mergeCuesWithSameText])
        #expect(cleaned.cues.count == 2)
        #expect(cleaned.cues[0].startTime == 0)
        #expect(cleaned.cues[0].endTime == 2_000)
        #expect(cleaned.cues[1].startTime == 2_100)
    }

    @Test("Fixes mostly uppercase text")
    func fixUppercaseText() {
        let subtitle = makeSubtitle(cues: [
            .init(
                id: 1,
                startTime: 0,
                endTime: 1_000,
                rawText: "HELLO WORLD. HOW ARE YOU?",
                plainText: "HELLO WORLD. HOW ARE YOU?"
            )
        ])

        let cleaned = subtitle.clean([.fixUppercaseText])
        #expect(cleaned.cues[0].plainText == "Hello world. How are you?")
    }

    @Test("Removes curly bracket tags")
    func removeCurlyTags() {
        let subtitle = makeSubtitle(cues: [
            .init(id: 1, startTime: 0, endTime: 1_000, rawText: "{\\an8}{\\i1}Hello", plainText: "{\\an8}{\\i1}Hello")
        ])

        let cleaned = subtitle.clean([.removeCurlyBracketTags])
        #expect(cleaned.cues[0].rawText == "Hello")
    }

    @Test("Removes HTML tags")
    func removeHTMLTags() {
        let subtitle = makeSubtitle(cues: [
            .init(
                id: 1,
                startTime: 0,
                endTime: 1_000,
                rawText: "<i>Hello</i> <b>world</b>",
                plainText: "<i>Hello</i> <b>world</b>"
            )
        ])

        let cleaned = subtitle.clean([.removeHTMLTags])
        #expect(cleaned.cues[0].rawText == "Hello world")
    }

    @Test("Mutating clean supports set-based options")
    func mutatingCleanSetOptions() {
        var subtitle = makeSubtitle(cues: [
            .init(id: 1, startTime: 0, endTime: 1_000, rawText: "GEORGE: HELLO", plainText: "GEORGE: HELLO")
        ])

        subtitle.applyClean(Set([.removeSpeakerLabels, .fixUppercaseText]))
        #expect(subtitle.cues[0].plainText == "Hello")
    }

    private func makeSubtitle(cues: [SubtitleCue]) -> Subtitle {
        Subtitle(
            document: .init(
                formatName: "srt",
                entries: cues.map(SubtitleEntry.cue)
            )
        )
    }
}
