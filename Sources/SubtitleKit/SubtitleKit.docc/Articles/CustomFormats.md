# Custom Formats

Extend SubtitleKit by implementing ``SubtitleFormat`` and registering it in ``SubtitleFormatRegistry``.

## Define a format

```swift
import SubtitleKit

public struct LineFormat: SubtitleFormat {
    public let name = "line"
    public let aliases = ["line", "lines"]

    public init() {}

    public func canParse(_ content: String) -> Bool {
        content.contains("|")
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws -> SubtitleDocument {
        var entries: [SubtitleEntry] = []

        for (index, line) in content.split(whereSeparator: \.isNewline).enumerated() {
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

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let lines = document.cues.map { "\($0.startTime)|\($0.endTime)|\($0.rawText)" }
        return lines.joined(separator: options.lineEnding.value)
    }
}
```

## Add convenience access

```swift
public extension SubtitleFormat where Self == LineFormat {
    static var line: SubtitleFormat { LineFormat() }
}
```

## Register and use

```swift
SubtitleFormatRegistry.register(.line)

let parsed = try Subtitle.parse(customText, format: .line)
let asSRT = try parsed.convertedText(to: .srt)
```

`SubtitleFormatRegistry.current` is process-wide global state. In tests, call ``SubtitleFormatRegistry/resetCurrent()`` between cases to avoid leakage.
