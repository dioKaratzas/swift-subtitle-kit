# ``SubtitleKit``

A Swift-native library for parsing, converting, resyncing, and saving subtitle files across nine formats.

## Overview

`SubtitleKit` normalizes every supported subtitle format into a unified ``SubtitleDocument`` model.
Use the ``Subtitle`` struct as the main entry point for all operations:

```swift
import SubtitleKit

// Parse with auto-detection
let subtitle = try Subtitle.parse(rawText)

// Access cues
for cue in subtitle.cues {
    print("\(cue.startTime)–\(cue.endTime): \(cue.plainText)")
}

// Convert to another format
let vtt = try subtitle.text(format: .vtt, lineEnding: .lf)

// Resync and save
let shifted = subtitle.resync(.init(offset: 2_000))
try shifted.save(to: outputURL)
```

### Supported Formats

| Format | Extension | Description |
| --- | --- | --- |
| SubRip | `.srt` | The most common text subtitle format |
| WebVTT | `.vtt` | Web-standard captioning format |
| SubViewer | `.sbv` | YouTube caption format |
| MicroDVD | `.sub` | Frame-based subtitle format |
| SSA | `.ssa` | Sub Station Alpha v4 |
| ASS | `.ass` | Advanced Sub Station Alpha v4+ |
| LRC | `.lrc` | Synchronized lyrics format |
| SAMI | `.smi` | Microsoft Synchronized Accessible Media |
| JSON | `.json` | Generic JSON caption interchange |

Custom formats can be added by conforming to ``SubtitleFormat`` and registering
with ``SubtitleFormatRegistry``.

### Concurrency

All model types (`Subtitle`, `SubtitleDocument`, `SubtitleCue`, etc.) are value types
conforming to `Sendable`. The global ``SubtitleFormatRegistry/current`` registry is
thread-safe. Format parsers and serializers are stateless.

## Topics

### Core API

- ``Subtitle``
- ``SubtitleDocument``
- ``SubtitleEntry``
- ``SubtitleCue``
- ``SubtitleMetadata``
- ``SubtitleStyle``
- ``SubtitleAttribute``

### Format System

- ``SubtitleFormat``
- ``SubtitleFormatRegistry``

### Built-in Formats

- ``SRTFormat``
- ``VTTFormat``
- ``SBVFormat``
- ``SUBFormat``
- ``SSAFormat``
- ``ASSFormat``
- ``LRCFormat``
- ``SMIFormat``
- ``JSONFormat``

### Options and Errors

- ``SubtitleParseOptions``
- ``SubtitleSerializeOptions``
- ``SubtitleResyncOptions``
- ``LineEnding``
- ``SubtitleError``

### Articles

- <doc:ParsingAndConversion>
- <doc:CustomFormats>
