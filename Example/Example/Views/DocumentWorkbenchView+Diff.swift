//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import SwiftUI
import SubtitleKit

extension DocumentWorkbenchView {
    var diffPreviewCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Diff Preview")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    if document.cleanPreview != nil {
                        Toggle("Changed only", isOn: $document.showChangedChangesOnly)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                        Text("Changed only")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let preview = document.cleanPreview {
                    let report = preview.report
                    HStack(spacing: 8) {
                        MetaChip(icon: "sum", text: "Total \(report.originalCueCount)")
                        MetaChip(icon: "arrow.right", text: "Remaining \(report.remainingCueCount)")
                        MetaChip(icon: "pencil", text: "\(report.modifiedCueCount) modified", tint: .amber)
                        MetaChip(icon: "trash", text: "\(report.removedCueCount) removed", tint: .red)
                        Spacer()
                        Button {
                            onPreviewFullDiff(document)
                        } label: {
                            Label("Full Diff", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        .buttonStyle(.bordered)
                    }

                    Table(filteredChanges, selection: $document.selectedChangeID) {
                        TableColumn("#") { change in
                            Text("\(change.cueID)")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                        .width(min: 40, ideal: 52, max: 70)

                        TableColumn("Original") { change in
                            Text(displayText(for: change.original))
                                .lineLimit(1)
                                .foregroundStyle(.primary)
                                .padding(.leading, 6)
                        }

                        TableColumn("Cleaned") { change in
                            if let cleaned = change.cleaned {
                                Text(displayText(for: cleaned))
                                    .lineLimit(1)
                                    .foregroundStyle(change.status == .modified ? Color.green : Color.primary)
                                    .padding(.leading, 6)
                            } else {
                                Text("Removed")
                                    .italic()
                                    .foregroundStyle(Color.red)
                                    .padding(.leading, 6)
                            }
                        }

                        TableColumn("Status") { change in
                            statusView(change.status)
                        }
                        .width(min: 90, ideal: 96, max: 110)
                    }
                    .tableStyle(.inset)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)

                    if let selectedChange {
                        HSplitView {
                            diffTextPane(
                                title: "Original",
                                body: selectedChange.original.rawText,
                                tint: selectedChange.status == .removed ? .red : .gray
                            )
                            diffTextPane(
                                title: "Cleaned",
                                body: selectedChange.cleaned?.rawText ?? "Removed",
                                tint: selectedChange.status == .modified ? .green : (
                                    selectedChange.status == .removed ? .red : .gray
                                )
                            )
                        }
                        .frame(minHeight: 150)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generate a preview to inspect per-cue changes before applying cleaning.")
                            .foregroundStyle(.primary)
                        Text("This view uses `SubtitleCleanReport`, so no extra diff package is required.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Use “Preview Changes” in the inspector above.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
