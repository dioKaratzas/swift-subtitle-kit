//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import Foundation

/// JSON compatibility subtitle adapter.
public struct JSONFormat: SubtitleFormat {
    public let name = "json"

    public func canParse(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first == "[" || trimmed.first == "{" else {
            return false
        }
        guard let data = trimmed.data(using: .utf8) else {
            return false
        }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    public func parse(_ content: String, options: SubtitleParseOptions) throws(SubtitleError) -> SubtitleDocument {
        let normalized = content
        guard let data = normalized.data(using: .utf8) else {
            throw SubtitleError.malformedBlock(format: "json", details: "Expected top-level JSON array")
        }
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw SubtitleError.malformedBlock(
                format: "json",
                details: "Invalid JSON input: \(error.localizedDescription)"
            )
        }
        guard let json = jsonObject as? [Any] else {
            throw SubtitleError.malformedBlock(format: "json", details: "Expected top-level JSON array")
        }

        var entries = [SubtitleEntry]()
        var fallbackID = 1

        for item in json {
            guard let object = item as? [String: Any] else {
                fallbackID += 1
                continue
            }

            let type = (object["type"] as? String)?.lowercased() ?? "caption"
            let identifier = toInt(object["index"]) ?? toInt(object["id"]) ?? fallbackID

            switch type {
            case "meta":
                let key = (object["name"] as? String)
                    ?? (object["tag"] as? String)
                    ?? (object["key"] as? String)
                    ?? "meta"
                if let dataString = object["data"] as? String {
                    entries.append(.metadata(.init(id: identifier, key: key, value: .text(dataString))))
                } else if let dict = object["data"] as? [String: Any] {
                    let fields = dict.keys.sorted().map { SubtitleAttribute(
                        key: $0,
                        value: String(describing: dict[$0] ?? "")
                    ) }
                    entries.append(.metadata(.init(id: identifier, key: key, value: .fields(fields))))
                } else {
                    entries.append(.metadata(.init(id: identifier, key: key, value: .text(""))))
                }

            case "style":
                let data = (object["data"] as? [String: Any]) ?? [:]
                let fields = data.keys.sorted().map { SubtitleAttribute(
                    key: $0,
                    value: String(describing: data[$0] ?? "")
                ) }
                let styleName = fields.first(where: { $0.key.caseInsensitiveCompare("name") == .orderedSame })?.value ?? "Style"
                entries.append(.style(.init(id: identifier, name: styleName, fields: fields)))

            default:
                let start = toInt(object["start"]) ?? 0
                let end = toInt(object["end"]) ?? start
                let rawText = (object["content"] as? String) ?? (object["text"] as? String) ?? ""
                let plainText = (object["text"] as? String) ?? rawText

                var attributes = [SubtitleAttribute]()
                if let dataDict = object["data"] as? [String: Any] {
                    attributes = dataDict.keys.sorted().map { SubtitleAttribute(
                        key: $0,
                        value: String(describing: dataDict[$0] ?? "")
                    ) }
                }

                var frameRange: SubtitleCue.FrameRange?
                if let frame = object["frame"] as? [String: Any],
                   let frameStart = toInt(frame["start"]),
                   let frameEnd = toInt(frame["end"]) {
                    frameRange = .init(start: frameStart, end: frameEnd)
                }

                let cue = SubtitleCue(
                    id: identifier,
                    cueIdentifier: object["cue"] as? String,
                    startTime: start,
                    endTime: end,
                    rawText: rawText,
                    plainText: plainText,
                    frameRange: frameRange,
                    attributes: attributes
                )
                entries.append(.cue(cue))
            }

            fallbackID += 1
        }

        return SubtitleDocument(formatName: "json", entries: entries)
    }

    public func serialize(_ document: SubtitleDocument, options: SubtitleSerializeOptions) throws(SubtitleError) -> String {
        var payload = [[String: Any]]()

        for entry in document.entries {
            switch entry {
            case let .cue(cue):
                var object: [String: Any] = [
                    "type": "caption",
                    "index": cue.id,
                    "start": cue.startTime,
                    "end": cue.endTime,
                    "duration": cue.duration,
                    "content": cue.rawText,
                    "text": cue.plainText,
                ]

                if let cueIdentifier = cue.cueIdentifier {
                    object["cue"] = cueIdentifier
                }
                if let frame = cue.frameRange {
                    object["frame"] = [
                        "start": frame.start,
                        "end": frame.end,
                        "count": frame.count,
                    ]
                }
                if !cue.attributes.isEmpty {
                    object["data"] = Dictionary(
                        cue.attributes.map { ($0.key, $0.value) },
                        uniquingKeysWith: { _, last in last }
                    )
                }
                payload.append(object)

            case let .metadata(metadata):
                var object: [String: Any] = [
                    "type": "meta",
                    "name": metadata.key,
                ]
                switch metadata.value {
                case let .text(text):
                    object["data"] = text
                case let .fields(fields):
                    object["data"] = Dictionary(fields.map { ($0.key, $0.value) }, uniquingKeysWith: { _, last in last })
                }
                payload.append(object)

            case let .style(style):
                let data = Dictionary(style.fields.map { ($0.key, $0.value) }, uniquingKeysWith: { _, last in last })
                payload.append([
                    "type": "style",
                    "data": data,
                ])
            }
        }

        let data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        } catch {
            throw SubtitleError.malformedBlock(
                format: "json",
                details: "Unable to encode JSON output: \(error.localizedDescription)"
            )
        }
        guard var output = String(data: data, encoding: .utf8) else {
            throw SubtitleError.malformedBlock(format: "json", details: "Unable to encode JSON output")
        }
        output += options.lineEnding.value
        return output
    }

    private func toInt(_ value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }
        if let double = value as? Double {
            return Int(double)
        }
        if let string = value as? String, let int = Int(string) {
            return int
        }
        return nil
    }
}
