# Parsing and Conversion

Parse from text or file, then convert or save using the same ``Subtitle`` value.

## Parse

```swift
import SubtitleKit

let subtitle = try Subtitle.parse(rawText)
let explicit = try Subtitle.parse(rawText, format: .srt)
let loaded = try Subtitle.load(from: fileURL)
```

Format detection prefers extension hints before content sniffing:

1. explicit ``SubtitleParseOptions/format``
2. `fileExtension`
3. `fileName` extension
4. content-based `canParse` checks in registry order

## Convert

```swift
let asVTT = try subtitle.convertedText(to: .vtt, lineEnding: .lf)
let asObject = try subtitle.convert(to: .vtt, lineEnding: .lf)

let converted = try Subtitle.convert(
    rawText,
    from: .srt,
    to: .vtt,
    lineEnding: .lf
)
```

## Resync

```swift
let shifted = subtitle.resync(.init(offset: 2_000))

let custom = subtitle.resync { start, end, frame in
    (start + 100, end + 300, frame)
}
```

## Save

```swift
try subtitle.save(to: outputURL)
try subtitle.save(to: outputURL, format: .srt, lineEnding: .crlf)
```

When no format is supplied to `save`, SubtitleKit tries to infer one from the destination extension.
