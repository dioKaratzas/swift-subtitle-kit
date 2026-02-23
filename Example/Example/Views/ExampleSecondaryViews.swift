//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import AppKit
import SwiftUI
import SubtitleKit

struct EmptyWorkbenchView: View {
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ContentUnavailableView(
                "SubtitleKit Studio",
                systemImage: "captions.bubble",
                description: Text(
                    "Open subtitle files to preview cleaning changes, edit cues, convert formats, and save/export results."
                )
            )

            Button("Open Subtitle Files", systemImage: "folder.badge.plus", action: onOpen)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SidebarDocumentRow: View {
    private let contentPadding: CGFloat = 12

    let document: ShowcaseDocument
    let isSelected: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(document.displayName)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                        .lineLimit(1)
                    if document.isDirty {
                        StatusBadge(text: "Edited", tint: .amber)
                    }
                }
                HStack(spacing: 6) {
                    Text(document.currentFormatLabel.uppercased())
                    Text("•")
                    Text("\(document.subtitle.cues.count) cues")
                    if let preview = document.cleanPreview {
                        Text("•")
                        Text("\(preview.report.modifiedCueCount + preview.report.removedCueCount) changes")
                    }
                }
                .font(.caption)
                .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.secondary)
            }

            Spacer(minLength: 6)

            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(isSelected ? Color.white.opacity(0.45) : Color.secondary.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(contentPadding)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

struct CardSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.25), lineWidth: 1)
            )
    }
}

struct MetaChip: View {
    let icon: String
    let text: String
    var tint = StatusBadge.Tint.gray

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule(style: .continuous)
                .fill(backgroundColor)
        )
    }

    private var backgroundColor: Color {
        switch tint {
        case .amber: return .orange.opacity(0.12)
        case .green: return .green.opacity(0.10)
        case .red: return .red.opacity(0.10)
        case .gray: return .secondary.opacity(0.10)
        }
    }

    private var foregroundColor: Color {
        switch tint {
        case .amber: return .orange
        case .green: return .green
        case .red: return .red
        case .gray: return .secondary
        }
    }
}

struct StatusBadge: View {
    enum Tint {
        case amber
        case green
        case red
        case gray
    }

    let text: String
    let tint: Tint

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(background))
            .foregroundStyle(foreground)
    }

    private var foreground: Color {
        switch tint {
        case .amber: return .orange
        case .green: return .green
        case .red: return .red
        case .gray: return .secondary
        }
    }

    private var background: Color {
        switch tint {
        case .amber: return .orange.opacity(0.10)
        case .green: return .green.opacity(0.08)
        case .red: return .red.opacity(0.08)
        case .gray: return .secondary.opacity(0.08)
        }
    }
}

struct FullDiffSheetView: View {
    let model: FullDiffSheetModel
    private let rows: [SideBySideDiffRow]

    init(model: FullDiffSheetModel) {
        self.model = model
        self.rows = SideBySideDiffRow.build(
            originalText: model.originalText,
            cleanedText: model.cleanedText
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            CardSurface {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Label(model.title, systemImage: "doc.text")
                            .font(.headline)
                        Spacer()
                        StatusBadge(text: "Changed", tint: .amber)
                    }
                    HStack(spacing: 8) {
                        MetaChip(icon: "sum", text: "Total \(model.stats.total)")
                        MetaChip(icon: "arrow.right", text: "Remaining \(model.stats.remaining)")
                        MetaChip(icon: "pencil", text: "\(model.stats.modified) modified", tint: .amber)
                        MetaChip(icon: "trash", text: "\(model.stats.removed) removed", tint: .red)
                        MetaChip(icon: "arrow.left.and.right", text: "\(changedRowCount) diff rows")
                    }
                }
            }

            diffGridCard
        }
        .padding(14)
    }

    private var changedRowCount: Int {
        rows.reduce(into: 0) { count, row in
            if row.kind != .unchanged {
                count += 1
            }
        }
    }

    private var diffGridCard: some View {
        CardSurface {
            VStack(spacing: 0) {
                ScrollView([.vertical, .horizontal]) {
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            diffColumnHeader("Original")
                            Divider()
                            diffColumnHeader("Cleaned")
                        }
                        .frame(height: 38)
                        .frame(minWidth: SideBySideDiffRowView.totalMinWidth, maxWidth: .infinity)
                        .background(Color(nsColor: .underPageBackgroundColor))

                        Divider()

                        LazyVStack(spacing: 0) {
                            ForEach(rows) { row in
                                SideBySideDiffRowView(row: row)
                            }
                        }
                        .frame(
                            minWidth: SideBySideDiffRowView.totalMinWidth,
                            maxWidth: .infinity,
                            alignment: .topLeading
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .textSelection(.enabled)
                    .padding(.bottom, 8)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .frame(minHeight: 440)
            }
        }
    }

    private func diffColumnHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 38, alignment: .center)
    }
}

private struct SideBySideDiffRowView: View {
    static let columnMinWidth: CGFloat = 520
    static let totalMinWidth: CGFloat = columnMinWidth * 2 + 1

    let row: SideBySideDiffRow

    var body: some View {
        if row.kind == .collapsed {
            collapsedRow
        } else {
            contentRow
        }
    }

    private var contentRow: some View {
        HStack(spacing: 0) {
            diffCell(
                marker: leftMarker,
                lineNumber: row.leftLineNumber,
                text: row.leftText,
                tint: leftTint
            )

            Divider()

            diffCell(
                marker: rightMarker,
                lineNumber: row.rightLineNumber,
                text: row.rightText,
                tint: rightTint
            )
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var collapsedRow: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "ellipsis")
                    .font(.caption)
                Text("\(row.collapsedCount ?? 0) unchanged lines")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 6)
        }
        .background(Color(nsColor: .underPageBackgroundColor).opacity(0.7))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var leftTint: Color {
        switch row.kind {
        case .unchanged:
            return .clear
        case .removed:
            return .red.opacity(0.10)
        case .added:
            return Color(nsColor: .textBackgroundColor)
        case .modified:
            return .orange.opacity(0.08)
        case .collapsed:
            return .clear
        }
    }

    private var rightTint: Color {
        switch row.kind {
        case .unchanged:
            return .clear
        case .removed:
            return Color(nsColor: .textBackgroundColor)
        case .added:
            return .green.opacity(0.10)
        case .modified:
            return .orange.opacity(0.08)
        case .collapsed:
            return .clear
        }
    }

    private var leftMarker: String {
        switch row.kind {
        case .removed: return "-"
        case .added: return ""
        case .modified: return "±"
        case .unchanged, .collapsed: return ""
        }
    }

    private var rightMarker: String {
        switch row.kind {
        case .added: return "+"
        case .removed: return ""
        case .modified: return "±"
        case .unchanged, .collapsed: return ""
        }
    }

    private func diffCell(marker: String, lineNumber: Int?, text: String?, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(marker)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(markerColor(marker))
                .frame(width: 12, alignment: .center)

            Text(lineNumber.map(String.init) ?? "")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            Text(verbatim: displayText(text))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(minWidth: Self.columnMinWidth, maxWidth: .infinity, alignment: .leading)
        .background(tint)
    }

    private func markerColor(_ marker: String) -> Color {
        switch marker {
        case "-": return .red
        case "+": return .green
        case "±": return .orange
        default: return .secondary
        }
    }

    private func displayText(_ text: String?) -> String {
        guard let text else {
            return ""
        }
        return text.isEmpty ? " " : text
    }
}

private struct SideBySideDiffRow: Identifiable {
    enum Kind {
        case unchanged
        case removed
        case added
        case modified
        case collapsed
    }

    let id: Int
    let kind: Kind
    let leftLineNumber: Int?
    let leftText: String?
    let rightLineNumber: Int?
    let rightText: String?
    let collapsedCount: Int?
}

private extension SideBySideDiffRow {
    private struct PendingLineChange {
        let offset: Int
        let text: String
    }

    private struct DiffSourceLine {
        let lineNumber: Int
        let text: String
    }

    static func build(originalText: String, cleanedText: String) -> [Self] {
        let originalLines = splitLines(originalText)
        let cleanedLines = splitLines(cleanedText)
        let diff = cleanedLines.map(\.text).difference(from: originalLines.map(\.text))

        var removals = [PendingLineChange]()
        var inserts = [PendingLineChange]()

        for change in diff {
            switch change {
            case let .remove(offset, element, _):
                removals.append(.init(offset: offset, text: element))
            case let .insert(offset, element, _):
                inserts.append(.init(offset: offset, text: element))
            }
        }

        removals.sort { $0.offset < $1.offset }
        inserts.sort { $0.offset < $1.offset }

        var rows = [Self]()
        rows.reserveCapacity(max(originalLines.count, cleanedLines.count))

        var originalIndex = 0
        var cleanedIndex = 0
        var removalIndex = 0
        var insertIndex = 0
        var rowID = 0

        func appendRow(
            kind: Kind,
            leftIndex: Int?,
            leftText: String?,
            rightIndex: Int?,
            rightText: String?
        ) {
            rows.append(
                .init(
                    id: rowID,
                    kind: kind,
                    leftLineNumber: leftIndex.map { originalLines[$0].lineNumber },
                    leftText: leftText,
                    rightLineNumber: rightIndex.map { cleanedLines[$0].lineNumber },
                    rightText: rightText,
                    collapsedCount: nil
                )
            )
            rowID += 1
        }

        while originalIndex < originalLines.count || cleanedIndex < cleanedLines.count {
            if originalIndex < originalLines.count,
               cleanedIndex < cleanedLines.count,
               originalLines[originalIndex].text == cleanedLines[cleanedIndex].text {
                appendRow(
                    kind: .unchanged,
                    leftIndex: originalIndex,
                    leftText: originalLines[originalIndex].text,
                    rightIndex: cleanedIndex,
                    rightText: cleanedLines[cleanedIndex].text
                )
                originalIndex += 1
                cleanedIndex += 1
                continue
            }

            let removalRun = consumeRemovalRun(
                removals: removals,
                from: &removalIndex,
                startingAt: originalIndex
            )
            let insertRun = consumeInsertRun(
                inserts: inserts,
                from: &insertIndex,
                startingAt: cleanedIndex
            )

            if !removalRun.isEmpty || !insertRun.isEmpty {
                let pairCount = min(removalRun.count, insertRun.count)

                for pairOffset in 0 ..< pairCount {
                    appendRow(
                        kind: .modified,
                        leftIndex: originalIndex,
                        leftText: removalRun[pairOffset],
                        rightIndex: cleanedIndex,
                        rightText: insertRun[pairOffset]
                    )
                    originalIndex += 1
                    cleanedIndex += 1
                }

                if removalRun.count > pairCount {
                    for text in removalRun.dropFirst(pairCount) {
                        appendRow(
                            kind: .removed,
                            leftIndex: originalIndex,
                            leftText: text,
                            rightIndex: nil,
                            rightText: nil
                        )
                        originalIndex += 1
                    }
                }

                if insertRun.count > pairCount {
                    for text in insertRun.dropFirst(pairCount) {
                        appendRow(
                            kind: .added,
                            leftIndex: nil,
                            leftText: nil,
                            rightIndex: cleanedIndex,
                            rightText: text
                        )
                        cleanedIndex += 1
                    }
                }

                continue
            }

            if originalIndex < originalLines.count, cleanedIndex < cleanedLines.count {
                appendRow(
                    kind: .modified,
                    leftIndex: originalIndex,
                    leftText: originalLines[originalIndex].text,
                    rightIndex: cleanedIndex,
                    rightText: cleanedLines[cleanedIndex].text
                )
                originalIndex += 1
                cleanedIndex += 1
            } else if originalIndex < originalLines.count {
                appendRow(
                    kind: .removed,
                    leftIndex: originalIndex,
                    leftText: originalLines[originalIndex].text,
                    rightIndex: nil,
                    rightText: nil
                )
                originalIndex += 1
            } else if cleanedIndex < cleanedLines.count {
                appendRow(
                    kind: .added,
                    leftIndex: nil,
                    leftText: nil,
                    rightIndex: cleanedIndex,
                    rightText: cleanedLines[cleanedIndex].text
                )
                cleanedIndex += 1
            }
        }

        return collapseUnchangedRuns(in: rows, context: 2)
    }

    private static func splitLines(_ text: String) -> [DiffSourceLine] {
        guard !text.isEmpty else {
            return []
        }
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        return lines.enumerated().compactMap { index, line in
            if isLikelySRTCueNumberLine(lines, index: index) {
                return nil
            }
            return .init(lineNumber: index + 1, text: line)
        }
    }

    private static func isLikelySRTCueNumberLine(_ lines: [String], index: Int) -> Bool {
        let current = lines[index].trimmingCharacters(in: .whitespaces)
        guard !current.isEmpty else {
            return false
        }
        guard current.allSatisfy(\.isNumber) else {
            return false
        }

        let previous = index > 0 ? lines[index - 1].trimmingCharacters(in: .whitespaces) : ""
        let next = index + 1 < lines.count ? lines[index + 1].trimmingCharacters(in: .whitespaces) : ""

        return (index == 0 || previous.isEmpty) && next.contains("-->")
    }

    private static func consumeRemovalRun(
        removals: [PendingLineChange],
        from index: inout Int,
        startingAt offset: Int
    ) -> [String] {
        var run = [String]()
        var expectedOffset = offset
        var cursor = index

        while cursor < removals.count, removals[cursor].offset == expectedOffset {
            run.append(removals[cursor].text)
            expectedOffset += 1
            cursor += 1
        }

        index = cursor
        return run
    }

    private static func consumeInsertRun(
        inserts: [PendingLineChange],
        from index: inout Int,
        startingAt offset: Int
    ) -> [String] {
        var run = [String]()
        var expectedOffset = offset
        var cursor = index

        while cursor < inserts.count, inserts[cursor].offset == expectedOffset {
            run.append(inserts[cursor].text)
            expectedOffset += 1
            cursor += 1
        }

        index = cursor
        return run
    }

    private static func collapseUnchangedRuns(in rows: [Self], context: Int) -> [Self] {
        guard !rows.isEmpty else {
            return []
        }

        var output = [Self]()
        var index = 0
        var nextID = (rows.last?.id ?? 0) + 1

        while index < rows.count {
            if rows[index].kind != .unchanged {
                output.append(rows[index])
                index += 1
                continue
            }

            let start = index
            while index < rows.count, rows[index].kind == .unchanged {
                index += 1
            }
            let run = Array(rows[start ..< index])

            let isLeadingRun = output.isEmpty
            let isTrailingRun = index == rows.count
            let keep = (isLeadingRun || isTrailingRun) ? 3 : context

            if run.count <= (keep * 2 + 1) {
                output.append(contentsOf: run)
                continue
            }

            output.append(contentsOf: run.prefix(keep))
            output.append(
                .init(
                    id: nextID,
                    kind: .collapsed,
                    leftLineNumber: nil,
                    leftText: nil,
                    rightLineNumber: nil,
                    rightText: nil,
                    collapsedCount: run.count - keep * 2
                )
            )
            nextID += 1
            output.append(contentsOf: run.suffix(keep))
        }

        return output
    }
}
