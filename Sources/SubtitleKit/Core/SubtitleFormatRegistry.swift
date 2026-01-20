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
        defer { lock.unlock() }
        registry = value
    }

    func mutate(_ body: (inout SubtitleFormatRegistry) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        body(&registry)
    }
}

/// Registry of available subtitle formats used for resolution and content detection.
///
/// The registry maps format names and aliases to their adapters, and defines
/// the order in which content-based detection is attempted.
///
/// Use ``current`` to access the process-wide registry, or ``standard`` to get
/// a fresh registry with only the built-in formats.
///
/// ## Thread Safety
/// Access to ``current`` is internally synchronized. The static ``register(_:)``
/// method is atomic. Custom formats must also be `Sendable`.
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
    ///
    /// This operation is atomic with respect to other concurrent mutations of ``current``.
    public static func register(_ format: SubtitleFormat) {
        SubtitleFormatRegistryStore.shared.mutate { registry in
            registry.register(format)
        }
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
