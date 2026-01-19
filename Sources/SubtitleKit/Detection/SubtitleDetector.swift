import Foundation

enum SubtitleDetector {
    static func detectFormat(
        content: String,
        registry: SubtitleFormatRegistry,
        fileName: String? = nil,
        fileExtension: String? = nil
    ) -> SubtitleFormat? {
        let sanitized = SubtitleNormalizer.stripByteOrderMark(content)

        if let fileExtension,
           let format = registry.resolve(fileExtension: fileExtension) {
            return format
        }

        if let fileName,
           let format = registry.resolve(fileName: fileName) {
            return format
        }

        return registry.detectFormat(content: sanitized)
    }
}
