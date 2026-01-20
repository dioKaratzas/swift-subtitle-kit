import Testing
@testable import SubtitleKit

@Suite("Additional Format Adapters")
struct AdditionalFormatsTests {
    @Test("Parses and serializes SSA")
    func parseSerializeSSA() throws {
        let content = "[Script Info]\nScriptType: v4.00\n\n[V4 Styles]\nFormat: Name, Fontname, Fontsize\nStyle: Default,Arial,20\n\n[Events]\nFormat: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\nDialogue: Marked=0,0:00:01.00,0:00:02.50,Default,NTP,0000,0000,0000,,Hello\\NWorld\n"
        let parsed = try Subtitle.parse(content, options: .init(format: .ssa))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].plainText == "Hello\nWorld")

        let serialized = try parsed.text(format: .ssa, lineEnding: .lf)
        #expect(serialized.contains("[Events]"))
    }

    @Test("Parses and serializes ASS")
    func parseSerializeASS() throws {
        let content = "[Script Info]\nScriptType: v4.00+\n\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize\nStyle: Default,Arial,20\n\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\nDialogue: 0,0:00:01.00,0:00:02.00,Default,NTP,0000,0000,0000,,{\\pos(1,1)}Hi\n"
        let parsed = try Subtitle.parse(content, options: .init(format: .ass))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].plainText == "Hi")

        let serialized = try parsed.text(format: .ass, lineEnding: .lf)
        #expect(serialized.contains("[V4+ Styles]"))
    }

    @Test("Parses and serializes SUB")
    func parseSerializeSUB() throws {
        let content = "{25}{50}Line 1|Line 2\n"
        let parsed = try Subtitle.parse(content, options: .init(format: .sub, fps: 25))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].frameRange?.start == 25)
        #expect(parsed.cues[0].startTime == 1000)  // frame 25 / 25fps = 1s = 1000ms
        #expect(parsed.cues[0].endTime == 2000)     // frame 50 / 25fps = 2s = 2000ms

        let serialized = try parsed.text(format: .sub, lineEnding: .lf, fps: 25)
        #expect(serialized.contains("{25}{50}"))
    }

    @Test("Parses and serializes LRC")
    func parseSerializeLRC() throws {
        let content = "[ar:Artist]\n\n[00:01.00]Hello\n[00:03.00]World\n"
        let parsed = try Subtitle.parse(content, options: .init(format: .lrc))
        #expect(parsed.cues.count == 2)
        #expect(parsed.cues[0].endTime == parsed.cues[1].startTime)

        let serialized = try parsed.text(format: .lrc, lineEnding: .lf)
        #expect(serialized.contains("[ar:Artist]"))
    }

    @Test("Parses and serializes SMI")
    func parseSerializeSMI() throws {
        let content = "<SAMI><BODY><SYNC Start=1000><P Class=LANG>Hello<BR>World<SYNC Start=2000><P Class=LANG>&nbsp;</BODY></SAMI>"
        let parsed = try Subtitle.parse(content, options: .init(format: .smi))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].plainText == "Hello\nWorld")

        let serialized = try parsed.text(using: .init(format: .smi, lineEnding: .lf, sami: .init(closeTags: true)))
        #expect(serialized.contains("<SYNC Start=1000>"))
    }

    @Test("SUB converts to SRT with correct timestamps")
    func subToSRTConversion() throws {
        // Frame 0 at 25fps = 0ms, Frame 75 at 25fps = 3000ms
        let content = "{0}{75}Hello\n"
        let parsed = try Subtitle.parse(content, options: .init(format: .sub, fps: 25))
        #expect(parsed.cues[0].startTime == 0)
        #expect(parsed.cues[0].endTime == 3000)

        let srt = try parsed.text(format: .srt, lineEnding: .lf)
        #expect(srt.contains("00:00:00,000 --> 00:00:03,000"))
    }

    @Test("SUB serializes all newlines as pipes")
    func subMultiLineSerialize() throws {
        let doc = SubtitleDocument(formatName: "sub", entries: [
            .cue(.init(id: 1, startTime: 0, endTime: 2000,
                        rawText: "Line 1\nLine 2\nLine 3",
                        plainText: "Line 1\nLine 2\nLine 3",
                        frameRange: .init(start: 0, end: 50)))
        ])
        let subtitle = Subtitle(document: doc)
        let output = try subtitle.text(format: .sub, lineEnding: .lf, fps: 25)
        #expect(output.contains("{0}{50}Line 1|Line 2|Line 3"))
    }

    @Test("LRC detects minimal content without metadata")
    func lrcDetectsMinimalContent() {
        let minimal = "[00:01.00]Hello"
        let detected = Subtitle.detectFormat(in: minimal)
        #expect(detected.isEqual(.lrc))
    }

    @Test("SMI parser handles closed SYNC tags")
    func smiClosedSyncTags() throws {
        let content = "<SAMI><BODY><SYNC Start=500></SYNC><SYNC Start=500><P Class=LANG>Hi</SYNC><SYNC Start=1500><P Class=LANG>&nbsp;</SYNC></BODY></SAMI>"
        let parsed = try Subtitle.parse(content, options: .init(format: .smi))
        #expect(!parsed.cues.isEmpty)
    }
}
