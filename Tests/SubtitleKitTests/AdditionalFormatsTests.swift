import Testing
@testable import SubtitleKit

@Suite("Additional Format Adapters")
struct AdditionalFormatsTests {
    let kit = SubtitleKit()

    @Test("Parses and serializes SSA")
    func parseSerializeSSA() throws {
        let content = "[Script Info]\nScriptType: v4.00\n\n[V4 Styles]\nFormat: Name, Fontname, Fontsize\nStyle: Default,Arial,20\n\n[Events]\nFormat: Marked, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\nDialogue: Marked=0,0:00:01.00,0:00:02.50,Default,NTP,0000,0000,0000,,Hello\\NWorld\n"
        let parsed = try kit.parse(content, options: .init(format: .ssa))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].plainText == "Hello\nWorld")

        let serialized = try kit.serialize(parsed, options: .init(format: .ssa, lineEnding: .lf))
        #expect(serialized.contains("[Events]"))
    }

    @Test("Parses and serializes ASS")
    func parseSerializeASS() throws {
        let content = "[Script Info]\nScriptType: v4.00+\n\n[V4+ Styles]\nFormat: Name, Fontname, Fontsize\nStyle: Default,Arial,20\n\n[Events]\nFormat: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text\nDialogue: 0,0:00:01.00,0:00:02.00,Default,NTP,0000,0000,0000,,{\\pos(1,1)}Hi\n"
        let parsed = try kit.parse(content, options: .init(format: .ass))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].plainText == "Hi")

        let serialized = try kit.serialize(parsed, options: .init(format: .ass, lineEnding: .lf))
        #expect(serialized.contains("[V4+ Styles]"))
    }

    @Test("Parses and serializes SUB")
    func parseSerializeSUB() throws {
        let content = "{25}{50}Line 1|Line 2\n"
        let parsed = try kit.parse(content, options: .init(format: .sub, fps: 25))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].frameRange?.start == 25)

        let serialized = try kit.serialize(parsed, options: .init(format: .sub, lineEnding: .lf, fps: 25))
        #expect(serialized.contains("{25}{50}"))
    }

    @Test("Parses and serializes LRC")
    func parseSerializeLRC() throws {
        let content = "[ar:Artist]\n\n[00:01.00]Hello\n[00:03.00]World\n"
        let parsed = try kit.parse(content, options: .init(format: .lrc))
        #expect(parsed.cues.count == 2)
        #expect(parsed.cues[0].endTime == parsed.cues[1].startTime)

        let serialized = try kit.serialize(parsed, options: .init(format: .lrc, lineEnding: .lf))
        #expect(serialized.contains("[ar:Artist]"))
    }

    @Test("Parses and serializes SMI")
    func parseSerializeSMI() throws {
        let content = "<SAMI><BODY><SYNC Start=1000><P Class=LANG>Hello<BR>World<SYNC Start=2000><P Class=LANG>&nbsp;</BODY></SAMI>"
        let parsed = try kit.parse(content, options: .init(format: .smi))
        #expect(parsed.cues.count == 1)
        #expect(parsed.cues[0].plainText == "Hello\nWorld")

        let serialized = try kit.serialize(parsed, options: .init(format: .smi, lineEnding: .lf, closeSMITags: true))
        #expect(serialized.contains("<SYNC Start=1000>"))
    }
}
