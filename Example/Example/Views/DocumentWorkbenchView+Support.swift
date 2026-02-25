//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SwiftUI
import SubtitleKit

extension DocumentWorkbenchView {
    var filteredCues: [SubtitleCue] {
        let query = document.cueSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return document.subtitle.cues
        }
        return document.subtitle.cues.filter { cue in
            cue.rawText.localizedCaseInsensitiveContains(query)
                || cue.plainText.localizedCaseInsensitiveContains(query)
                || String(cue.id).contains(query)
                || (cue.cueIdentifier?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var selectedCue: SubtitleCue? {
        guard let id = document.selectedCueID else {
            return nil
        }
        return document.cue(id: id)
    }

    var filteredChanges: [SubtitleCleanReport.CueChange] {
        guard let preview = document.cleanPreview else {
            return []
        }
        if document.showChangedChangesOnly {
            return preview.report.changes.filter { $0.status != .unchanged }
        }
        return preview.report.changes
    }

    var selectedChange: SubtitleCleanReport.CueChange? {
        guard let id = document.selectedChangeID else {
            return nil
        }
        return filteredChanges.first(where: { $0.id == id })
            ?? document.cleanPreview?.report.changes.first(where: { $0.id == id })
    }

    var selectedCueIdentifierBinding: Binding<String> {
        Binding(
            get: { selectedCue?.cueIdentifier ?? "" },
            set: { newValue in
                guard let id = document.selectedCueID else {
                    return
                }
                document.updateCue(id: id) { cue in
                    cue.cueIdentifier = newValue.isEmpty ? nil : newValue
                }
            }
        )
    }

    var selectedCueStartBinding: Binding<Int> {
        Binding(
            get: { selectedCue?.startTime ?? 0 },
            set: { newValue in
                guard let id = document.selectedCueID else {
                    return
                }
                document.updateCue(id: id) { cue in
                    cue.startTime = max(0, newValue)
                    cue.endTime = max(cue.startTime, cue.endTime)
                }
            }
        )
    }

    var selectedCueEndBinding: Binding<Int> {
        Binding(
            get: { selectedCue?.endTime ?? 0 },
            set: { newValue in
                guard let id = document.selectedCueID else {
                    return
                }
                document.updateCue(id: id) { cue in
                    cue.endTime = max(cue.startTime, newValue)
                }
            }
        )
    }

    var selectedCueRawTextBinding: Binding<String> {
        Binding(
            get: { selectedCue?.rawText ?? "" },
            set: { newValue in
                guard let id = document.selectedCueID else {
                    return
                }
                document.updateCue(id: id) { cue in
                    cue.rawText = newValue
                    // Keep the hidden normalized field from becoming stale when the UI only edits raw text.
                    cue.plainText = newValue
                }
            }
        )
    }

    var editorBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(nsColor: .textBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.35), lineWidth: 1)
            )
    }

    func binding(for option: SubtitleCleanOption) -> Binding<Bool> {
        Binding(
            get: { document.cleanOptions.contains(option) },
            set: { isOn in
                if isOn {
                    document.cleanOptions.insert(option)
                } else {
                    document.cleanOptions.remove(option)
                }
                document.invalidatePreview(preserveSelection: true)
            }
        )
    }

    func nudgeSelectedCue(by delta: Int) {
        guard let id = document.selectedCueID else {
            return
        }
        document.updateCue(id: id) { cue in
            cue.startTime = max(0, cue.startTime + delta)
            cue.endTime = max(cue.startTime, cue.endTime + delta)
        }
    }

    func displayText(for cue: SubtitleCue) -> String {
        let text = cue.rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? cue.plainText : text
    }

    func statusView(_ status: SubtitleCleanReport.Status) -> some View {
        switch status {
        case .unchanged:
            return AnyView(StatusBadge(text: "Same", tint: .gray))
        case .modified:
            return AnyView(StatusBadge(text: "Modified", tint: .green))
        case .removed:
            return AnyView(StatusBadge(text: "Removed", tint: .red))
        }
    }

    func diffTextPane(title: String, body: String, tint: StatusBadge.Tint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(text: tint == .green ? "Updated" : (tint == .red ? "Removed" : "Preview"), tint: tint)
            }
            .padding(.horizontal, 8)
            .padding(.top, 2)

            ScrollView {
                Text(body.isEmpty ? " " : body)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(10)
                    .textSelection(.enabled)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                (
                                    tint == .green ? Color.green : tint == .red ? Color.red : Color(
                                        nsColor: .separatorColor
                                    )
                                )
                                .opacity(tint == .gray ? 0.35 : 0.18),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}
