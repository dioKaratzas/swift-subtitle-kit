//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SwiftUI
import SubtitleKit

extension DocumentWorkbenchView {
    var headerCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: "doc.text")
                                .foregroundStyle(.primary)
                            Text(document.displayName)
                                .font(.system(.title2, design: .rounded).weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            if document.isDirty {
                                StatusBadge(text: "CHANGED", tint: .amber)
                            }
                        }

                        HStack(spacing: 8) {
                            MetaChip(icon: "captions.bubble", text: "\(document.subtitle.cues.count) cues")
                            MetaChip(icon: "square.stack.3d.up", text: document.currentFormatLabel.uppercased())
                            if let preview = document.cleanPreview {
                                MetaChip(
                                    icon: "eye",
                                    text: "\(preview.report.modifiedCueCount + preview.report.removedCueCount) preview changes",
                                    tint: .amber
                                )
                            }
                            if let path = document.fileURL?.path {
                                MetaChip(icon: "folder", text: path)
                            }
                        }
                    }

                    Spacer()
                }

                HStack(spacing: 12) {
                    Label(workbenchHeaderTitle, systemImage: workbenchHeaderSystemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(workbenchHeaderSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    var cueTableCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Text("Subtitles")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        isResyncSheetPresented = true
                    } label: {
                        Label("Resync…", systemImage: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Open timing resync options and preview the timing changes before applying them.")

                    TextField("Search cue text or ID", text: $document.cueSearchQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 260)
                }

                HStack(spacing: 8) {
                    MetaChip(icon: "line.3.horizontal.decrease.circle", text: "\(filteredCues.count) shown")
                    if filteredCues.count != document.subtitle.cues.count {
                        MetaChip(icon: "text.magnifyingglass", text: "filtered")
                    }
                    if let selectedCue {
                        MetaChip(icon: "checkmark.circle", text: "cue #\(selectedCue.id) selected", tint: .green)
                    }
                    Spacer()
                }

                Table(filteredCues, selection: $document.selectedCueID) {
                    TableColumn("#") { cue in
                        Text("\(cue.id)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .width(min: 44, ideal: 56, max: 72)

                    TableColumn("Start") { cue in
                        Text(timestampString(from: cue.startTime))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                    .width(min: 120, ideal: 136, max: 160)

                    TableColumn("End") { cue in
                        Text(timestampString(from: cue.endTime))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                    .width(min: 120, ideal: 136, max: 160)

                    TableColumn("Duration") { cue in
                        Text("\(cue.duration) ms")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .width(min: 80, ideal: 92, max: 110)

                    TableColumn("Text") { cue in
                        Text(cue.rawText.replacingOccurrences(of: "\n", with: " ⏎ "))
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .tableStyle(.inset)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 330)
            }
        }
        .sheet(isPresented: $isResyncSheetPresented) {
            ResyncOptionsSheet(document: $document)
        }
    }

    var cueInspectorCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Cue Editor")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    if selectedCue != nil {
                        Button(role: .destructive) {
                            document.deleteSelectedCue()
                        } label: {
                            Label("Delete Cue", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if let selectedCue {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            MetaChip(icon: "number", text: "cue #\(selectedCue.id)")
                            if let identifier = selectedCue.cueIdentifier, !identifier.isEmpty {
                                MetaChip(icon: "tag", text: identifier)
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Button("-100ms") { nudgeSelectedCue(by: -100) }
                                Button("+100ms") { nudgeSelectedCue(by: 100) }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }

                        HStack(spacing: 10) {
                            TextField("Cue Identifier", text: selectedCueIdentifierBinding)
                                .textFieldStyle(.roundedBorder)

                            TextField("Start (ms)", value: selectedCueStartBinding, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 130)

                            TextField("End (ms)", value: selectedCueEndBinding, format: .number.grouping(.never))
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 130)
                        }

                        HStack(spacing: 8) {
                            Text(timestampString(from: selectedCue.startTime))
                            Text("→")
                            Text(timestampString(from: selectedCue.endTime))
                            Text("(\(max(0, selectedCue.duration)) ms)")
                                .foregroundStyle(.secondary)
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.primary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Cue Text")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .help(
                                    "Edits the original/stored cue text. Format markup (for example ASS/HTML tags) is preserved when present."
                                )
                            TextEditor(text: selectedCueRawTextBinding)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 130)
                                .scrollContentBackground(.hidden)
                                .background(editorBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        Text(
                            "Edits apply to the stored/original cue text. A plain-text representation is maintained automatically for searching and cleaning."
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Select a cue from the table to edit timing and text.")
                            .foregroundStyle(.primary)
                        Text("The inspector edits the real `Subtitle` model and keeps metadata/style entries intact.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    var cleanOptionsCard: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Cleaning Options")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Reset") {
                        document.cleanOptions = ShowcaseDocument.defaultCleanOptions
                        document.invalidatePreview(preserveSelection: true)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(CleanOptionDescriptor.allCases) { descriptor in
                            Toggle(isOn: binding(for: descriptor.option)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(descriptor.title)
                                        .foregroundStyle(.primary)
                                    Text(descriptor.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .toggleStyle(.checkbox)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(minHeight: 170, maxHeight: 255)

                HStack(spacing: 8) {
                    Button {
                        document.generateCleanPreview()
                    } label: {
                        Label("Preview Changes", systemImage: "eye")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        document.applyCleanPreviewOrCleanNow()
                    } label: {
                        Label("Apply Clean", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("\(document.cleanOptions.count) enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private extension DocumentWorkbenchView {
    var workbenchHeaderTitle: String {
        switch pane {
        case .subtitles:
            return "Subtitle editing table"
        case .cleaning:
            return "Cleaning and diff preview"
        }
    }

    var workbenchHeaderSystemImage: String {
        switch pane {
        case .subtitles:
            return "tablecells"
        case .cleaning:
            return "wand.and.stars"
        }
    }

    var workbenchHeaderSubtitle: String {
        switch pane {
        case .subtitles:
            return "Select a cue below and edit timing/text in the inspector."
        case .cleaning:
            return "Configure cleaning options, preview per-cue changes, and open the full diff."
        }
    }
}
