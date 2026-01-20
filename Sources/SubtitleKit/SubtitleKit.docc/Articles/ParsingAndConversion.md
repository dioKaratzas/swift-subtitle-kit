# Parsing and Conversion

Parse subtitle text or files, then convert, resync, or save using the same ``Subtitle`` value.

## Parse

```swift
import SubtitleKit

// Auto-detect format from content
let subtitle = try Subtitle.parse(rawText)

// Provide an explicit format
let srt = try Subtitle.parse(rawText, format: .srt)

// Use detection hints
let hinted = try Subtitle.parse(rawText, fileName: "track.vtt")

// Load directly from disk (extension-based detection)
let loaded = try Subtitle.load(from: fileURL)
```

Format detection follows this priority:

1. Explicit ``SubtitleParseOptions/format``
2. ``SubtitleParseOptions/fileExtension``
3. Extension extracted from ``SubtitleParseOptions/fileName``
4. Content-based `canParse` checks in registry order

## Access Cue Data

```swift
let subtitle = try Subtitle.parse(rawText)

for cue in subtitle.cues {
    print("[\(cue.startTime)ms–\(cue.endTime)ms] \(cue.plainText)")
}

// Full entry list includes metadata and styles
for entry in subtitle.entries {
    switch entry {
    case .cue(let cue):     print(cue.plainText)
    case .metadata(let m):  print("\(m.key)")
    case .style(let s):     print(s.name)
    }
}
```

## Convert

```swift
// Get converted text
let vttText = try subtitle.text(format: .vtt, lineEnding: .lf)

// Get a re-parsed Subtitle object in the target format
let vttObject = try subtitle.convert(to: .vtt, lineEnding: .lf)

// One-shot static conversion
let output = try Subtitle.convert(rawText, from: .srt, to: .vtt, lineEnding: .lf)
```

## SAMI-Specific Options

When serializing to SAMI, use ``SubtitleSerializeOptions`` to set
format-specific fields:

```swift
let options = SubtitleSerializeOptions(
    format: .smi,
    lineEnding: .crlf,
    sami: .init(title: "My Subtitles", languageName: "English", closeTags: true)
)
let smiText = try subtitle.text(using: options)
try subtitle.save(to: outputURL, using: options)
```

## Resync

```swift
// Shift all cues forward by 2 seconds
let shifted = subtitle.resync(.init(offset: 2_000))

// Apply a ratio (speed change)
let scaled = subtitle.resync(.init(ratio: 1.05))

// Custom transform
let custom = subtitle.resync { start, end, frame in
    (start + 100, end + 300, frame)
}

// Mutating variant
var mutable = subtitle
mutable.applyResync(.init(offset: -500))
```

## Save

```swift
// Infers format from the destination file extension
try subtitle.save(to: outputURL)

// Explicit format and options
try subtitle.save(to: outputURL, format: .srt, lineEnding: .crlf)
```

## Frame-Based Formats

MicroDVD (`.sub`) uses frame numbers instead of timestamps. Supply a frame rate:

```swift
let sub = try Subtitle.parse(content, format: .sub, fps: 23.976)

// When serializing back, provide fps to compute frames from milliseconds
try sub.save(to: outputURL, format: .sub, fps: 23.976)
```

If no `fps` is provided, a default of 25 is used.
