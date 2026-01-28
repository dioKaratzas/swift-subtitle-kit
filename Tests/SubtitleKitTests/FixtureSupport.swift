import Foundation
@testable import SubtitleKit

enum FixtureSupport {
    static let fixtureFormatNames = [
        "srt",
        "vtt",
        "sbv",
        "sub",
        "ass",
        "ssa",
        "lrc",
        "smi",
        "json",
    ]

    static func fixtureText(_ fileName: String, ext: String) throws(any Error) -> String {
        guard let baseURL = Bundle.module.resourceURL else {
            throw FixtureError.resourceBundleMissing
        }
        let url = baseURL
            .appendingPathComponent("Fixtures", isDirectory: true)
            .appendingPathComponent("\(fileName).\(ext)")

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FixtureError.fixtureMissing(url.path)
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    static func sampleText(for formatName: String) throws(any Error) -> String {
        try fixtureText("sample", ext: formatName)
    }

    static func format(named name: String) -> SubtitleFormat {
        switch name.lowercased() {
        case "srt":
            return .srt
        case "vtt":
            return .vtt
        case "sbv":
            return .sbv
        case "sub":
            return .sub
        case "ass":
            return .ass
        case "ssa":
            return .ssa
        case "lrc":
            return .lrc
        case "smi":
            return .smi
        case "json":
            return .json
        default:
            preconditionFailure("Unsupported fixture format: \(name)")
        }
    }

    static func generatedSRT(cueCount: Int) -> String {
        var chunks: [String] = []
        chunks.reserveCapacity(cueCount)

        for index in 0..<cueCount {
            let number = index + 1
            let start = index * 1500
            let end = start + 1200
            chunks.append(
                "\(number)\n\(toSRTTime(start)) --> \(toSRTTime(end))\nLine \(number)\n"
            )
        }
        return chunks.joined(separator: "\n")
    }

    private static func toSRTTime(_ milliseconds: Int) -> String {
        let total = max(0, milliseconds)
        let hours = total / 3_600_000
        let minutes = (total / 60_000) % 60
        let seconds = (total / 1_000) % 60
        let ms = total % 1_000
        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, ms)
    }

    enum FixtureError: Error {
        case resourceBundleMissing
        case fixtureMissing(String)
    }
}
