# Custom Formats

Extend SubtitleKit with new subtitle formats by conforming to ``SubtitleFormat``
and registering with ``SubtitleFormatRegistry``.

## Define a Format

Create a struct conforming to ``SubtitleFormat``. You must implement `name`,
`canParse(_:)`, `parse(_:options:)`, and `serialize(_:options:)`:

```swift
import SubtitleKit

public struct LineFormat: SubtitleFormat {
    public let name = "line"
    public let aliases = ["line", "lines"]

    public init() {}

    public func canParse(_ content: String) -> Bool {
        content.split(whereSeparator: \.isNewline).contains { line in
            let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
            return parts.count == 3 && Int(parts[0]) != nil && Int(parts[1]) != nil
        }
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument {
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

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        let body = document.cues.map { "\($0.startTime)|\($0.endTime)|\($0.rawText)" }
        return body.joined(separator: options.lineEnding.value)
            + (body.isEmpty ? "" : options.lineEnding.value)
    }
}
```

## Add Convenience Access

Provide a static property so callers can use `.line` syntax:

```swift
public extension SubtitleFormat where Self == LineFormat {
    static var line: SubtitleFormat { LineFormat() }
}
```

## Register and Use

```swift
// Register globally
SubtitleFormatRegistry.register(.line)

// Now auto-detection, parsing, and conversion all work
let parsed = try Subtitle.parse(customText, format: .line)
let srt = try parsed.text(format: .srt)
```

## Thread Safety

``SubtitleFormatRegistry/current`` is process-wide mutable state protected by
an internal lock. Registration is atomic, but format implementations must also
be `Sendable` and safe to call from any thread.

In tests, call ``SubtitleFormatRegistry/resetCurrent()`` in a `defer` block
to avoid cross-test leakage:

```swift
SubtitleFormatRegistry.resetCurrent()
defer { SubtitleFormatRegistry.resetCurrent() }

SubtitleFormatRegistry.register(.line)
// ... test code ...
```
