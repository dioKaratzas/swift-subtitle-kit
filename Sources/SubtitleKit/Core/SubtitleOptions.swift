import Foundation

public struct SubtitleParseOptions: Sendable, Hashable {
    public var format: SubtitleFormat?
    public var fileExtension: String?
    public var preserveWhitespaceCaptions: Bool
    public var fps: Double?

    public init(
        format: SubtitleFormat? = nil,
        fileExtension: String? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil
    ) {
        self.format = format
        self.fileExtension = fileExtension
        self.preserveWhitespaceCaptions = preserveWhitespaceCaptions
        self.fps = fps
    }
}

public struct SubtitleSerializeOptions: Sendable, Hashable {
    public var format: SubtitleFormat
    public var lineEnding: LineEnding
    public var fps: Double?
    public var samiTitle: String?
    public var samiLanguageName: String
    public var samiLanguageCode: String
    public var closeSMITags: Bool

    public init(
        format: SubtitleFormat,
        lineEnding: LineEnding = .crlf,
        fps: Double? = nil,
        samiTitle: String? = nil,
        samiLanguageName: String = "English",
        samiLanguageCode: String = "en-US",
        closeSMITags: Bool = false
    ) {
        self.format = format
        self.lineEnding = lineEnding
        self.fps = fps
        self.samiTitle = samiTitle
        self.samiLanguageName = samiLanguageName
        self.samiLanguageCode = samiLanguageCode
        self.closeSMITags = closeSMITags
    }
}

public enum LineEnding: String, Sendable, Hashable, Codable {
    case lf = "\n"
    case crlf = "\r\n"

    public var value: String {
        rawValue
    }
}
