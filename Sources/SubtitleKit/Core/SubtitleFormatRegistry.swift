import Foundation

private final class SubtitleFormatRegistryStore: @unchecked Sendable {
    static let shared = SubtitleFormatRegistryStore()

    private let lock = NSLock()
    private var registry: SubtitleFormatRegistry = .standard

    private init() {}

    func get() -> SubtitleFormatRegistry {
        lock.lock()
        defer { lock.unlock() }
        return registry
    }

    func set(_ value: SubtitleFormatRegistry) {
        lock.lock()
        registry = value
        lock.unlock()
    }
}

/// Registry of available subtitle formats used for resolution and content detection.
public struct SubtitleFormatRegistry: Sendable {
    private let formatsByName: [String: SubtitleFormat]
    private let detectionOrder: [SubtitleFormat]

    init(formats: [SubtitleFormat]) {
        var map: [String: SubtitleFormat] = [:]
        for format in formats {
            map[Self.normalize(format.name)] = format
            for alias in format.aliases {
                map[Self.normalize(alias)] = format
            }
        }
        self.formatsByName = map
        self.detectionOrder = formats
    }

    /// Default registry containing all built-in SubtitleKit formats.
    public static var standard: Self {
        .init(formats: [
            .vtt,
            .lrc,
            .smi,
            .ass,
            .ssa,
            .sub,
            .srt,
            .sbv,
            .json,
        ])
    }

    /// Process-wide current registry used by ``Subtitle`` convenience APIs.
    public static var current: Self {
        get { SubtitleFormatRegistryStore.shared.get() }
        set { SubtitleFormatRegistryStore.shared.set(newValue) }
    }

    /// All formats in detection order.
    public var supportedFormats: [SubtitleFormat] {
        detectionOrder
    }

    /// Canonical format names for the currently registered formats.
    public var supportedFormatNames: [String] {
        var names: [String] = []
        for format in detectionOrder {
            if !names.contains(where: { Self.normalize($0) == Self.normalize(format.name) }) {
                names.append(format.name)
            }
        }
        return names.sorted()
    }

    /// Adds a format to this registry value.
    public mutating func register(_ format: SubtitleFormat) {
        self = appending(format)
    }

    /// Returns a copy of this registry with one additional format.
    public func appending(_ format: SubtitleFormat) -> Self {
        .init(formats: detectionOrder + [format])
    }

    /// Registers a format in ``current``.
    public static func register(_ format: SubtitleFormat) {
        var value = current
        value.register(format)
        current = value
    }

    /// Resets ``current`` back to ``standard``.
    public static func resetCurrent() {
        current = .standard
    }

    func resolve(name: String) -> SubtitleFormat? {
        formatsByName[Self.normalize(name)]
    }

    func resolve(fileExtension: String) -> SubtitleFormat? {
        let ext = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        guard !ext.isEmpty else { return nil }
        return resolve(name: ext)
    }

    func resolve(fileName: String) -> SubtitleFormat? {
        let trimmed = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let dot = trimmed.lastIndex(of: ".") else { return nil }
        let ext = String(trimmed[trimmed.index(after: dot)...])
        return resolve(fileExtension: ext)
    }

    func detectFormat(content: String) -> SubtitleFormat? {
        for format in detectionOrder where format.canParse(content) {
            return format
        }
        return nil
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
