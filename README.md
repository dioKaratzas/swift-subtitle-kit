# SubtitleKit

`SubtitleKit` is a Swift 6 package for parsing, normalizing, converting, resyncing, and saving subtitle files.

It ports the `subsrt-ts` behavior into a production-oriented Swift API centered on a single `Subtitle` value.

## Highlights

- Object-first API: parse into `Subtitle`, then convert/resync/save from the same object
- Multi-format support with a unified `SubtitleDocument` model
- Auto-detection by file extension, filename, and content sniffing
- Round-trip focused parsing/serialization for timing/order/text fidelity
- Extensible format system via `SubtitleFormat` protocol + registry
- `Sendable` domain model types for strict-concurrency codebases

## Supported Formats

| Format | Extensions | Parse | Serialize | Detect |
| --- | --- | --- | --- | --- |
| SubRip | `.srt` | Yes | Yes | Yes |
| WebVTT | `.vtt` | Yes | Yes | Yes |
| SubViewer | `.sbv` | Yes | Yes | Yes |
| MicroDVD | `.sub` | Yes | Yes | Yes |
| SSA | `.ssa` | Yes | Yes | Yes |
| ASS | `.ass` | Yes | Yes | Yes |
| LRC | `.lrc` | Yes | Yes | Yes |
| SAMI | `.smi` | Yes | Yes | Yes |
| JSON compatibility format | `.json` | Yes | Yes | Yes |
| Custom (user-defined) | any | Yes | Yes | Yes |

## Installation

```swift
// Package.swift
.package(url: "https://github.com/your-org/subtitlekit.git", from: "1.0.0")
```

Then add `SubtitleKit` to your target dependencies.

## Quick Start

### Parse with auto-detection

```swift
import SubtitleKit

let subtitle = try Subtitle.parse(rawText)
```

### Parse with explicit format

```swift
let subtitle = try Subtitle.parse(rawText, format: .srt)
```

### Load from file

```swift
let subtitle = try Subtitle.load(from: inputURL)
```

### Convert formats

```swift
let asVTTText = try subtitle.convertedText(to: .vtt, lineEnding: .lf)
let asVTT = try subtitle.convert(to: .vtt, lineEnding: .lf)
```

### Resync timestamps

```swift
let shifted = subtitle.resync(.init(offset: 1_500))

let transformed = subtitle.resync { start, end, frame in
    (start + 100, end + 350, frame)
}
```

### Save to file

```swift
try subtitle.save(to: outputURL)             // infers from file extension when possible
try subtitle.save(to: outputURL, format: .srt)
```

## API Surface

Main types:

- `Subtitle`
- `SubtitleDocument`
- `SubtitleEntry`
- `SubtitleCue`
- `SubtitleMetadata`
- `SubtitleStyle`
- `SubtitleAttribute`
- `SubtitleFormat` (protocol)
- `SubtitleFormatRegistry`
- `SubtitleParseOptions`
- `SubtitleSerializeOptions`
- `SubtitleResyncOptions`
- `LineEnding`
- `SubtitleError`

Useful static helpers:

- `Subtitle.supportedFormats()`
- `Subtitle.supportedFormatNames()`
- `Subtitle.detectFormat(in:fileName:fileExtension:)`
- `SubtitleFormatRegistry.register(_:)`
- `SubtitleFormatRegistry.resetCurrent()`

## Detection Rules

Detection order is:

1. Explicit format in options (if provided)
2. File extension argument (if provided)
3. Filename extension (if provided)
4. Content sniffing via registered format detectors

## Custom Format Extension

Create a concrete formatter that conforms to `SubtitleFormat`, then register it:

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
        let entries = content
            .split(whereSeparator: \.isNewline)
            .enumerated()
            .map { index, line -> SubtitleEntry in
                let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
                let start = Int(parts[safe: 0] ?? "") ?? 0
                let end = Int(parts[safe: 1] ?? "") ?? 0
                let text = String(parts[safe: 2] ?? "")
                return .cue(.init(id: index + 1, startTime: start, endTime: end, rawText: text, plainText: text))
            }

        return SubtitleDocument(formatName: name, entries: entries)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws -> String {
        let body = document.cues.map { "\($0.startTime)|\($0.endTime)|\($0.rawText)" }
        return body.joined(separator: options.lineEnding.value)
    }
}

public extension SubtitleFormat where Self == LineFormat {
    static var line: SubtitleFormat { LineFormat() }
}

SubtitleFormatRegistry.register(.line)

let parsed = try Subtitle.parse(customText, format: .line)
let asSRT = try parsed.convertedText(to: .srt)
```

Notes:

- `SubtitleFormatRegistry.current` is global state; call `SubtitleFormatRegistry.resetCurrent()` in tests.
- Custom format implementations must be `Sendable` and thread-safe.

## Error Model

`SubtitleError` includes:

- `unsupportedFormat`
- `unableToDetectFormat`
- `malformedBlock(format:details:)`
- `invalidTimestamp(format:value:)`
- `unsupportedVariant(format:details:)`
- `invalidFrameRate`

## Concurrency and Thread Safety

- Core models are value types and `Sendable`.
- Internal registry state is protected for concurrent access.
- Parsers/serializers are stateless; they work safely across tasks when custom formats are also thread-safe.

## Testing

The package uses **Swift Testing** (`import Testing`) and includes:

- Fixture-based parsing tests for every built-in format
- Round-trip serialization tests per format
- Cross-format conversion tests
- Edge-case coverage (BOM, CRLF/LF, malformed timestamps, empty metadata sections)
- Performance sanity test for large SRT payloads

Run all tests:

```bash
swift test
```

## Known Limitations

- Converting between very different subtitle families can normalize style/metadata details.
- ASS/SSA style/event richness is best preserved when staying in ASS/SSA.
- SAMI HTML/class semantics are simplified when converting to non-SAMI formats.
- MicroDVD (`.sub`) conversions without explicit `frameRange` rely on `fps` assumptions.
