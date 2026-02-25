//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SwiftUI

struct SidebarPaneView: View {
    let documents: [ShowcaseDocument]
    @Binding var selectedDocumentID: ShowcaseDocument.ID?
    let onOpenFiles: () -> Void
    let onDropFiles: ([URL]) -> Void
    let onClearAll: () -> Void
    let onCloseDocument: (ShowcaseDocument.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            uploadCard

            HStack {
                Text("\(documents.count) file\(documents.count == 1 ? "" : "s")")
                    .font(.headline)
                Spacer()
                if !documents.isEmpty {
                    Button("Clear All", role: .destructive, action: onClearAll)
                        .buttonStyle(.plain)
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(documents) { document in
                        SidebarDocumentRow(
                            document: document,
                            isSelected: selectedDocumentID == document.id,
                            onClose: { onCloseDocument(document.id) }
                        )
                        .onTapGesture {
                            selectedDocumentID = document.id
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .toolbar {
            ToolbarItem {
                Button(action: onOpenFiles) {
                    Label("Open", systemImage: "folder")
                }
                .keyboardShortcut("o", modifiers: .command)
                .help("Open one or more subtitle files.")
            }
        }
    }

    private var uploadCard: some View {
        Button(action: onOpenFiles) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "tray.and.arrow.up")
                        .font(.title3.weight(.semibold))
                    Text("Open Subtitle Files")
                        .font(.headline)
                }
                Text("Drag & drop or click. Supports SRT, VTT, ASS, SSA, SBV, SUB, LRC, SMI, JSON.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.quaternary.opacity(0.35))
            )
        }
        .buttonStyle(.plain)
        .dropDestination(for: URL.self) { urls, _ in
            onDropFiles(urls)
            return true
        }
    }
}
