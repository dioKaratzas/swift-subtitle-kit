//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SwiftUI
import Foundation
import SubtitleKit

struct ResyncOptionsSheet: View {
    @Binding var document: ShowcaseDocument
    @Environment(\.dismiss) private var dismiss

    @State private var offset = 0
    @State private var ratio = 1.0
    @State private var useFrameValues = false

    var body: some View {
        VStack(spacing: 12) {
            headerCard
            controlsCard
            previewCard
            footerActions
        }
        .padding(14)
        .frame(minWidth: 860, minHeight: 560)
    }

    private var resyncOptions: SubtitleResyncOptions {
        .init(offset: offset, ratio: max(0.001, ratio), useFrameValues: useFrameValues)
    }

    private var previewSubtitle: Subtitle {
        document.subtitle.resync(resyncOptions)
    }

    private var previewRows: [PreviewRow] {
        let originalCues = document.subtitle.cues
        let resyncedCues = previewSubtitle.cues
        guard !originalCues.isEmpty else {
            return []
        }

        var rows = zip(originalCues, resyncedCues).map { original, resynced in
            PreviewRow(original: original, resynced: resynced)
        }

        if let selectedCueID = document.selectedCueID,
           let selectedIndex = rows.firstIndex(where: { $0.cueID == selectedCueID }) {
            let selected = rows.remove(at: selectedIndex)
            rows.insert(selected, at: 0)
        }

        return Array(rows.prefix(20))
    }

    private var hasPendingChanges: Bool {
        offset != 0 || abs(ratio - 1.0) > 0.000_001
    }

    private var cuesWithFrameRanges: Int {
        document.subtitle.cues.reduce(into: 0) { count, cue in
            if cue.frameRange != nil {
                count += 1
            }
        }
    }

    private var headerCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Resync Subtitle Timing", systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                        .font(.headline)
                    Spacer()
                    if hasPendingChanges {
                        StatusBadge(text: "Preview", tint: .amber)
                    }
                }

                Text(document.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("Preview is non-destructive until you press Apply Resync.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controlsCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    MetaChip(icon: "captions.bubble", text: "\(document.subtitle.cues.count) cues")
                    MetaChip(icon: "arrow.left.and.right", text: "Offset \(signedMilliseconds(offset))")
                    MetaChip(icon: "percent", text: "Ratio \(ratioString)")
                    if cuesWithFrameRanges > 0 {
                        MetaChip(icon: "film", text: "\(cuesWithFrameRanges) frame cues")
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("Offset (ms)")
                        .frame(width: 90, alignment: .leading)
                        .foregroundStyle(.secondary)

                    TextField(
                        "Offset",
                        value: $offset,
                        format: .number.grouping(.never)
                    )
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)

                    Stepper("", value: $offset, in: -3_600_000 ... 3_600_000, step: 100)
                        .labelsHidden()

                    Spacer()

                    HStack(spacing: 6) {
                        Button("-500 ms") { offset -= 500 }
                        Button("+500 ms") { offset += 500 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                Text(
                    "Moves every cue by a fixed amount. Positive values make subtitles appear later, negative values make them appear earlier."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("Ratio")
                            .frame(width: 90, alignment: .leading)
                            .foregroundStyle(.secondary)

                        TextField(
                            "Ratio",
                            value: ratioBinding,
                            format: .number.precision(.fractionLength(3))
                        )
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)

                        Spacer()

                        Button("1.000") { ratio = 1.0 }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                }
                Text(
                    "Scales timing to fix drift. `1.000` means no change. Above `1.000` stretches timing (later over time), below `1.000` compresses timing."
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Toggle(isOn: $useFrameValues) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Use frame values when available")
                        Text(
                            "Some subtitles store timing as video frame numbers instead of milliseconds. Turn this on to resync those frame-based cues directly. For normal SRT/VTT files, leave this off."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)

                HStack {
                    Spacer()
                    Button("Reset") {
                        offset = 0
                        ratio = 1.0
                        useFrameValues = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var previewCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Timing Preview")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Showing up to 20 cues")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if previewRows.isEmpty {
                    Text("No cues available to preview.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    Table(previewRows) {
                        TableColumn("#") { row in
                            Text("\(row.cueID)")
                                .font(.system(.body, design: .monospaced))
                        }
                        .width(min: 44, ideal: 56, max: 72)

                        TableColumn("Start") { row in
                            Text(timestampString(from: row.originalStart))
                                .font(.system(.body, design: .monospaced))
                        }
                        .width(min: 120, ideal: 136, max: 160)

                        TableColumn("→") { row in
                            Text(timestampString(from: row.resyncedStart))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(row.startDelta == 0 ? Color.primary : Color.green)
                        }
                        .width(min: 120, ideal: 136, max: 160)

                        TableColumn("Δ Start") { row in
                            Text(signedMilliseconds(row.startDelta))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(row.startDelta == 0 ? Color.secondary : Color.green)
                        }
                        .width(min: 88, ideal: 96, max: 112)

                        TableColumn("End") { row in
                            Text(timestampString(from: row.originalEnd))
                                .font(.system(.body, design: .monospaced))
                        }
                        .width(min: 120, ideal: 136, max: 160)

                        TableColumn("→ ") { row in
                            Text(timestampString(from: row.resyncedEnd))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(row.endDelta == 0 ? Color.primary : Color.green)
                        }
                        .width(min: 120, ideal: 136, max: 160)

                        TableColumn("Δ End") { row in
                            Text(signedMilliseconds(row.endDelta))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(row.endDelta == 0 ? Color.secondary : Color.green)
                        }
                        .width(min: 88, ideal: 96, max: 112)
                    }
                    .tableStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 260)
                }
            }
        }
    }

    private var footerActions: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) {
                dismiss()
            }
            Button {
                document.applyResync(resyncOptions)
                dismiss()
            } label: {
                Label("Apply Resync", systemImage: "checkmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasPendingChanges)
        }
    }

    private var ratioBinding: Binding<Double> {
        Binding(
            get: { ratio },
            set: { newValue in
                ratio = max(0.001, min(10, newValue))
            }
        )
    }

    private var ratioString: String {
        String(format: "%.3f", ratio)
    }

    private func signedMilliseconds(_ value: Int) -> String {
        if value > 0 {
            return "+\(value)ms"
        }
        if value < 0 {
            return "\(value)ms"
        }
        return "0ms"
    }
}

private struct PreviewRow: Identifiable {
    let cueID: Int
    let originalStart: Int
    let originalEnd: Int
    let resyncedStart: Int
    let resyncedEnd: Int

    var id: Int {
        cueID
    }

    var startDelta: Int {
        resyncedStart - originalStart
    }

    var endDelta: Int {
        resyncedEnd - originalEnd
    }

    init(original: SubtitleCue, resynced: SubtitleCue) {
        cueID = original.id
        originalStart = original.startTime
        originalEnd = original.endTime
        resyncedStart = resynced.startTime
        resyncedEnd = resynced.endTime
    }
}
