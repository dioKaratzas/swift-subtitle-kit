import Testing
@testable import SubtitleKit

@Suite("Cleaning Report")
struct CleaningReportTests {
    @Test("cleanWithReport returns counts and per-cue statuses")
    func countsAndStatuses() {
        let subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "[MUSIC]"),
            cue(id: 2, start: 1_000, end: 2_000, text: "GEORGE: HELLO"),
            cue(id: 3, start: 2_000, end: 3_000, text: "Plain text")
        ])

        let result = subtitle.cleanWithReport([.removeSDH, .removeSpeakerLabels, .fixUppercaseText])
        let report = result.report

        #expect(report.originalCueCount == 3)
        #expect(report.remainingCueCount == 2)
        #expect(report.removedCueCount == 1)
        #expect(report.modifiedCueCount == 1)
        #expect(report.unchangedCueCount == 1)

        #expect(report.changes[0].cueID == 1)
        #expect(report.changes[0].status == .removed)
        #expect(report.changes[0].cleaned == nil)
        #expect(report.changes[0].changedBy == [.removeSDH])

        #expect(report.changes[1].cueID == 2)
        #expect(report.changes[1].status == .modified)
        #expect(report.changes[1].cleaned?.plainText == "Hello")
        #expect(report.changes[1].changedBy == [.removeSpeakerLabels, .fixUppercaseText])

        #expect(report.changes[2].cueID == 3)
        #expect(report.changes[2].status == .unchanged)
        #expect(report.changes[2].changedBy.isEmpty)
    }

    @Test("Merge reports one modified and one removed cue")
    func mergeReporting() {
        let subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "Hello"),
            cue(id: 2, start: 900, end: 2_000, text: "Hello")
        ])

        let result = subtitle.cleanWithReport([.mergeCuesWithSameText])
        let report = result.report

        #expect(report.originalCueCount == 2)
        #expect(report.remainingCueCount == 1)
        #expect(report.modifiedCueCount == 1)
        #expect(report.removedCueCount == 1)

        #expect(report.changes[0].status == .modified)
        #expect(report.changes[0].cleaned?.endTime == 2_000)
        #expect(report.changes[0].changedBy == [.mergeCuesWithSameText])

        #expect(report.changes[1].status == .removed)
        #expect(report.changes[1].changedBy == [.mergeCuesWithSameText])
        #expect(report.changes[1].cleaned == nil)
    }

    @Test("Set-based report API matches deterministic array ordering")
    func setOverloadParity() {
        let subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "GEORGE: HELLO")
        ])
        let options: Set<SubtitleCleanOption> = [.fixUppercaseText, .removeSpeakerLabels]

        let setResult = subtitle.cleanWithReport(options)
        let arrayResult = subtitle.cleanWithReport(SubtitleCleanOption.allCases.filter(options.contains))

        #expect(setResult.subtitle == arrayResult.subtitle)
        #expect(setResult.report == arrayResult.report)
    }

    @Test("Mutating report API returns same report and mutates subtitle")
    func mutatingReportAPI() {
        var subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "<i>Hello</i>")
        ])

        let report = subtitle.applyCleanWithReport([.removeHTMLTags])

        #expect(subtitle.cues[0].plainText == "Hello")
        #expect(report.modifiedCueCount == 1)
        #expect(report.removedCueCount == 0)
        #expect(report.changes[0].changedBy == [.removeHTMLTags])
    }

    @Test("changedBy is deduplicated and ordered by allCases")
    func changedByOrderingAndDeduplication() {
        let subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "GEORGE: HELLO")
        ])

        let result = subtitle.cleanWithReport([
            .fixUppercaseText,
            .removeSpeakerLabels,
            .fixUppercaseText
        ])

        let change = result.report.changes[0]
        #expect(change.status == .modified)
        #expect(change.changedBy == [.removeSpeakerLabels, .fixUppercaseText])
    }

    @Test("Report tracks cues touched by multiple options before removal")
    func removedCueTracksMultipleOptions() {
        let subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "[MUSIC]\nwww.example.com")
        ])

        let result = subtitle.cleanWithReport([.removeWatermarks, .removeSDH])
        let change = result.report.changes[0]

        #expect(change.status == .removed)
        #expect(change.cleaned == nil)
        #expect(change.changedBy == [.removeSDH, .removeWatermarks])
    }

    @Test("Empty options produce unchanged report")
    func emptyOptionsReport() {
        let subtitle = makeSubtitle(cues: [
            cue(id: 1, start: 0, end: 1_000, text: "Hello")
        ])

        let result = subtitle.cleanWithReport([])
        let report = result.report

        #expect(result.subtitle == subtitle)
        #expect(report.originalCueCount == 1)
        #expect(report.remainingCueCount == 1)
        #expect(report.modifiedCueCount == 0)
        #expect(report.removedCueCount == 0)
        #expect(report.unchangedCueCount == 1)
        #expect(report.changes[0].status == .unchanged)
        #expect(report.changes[0].changedBy.isEmpty)
    }

    private func makeSubtitle(cues: [SubtitleCue]) -> Subtitle {
        Subtitle(
            document: .init(
                formatName: "srt",
                entries: cues.map(SubtitleEntry.cue)
            )
        )
    }

    private func cue(id: Int, start: Int, end: Int, text: String) -> SubtitleCue {
        .init(
            id: id,
            startTime: start,
            endTime: end,
            rawText: text,
            plainText: text
        )
    }
}
