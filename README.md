# SubtitleKit

[![Test](https://github.com/dioKaratzas/swift-subtitle-kit/actions/workflows/test.yml/badge.svg)](https://github.com/dioKaratzas/swift-subtitle-kit/actions/workflows/test.yml)
[![Latest Release](https://img.shields.io/github/v/release/dioKaratzas/swift-subtitle-kit?display_name=tag)](https://github.com/dioKaratzas/swift-subtitle-kit/releases)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2013%2B%20%7C%20macOS%2010.15%2B%20%7C%20tvOS%2013%2B%20%7C%20watchOS%206%2B-blue)](https://github.com/dioKaratzas/swift-subtitle-kit/blob/main/Package.swift)
[![Swift](https://img.shields.io/badge/swift-6.0-orange)](https://www.swift.org)

A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.

SubtitleKit normalizes every supported format into a single `SubtitleDocument` model, letting you parse once and convert to any output format from the same object.

## Highlights

- **Object-first API** -- parse into a `Subtitle` value, then convert, resync, inspect, or save from that same value.
- **9 built-in formats** with a unified timing/text model (`SubtitleDocument`).
- **Auto-detection** by file extension, filename, and content sniffing.
- **Round-trip fidelity** -- metadata, styles, and cue attributes survive parse/serialize cycles within the same format.
- **Extensible** -- add new formats by conforming to `SubtitleFormat` and registering at runtime.
- **Concurrency-ready** -- all model types are value types and `Sendable`. The global registry is thread-safe.
- **Zero dependencies** -- only Foundation.

## Supported Formats

| Format | Extension | Type | Notes |
| --- | --- | --- | --- |
| SubRip | `.srt` | Time-based | Most widely used subtitle format |
| WebVTT | `.vtt` | Time-based | W3C web standard; supports cue IDs, settings, and metadata blocks |
| SubViewer | `.sbv` | Time-based | YouTube caption format |
| MicroDVD | `.sub` | Frame-based | Requires a frame rate (`fps`) to convert to/from time-based formats |
| Sub Station Alpha | `.ssa` | Time-based | SSA v4; preserves styles and script info metadata |
| Advanced SSA | `.ass` | Time-based | ASS v4+; superset of SSA with richer styling |
| LRC | `.lrc` | Time-based | Synchronized lyrics; end times are inferred from the next cue |
| SAMI | `.smi` | Time-based | Microsoft format; HTML-based cue content |
| JSON | `.json` | Time-based | Generic array-of-objects interchange format |
| Custom | any | any | User-defined via `SubtitleFormat` protocol |

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dioKaratzas/swift-subtitle-kit.git", from: "1.0.0")
]
```

Then add the library product to your target dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "SubtitleKit", package: "swift-subtitle-kit")
    ]
)
```

**Requirements:** Swift tools-version 6.0, iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+.

## Documentation

- API Docs: https://diokaratzas.github.io/swift-subtitle-kit/documentation/subtitlekit/

## Quick Start

### Parse with Auto-Detection

```swift
import SubtitleKit

let subtitle = try Subtitle.parse(rawSRTText)
print(subtitle.formatName)   // "srt"
print(subtitle.cues.count)   // number of timed cues
```

### Parse with Explicit Format

```swift
let subtitle = try Subtitle.parse(rawText, format: .vtt)
```

### Parse with Detection Hints

```swift
let subtitle = try Subtitle.parse(rawText, fileName: "episode.srt")
// or
let subtitle = try Subtitle.parse(rawText, fileExtension: "vtt")
```

### Load from File

```swift
let subtitle = try Subtitle.load(from: fileURL)
// Extension of the URL is used for format detection
```

## Accessing Cue Data

```swift
let subtitle = try Subtitle.parse(content, format: .srt)

for cue in subtitle.cues {
    print("[\(cue.startTime)ms - \(cue.endTime)ms] \(cue.plainText)")
}

// SubtitleEntry includes cues, metadata, and styles
for entry in subtitle.entries {
    switch entry {
    case .cue(let cue):       print(cue.plainText)
    case .metadata(let meta): print("\(meta.key)")
    case .style(let style):   print(style.name)
    }
}
```

**`SubtitleCue` fields:**

| Property | Type | Description |
| --- | --- | --- |
| `id` | `Int` | Cue sequence number |
| `cueIdentifier` | `String?` | Optional format-specific ID (e.g., WebVTT cue IDs) |
| `startTime` | `Int` | Start time in milliseconds |
| `endTime` | `Int` | End time in milliseconds |
| `duration` | `Int` | Computed: `endTime - startTime` |
| `rawText` | `String` | Original cue text (may contain formatting tags) |
| `plainText` | `String` | Tag-stripped and normalized cue text |
| `frameRange` | `FrameRange?` | Frame numbers for frame-based formats (MicroDVD) |
| `attributes` | `[SubtitleAttribute]` | Format-specific key/value attributes |

## Converting Formats

### Get Converted Text

```swift
let vttText = try subtitle.text(format: .vtt, lineEnding: .lf)
```

### Get a Re-Parsed Subtitle Object

```swift
let vttSubtitle = try subtitle.convert(to: .vtt, lineEnding: .lf)
print(vttSubtitle.formatName) // "vtt"
```

### One-Shot Static Conversion

```swift
let output = try Subtitle.convert(
    rawSRTText,
    from: .srt,
    to: .vtt,
    lineEnding: .lf
)
```

### Serialize Back to Source Format

```swift
let text = try subtitle.text()  // uses source format and line ending
```

## Resyncing Timestamps

### Offset Shift

```swift
// Shift all cues forward by 2 seconds
let shifted = subtitle.resync(.init(offset: 2_000))
```

### Ratio Scaling

```swift
// Speed up by 5%
let faster = subtitle.resync(.init(ratio: 1.05))
```

### Combined

```swift
let adjusted = subtitle.resync(.init(offset: 500, ratio: 0.98))
```

### Custom Transform

```swift
let custom = subtitle.resync { start, end, frame in
    (start + 100, end + 300, frame)
}
```

### Mutating Variant

```swift
var mutable = subtitle
mutable.applyResync(.init(offset: -500))
```

## Saving to File

```swift
// Infer format from the destination file extension
try subtitle.save(to: outputURL)

// Explicit format and line ending
try subtitle.save(to: outputURL, format: .srt, lineEnding: .crlf)
```

## Format Detection

Detection follows a strict priority order:

1. **Explicit format** in `SubtitleParseOptions.format`
2. **File extension** argument (`fileExtension:`)
3. **Filename** extension extracted from `fileName:`
4. **Content sniffing** via registered `canParse` checks

Content sniffing order: VTT, LRC, SMI, ASS, SSA, SUB, SRT, SBV, JSON.

```swift
// Detect without parsing
let format = Subtitle.detectFormat(in: rawText)
let format = Subtitle.detectFormat(in: rawText, fileName: "track.srt")
```

## Custom Format Extension

### 1. Conform to `SubtitleFormat`

```swift
import SubtitleKit

struct PipeFormat: SubtitleFormat {
    let name = "pipe"
    let aliases = ["pipe", "pip"]

    func canParse(_ content: String) -> Bool {
        content.split(whereSeparator: \.isNewline).contains { line in
            line.split(separator: "|", maxSplits: 2).count == 3
        }
    }

    func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument {
        var entries: [SubtitleEntry] = []
        for (i, line) in content.split(whereSeparator: \.isNewline).enumerated() {
            let parts = line.split(separator: "|", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3,
                  let start = Int(parts[0]),
                  let end = Int(parts[1])
            else {
                throw SubtitleError.malformedBlock(format: name, details: String(line))
            }
            entries.append(.cue(.init(
                id: i + 1, startTime: start, endTime: end,
                rawText: String(parts[2]), plainText: String(parts[2])
            )))
        }
        return SubtitleDocument(formatName: name, entries: entries)
    }

    func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        let lines = document.cues.map { "\($0.startTime)|\($0.endTime)|\($0.rawText)" }
        return lines.joined(separator: options.lineEnding.value)
            + (lines.isEmpty ? "" : options.lineEnding.value)
    }
}
```

### 2. Add Static Accessor

```swift
extension SubtitleFormat where Self == PipeFormat {
    static var pipe: SubtitleFormat { PipeFormat() }
}
```

### 3. Register and Use

```swift
SubtitleFormatRegistry.register(.pipe)

let parsed = try Subtitle.parse("0|1000|Hello\n", format: .pipe)
let srt = try parsed.text(format: .srt)
```

## SAMI-Specific Options

Format-specific serialization options are grouped in `SubtitleSerializeOptions`
rather than polluting every method signature. For SAMI output:

```swift
let options = SubtitleSerializeOptions(
    format: .smi,
    lineEnding: .crlf,
    sami: .init(title: "My Subtitles", languageName: "English", closeTags: true)
)
let smiText = try subtitle.text(using: options)
try subtitle.save(to: outputURL, using: options)
```

## Concurrency and Thread Safety

- **Model types** (`Subtitle`, `SubtitleDocument`, `SubtitleCue`, `SubtitleEntry`, etc.) are all value types conforming to `Sendable`. They are safe to pass across actor/task boundaries.
- **Registry** -- `SubtitleFormatRegistry.current` is protected by an internal lock. The static `register(_:)` method is atomic.
- **Parsers and serializers** are stateless struct methods. As long as custom format implementations are also `Sendable`, concurrent parsing across different tasks is safe.
- In tests, call `SubtitleFormatRegistry.resetCurrent()` in a `defer` block to prevent cross-test leakage.

## Error Handling

All errors are typed as `SubtitleError`, which conforms to `LocalizedError`:

| Case | Meaning |
| --- | --- |
| `unsupportedFormat(String)` | Named format not registered |
| `unableToDetectFormat` | No format matched by hints or content |
| `malformedBlock(format:details:)` | Structural parse error in a format block |
| `invalidTimestamp(format:value:)` | Unparseable timestamp string |
| `unsupportedVariant(format:details:)` | Recognized but unsupported format variant |
| `invalidFrameRate(Double)` | Non-positive or invalid FPS value |

```swift
do {
    let subtitle = try Subtitle.parse(brokenText)
} catch let error as SubtitleError {
    print(error.errorDescription ?? "Unknown subtitle error")
}
```

## API Reference

### Main Types

| Type | Role |
| --- | --- |
| `Subtitle` | Primary entry point: parse, convert, resync, save |
| `SubtitleDocument` | Unified document model (entries array + format name) |
| `SubtitleEntry` | Enum: `.cue`, `.metadata`, `.style` |
| `SubtitleCue` | Timed cue with text, timestamps, and attributes |
| `SubtitleMetadata` | Key/value metadata from format headers |
| `SubtitleStyle` | Named style with key/value fields |
| `SubtitleAttribute` | Key/value pair used across cues, metadata, styles |

### Configuration Types

| Type | Role |
| --- | --- |
| `SubtitleParseOptions` | Format hints, FPS, whitespace preservation |
| `SubtitleSerializeOptions` | Target format, line ending, FPS, SAMI-specific options |
| `SubtitleResyncOptions` | Offset, ratio, frame-value mode |
| `LineEnding` | `.lf` or `.crlf` |

### Format System

| Type | Role |
| --- | --- |
| `SubtitleFormat` | Protocol for format adapters |
| `SubtitleFormatRegistry` | Registration, resolution, and detection |
| `SRTFormat`, `VTTFormat`, ... | Built-in format implementations |

## Limitations and Edge Cases

- **Cross-family conversion** normalizes style/metadata to the lowest common denominator. ASS/SSA styles are best preserved when staying in the ASS/SSA family.
- **SAMI** HTML semantics (classes, nested tags) are simplified to plain text when converting to non-SAMI formats.
- **MicroDVD** (`.sub`) stores frame numbers; converting to/from time-based formats requires an accurate `fps` value. The default is 25 fps.
- **LRC** has no explicit end times; SubtitleKit infers end times from the start of the next cue (final cue gets a 2-second default duration).
- **JSON format** uses `JSONSerialization` for broad compatibility; the schema follows the subsrt-ts convention (array of objects with `type`, `start`, `end`, `content`, `text` fields).
- **BOM handling** -- UTF-8 byte order marks are stripped during normalization. The `sourceHadByteOrderMark` property records whether one was present.
- **Line endings** -- source line endings (LF vs CRLF) are detected and preserved by default. Override with the `lineEnding:` parameter on any serialization method.
