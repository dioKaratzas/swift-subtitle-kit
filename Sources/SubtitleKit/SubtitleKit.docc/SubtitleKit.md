# ``SubtitleKit``

`SubtitleKit` provides a Swift-native API for subtitle parsing, conversion, resync, and serialization.

## Overview

Use ``Subtitle`` as the main entry point.

```swift
import SubtitleKit

let subtitle = try Subtitle.parse(rawText)
let vtt = try subtitle.convertedText(to: .vtt, lineEnding: .lf)
```

`SubtitleKit` normalizes parsed data into ``SubtitleDocument`` and exposes:

- ``SubtitleEntry``
- ``SubtitleCue``
- ``SubtitleMetadata``
- ``SubtitleStyle``

Formats conform to ``SubtitleFormat`` and are managed by ``SubtitleFormatRegistry``.

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

### Options and Errors

- ``SubtitleParseOptions``
- ``SubtitleSerializeOptions``
- ``SubtitleResyncOptions``
- ``LineEnding``
- ``SubtitleError``

### Articles

- <doc:ParsingAndConversion>
- <doc:CustomFormats>
