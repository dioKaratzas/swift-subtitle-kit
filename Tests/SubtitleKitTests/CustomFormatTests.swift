import Testing
@testable import SubtitleKit

private struct LineFormat: SubtitleFormat {
    let name = "line"
    let aliases = ["line", "lines"]

    func canParse(_ content: String) -> Bool {
        content
            .split(whereSeparator: \.isNewline)
            .contains { line in
                let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
                return parts.count == 3 && Int(parts[0]) != nil && Int(parts[1]) != nil
            }
    }

    func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        let lines = content.split(whereSeparator: \.isNewline)
        var entries: [SubtitleEntry] = []

        for (index, line) in lines.enumerated() {
            let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3,
                  let start = Int(parts[0]),
                  let end = Int(parts[1])
            else {
                throw SubtitleError.malformedBlock(format: name, details: String(line))
            }

            let text = String(parts[2])
            entries.append(.cue(.init(
                id: index + 1,
                startTime: start,
                endTime: end,
                rawText: text,
                plainText: text
            )))
        }

        return SubtitleDocument(formatName: name, entries: entries)
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let body = document.cues.map { cue in
            "\(cue.startTime)|\(cue.endTime)|\(cue.rawText)"
        }
        return body.joined(separator: options.lineEnding.value) + (body.isEmpty ? "" : options.lineEnding.value)
    }
}

extension SubtitleFormat where Self == LineFormat {
    static var line: SubtitleFormat { LineFormat() }
}

@Suite("Custom format registry")
struct CustomFormatTests {
    @Test("Uses current registry with custom format")
    func customRegistryFlow() throws {
        SubtitleFormatRegistry.resetCurrent()
        defer { SubtitleFormatRegistry.resetCurrent() }

        SubtitleFormatRegistry.register(.line)

        #expect(Subtitle.supportedFormats().contains(where: { $0.isEqual(.line) }))

        let sample = "0|1000|Hello\n1000|2300|World\n"
        #expect(Subtitle.detectFormat(in: sample).isEqual(.line))
        #expect(Subtitle.detectFormat(in: "", fileName: "track.line").isEqual(.line))
        #expect(Subtitle.detectFormat(in: "", fileExtension: "lines").isEqual(.line))

        let parsed = try Subtitle.parse(sample, format: .line)
        #expect(parsed.format.isEqual(.line))
        #expect(parsed.cues.count == 2)

        let srt = try parsed.convertedText(to: .srt, lineEnding: .lf)
        #expect(srt.contains("00:00:00,000 --> 00:00:01,000"))

        let backToLine = try Subtitle.convert(
            srt,
            from: .srt,
            to: .line,
            lineEnding: .lf
        )
        #expect(backToLine.contains("0|1000|Hello"))
    }
}
