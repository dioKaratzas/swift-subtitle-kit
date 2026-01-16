import Foundation

public struct SubtitleParseOptions: Sendable, Hashable {
    public var format: SubtitleFormat?
    public var fileName: String?
    public var fileExtension: String?
    public var preserveWhitespaceCaptions: Bool
    public var fps: Double?

    public init(
        format: SubtitleFormat? = nil,
        fileName: String? = nil,
        fileExtension: String? = nil,
        preserveWhitespaceCaptions: Bool = false,
        fps: Double? = nil
    ) {
        self.format = format
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.preserveWhitespaceCaptions = preserveWhitespaceCaptions
        self.fps = fps
    }
}

struct SubtitleSerializeOptions: Sendable, Hashable {
    var format: SubtitleFormat
    var lineEnding: LineEnding
    var fps: Double?
    var samiTitle: String?
    var samiLanguageName: String
    var samiLanguageCode: String
    var closeSMITags: Bool

    init(
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

public struct SubtitleResyncOptions: Sendable, Hashable {
    public var offset: Int
    public var ratio: Double
    public var useFrameValues: Bool

    public init(offset: Int = 0, ratio: Double = 1.0, useFrameValues: Bool = false) {
        self.offset = offset
        self.ratio = ratio
        self.useFrameValues = useFrameValues
    }
}

public enum LineEnding: String, Sendable, Hashable, Codable {
    case lf = "\n"
    case crlf = "\r\n"

    public var value: String {
        rawValue
    }
}
