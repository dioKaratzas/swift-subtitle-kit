# SubtitleKit

`SubtitleKit` is a Swift 6 subtitle library for parsing, converting, resyncing, and saving subtitle files.

It is inspired by `subsrt-ts`, but exposes an object-first Swift API centered on `Subtitle`.

## Why SubtitleKit

- One public entry point: `Subtitle`
- Auto-detect input format from content or file extension
- Convert across common subtitle formats
- Strong typed domain model (`Sendable`, `Hashable`, `Identifiable`)
- Swift Testing fixture coverage and performance sanity checks

## Supported Formats

| Format | Extension | Parse | Serialize | Detect |
|---|---|---|---|---|
| SubRip | `.srt` | Yes | Yes | Yes |
| WebVTT | `.vtt` | Yes | Yes | Yes |
| SubViewer | `.sbv` | Yes | Yes | Yes |
| MicroDVD | `.sub` | Yes | Yes | Yes |
| SSA | `.ssa` | Yes | Yes | Yes |
| ASS | `.ass` | Yes | Yes | Yes |
| LRC | `.lrc` | Yes | Yes | Yes |
| SAMI | `.smi` | Yes | Yes | Yes |

## Installation

```swift
.package(url: "https://github.com/your-org/subtitlekit.git", from: "1.0.0")
```

Add `SubtitleKit` to your target dependencies.

## Quick Start

### Parse text (auto-detect)

```swift
import SubtitleKit

let subtitle = try Subtitle.parse(rawSubtitleText)
```

### Parse text (explicit format)

```swift
let subtitle = try Subtitle.parse(
  rawSubtitleText,
  options: .init(format: .srt)
)
```

### Load from file

```swift
let subtitle = try Subtitle.load(from: inputURL) // auto-detect
```

### Convert format

```swift
let vttText = try subtitle.convertedText(to: .vtt, lineEnding: .lf)
let vttSubtitle = try subtitle.convert(to: .vtt, lineEnding: .lf)
```

### Resync timings

```swift
let shifted = subtitle.resync(.init(offset: 3000))

let custom = subtitle.resync { start, end, frame in
  (start, end + 500, frame)
}
```

### Save to file

```swift
try subtitle.save(to: outputURL, format: .srt)
```

## Common File Workflow

```swift
import SubtitleKit

let input = URL(fileURLWithPath: "input.srt")
let output = URL(fileURLWithPath: "output.vtt")

let subtitle = try Subtitle.load(from: input)
let normalized = subtitle.resync(.init(offset: 750))
try normalized.save(to: output, format: .vtt)
```

## API Overview

Main public types:
- `Subtitle`
- `SubtitleFormat`
- `SubtitleDocument`
- `SubtitleEntry`
- `SubtitleCue`
- `SubtitleMetadata`
- `SubtitleStyle`
- `SubtitleAttribute`
- `SubtitleParseOptions`
- `SubtitleResyncOptions`
- `LineEnding`
- `SubtitleError`

Static helpers:
- `Subtitle.supportedFormats()`
- `Subtitle.detectFormat(in:fileName:fileExtension:)`

## Thread Safety

- Public model types are value types and `Sendable`.
- Domain models are `Hashable`.
- Entry-like entities conform to `Identifiable`.
- Internal parsing/serialization engine is stateless.

## Error Model

`SubtitleError` covers:
- unsupported format
- unable to detect format
- malformed blocks
- invalid timestamps
- unsupported variants
- invalid frame rates

## Testing

The test suite uses Swift Testing and includes:
- real fixtures per format
- round-trip checks per format
- cross-format conversion checks
- edge-case coverage (BOM, CRLF/LF, malformed timestamps, metadata quirks)
- large-file performance sanity test

Run tests:

```bash
swift test
```

## Known Limitations

- Converting between very different formats preserves cue timing/text, but some format-specific styling/metadata can be simplified.
- ASS/SSA event/style richness is best preserved when staying within ASS/SSA.
- SAMI HTML/class semantics are normalized when converting to non-SAMI formats.
