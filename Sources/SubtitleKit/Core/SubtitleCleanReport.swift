//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import Foundation

/// Output of a cleaning operation with transformed subtitle and a change report.
public struct SubtitleCleanResult: Sendable, Hashable {
    /// Cleaned subtitle.
    public var subtitle: Subtitle
    /// Per-cue cleaning summary and counts.
    public var report: SubtitleCleanReport

    public init(subtitle: Subtitle, report: SubtitleCleanReport) {
        self.subtitle = subtitle
        self.report = report
    }
}

/// Report describing how each original cue changed during cleaning.
public struct SubtitleCleanReport: Sendable, Hashable {
    /// Cue-level change category.
    public enum Status: String, Sendable, Hashable, Codable {
        case unchanged
        case modified
        case removed
    }

    /// Change entry for one original cue.
    public struct CueChange: Sendable, Hashable, Identifiable {
        /// Original cue id.
        public var cueID: Int
        /// Final state for this cue.
        public var status: Status
        /// Original cue before cleaning.
        public var original: SubtitleCue
        /// Cleaned cue when still present. `nil` when removed.
        public var cleaned: SubtitleCue?
        /// Options that contributed to this change.
        public var changedBy: [SubtitleCleanOption]

        public init(
            cueID: Int,
            status: Status,
            original: SubtitleCue,
            cleaned: SubtitleCue?,
            changedBy: [SubtitleCleanOption] = []
        ) {
            self.cueID = cueID
            self.status = status
            self.original = original
            self.cleaned = cleaned
            self.changedBy = changedBy
        }

        public var id: Int {
            cueID
        }
    }

    /// Number of cues before cleaning.
    public var originalCueCount: Int
    /// Number of cues after cleaning.
    public var remainingCueCount: Int
    /// Per-cue changes in original cue order.
    public var changes: [CueChange]

    public init(
        originalCueCount: Int,
        remainingCueCount: Int,
        changes: [CueChange]
    ) {
        self.originalCueCount = originalCueCount
        self.remainingCueCount = remainingCueCount
        self.changes = changes
    }

    /// Number of cues removed during cleaning.
    public var removedCueCount: Int {
        changes.lazy.count(where: { $0.status == .removed })
    }

    /// Number of cues that changed but remained.
    public var modifiedCueCount: Int {
        changes.lazy.count(where: { $0.status == .modified })
    }

    /// Number of cues unaffected by cleaning.
    public var unchangedCueCount: Int {
        changes.lazy.count(where: { $0.status == .unchanged })
    }
}
