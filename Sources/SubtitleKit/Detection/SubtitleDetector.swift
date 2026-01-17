import Foundation

enum SubtitleDetector {
    static func detectFormat(
        content: String,
        registry: SubtitleRegistry,
        fileName: String? = nil,
        fileExtension: String? = nil
    ) -> SubtitleFormat? {
        let sanitized = SubtitleNormalizer.stripByteOrderMark(content)

        if let fileExtension,
           let format = SubtitleFormat.from(fileExtension: fileExtension),
           registry.adapter(for: format) != nil {
            return format
        }

        if let fileName,
           let format = SubtitleFormat.from(fileName: fileName),
           registry.adapter(for: format) != nil {
            return format
        }

        return registry.detect(content: sanitized)
    }
}
