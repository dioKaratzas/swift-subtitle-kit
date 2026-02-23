//
//  SubsTranslatorBackend
//  Subtitle translation backend.
//

import SwiftUI

enum WorkbenchPane: String, CaseIterable, Identifiable {
    case subtitles
    case cleaning

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .subtitles: return "Subtitles"
        case .cleaning: return "Clean"
        }
    }

    var systemImage: String {
        switch self {
        case .subtitles: return "tablecells"
        case .cleaning: return "wand.and.stars"
        }
    }
}

struct ContentView: View {
    @StateObject private var model = ShowcaseAppModel()
    @State private var selectedPane = WorkbenchPane.subtitles

    var body: some View {
        NavigationSplitView {
            SidebarPaneView(
                documents: model.documents,
                selectedDocumentID: $model.selectedDocumentID,
                onOpenFiles: model.openFiles,
                onDropFiles: model.open(urls:),
                onClearAll: model.clearAllDocuments,
                onCloseDocument: model.closeDocument(id:)
            )
        } detail: {
            DetailPaneContainerView(
                selectedDocument: selectedDocumentOptionalBinding,
                selectedPane: $selectedPane,
                onOpenFiles: model.openFiles,
                onPreviewFullDiff: model.presentFullDiff(for:)
            )
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1180, minHeight: 760)
        .toolbar {
            toolbarContent
        }
        .sheet(item: $model.fullDiffSheet) { sheet in
            FullDiffSheetView(model: sheet)
                .frame(minWidth: 1000, minHeight: 640)
        }
        .alert(
            "SubtitleKit Example",
            isPresented: Binding(
                get: { model.alertMessage != nil },
                set: { if !$0 {
                    model.clearAlert()
                } }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(model.alertMessage ?? "Unknown error")
            }
        )
    }

    @ToolbarContentBuilder private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button(action: model.saveSelectedDocument) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
            .labelStyle(.iconOnly)
            .keyboardShortcut("s", modifiers: .command)
            .disabled(model.selectedDocumentIndex == nil || !selectedDocumentIsDirty)
            .help(
                "Save changes to the current file path. If there is no file path yet, you will be prompted to choose one."
            )

            Button(action: model.exportSelectedDocument) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)
            .keyboardShortcut("S", modifiers: [.command, .shift])
            .disabled(model.selectedDocumentIndex == nil)
            .help("Export the current subtitle to another file path and format without changing the open document.")
        }

        ToolbarItemGroup(placement: .principal) {
            Picker("View", selection: $selectedPane) {
                Text("Subtitles").tag(WorkbenchPane.subtitles)
                Text("Clean").tag(WorkbenchPane.cleaning)
            }
            .labelsHidden()
            .pickerStyle(.segmented)
            .controlSize(.small)
            .frame(width: 170)
            .disabled(model.selectedDocumentIndex == nil)
            .help("Switch between subtitle editing and cleaning/diff tools.")
        }
    }

    private var selectedDocumentOptionalBinding: Binding<ShowcaseDocument?> {
        Binding(
            get: {
                guard let index = model.selectedDocumentIndex else {
                    return nil
                }
                return model.documents[index]
            },
            set: { newValue in
                guard let index = model.selectedDocumentIndex, let newValue else {
                    return
                }
                model.documents[index] = newValue
            }
        )
    }

    private var selectedDocumentIsDirty: Bool {
        guard let index = model.selectedDocumentIndex else {
            return false
        }
        return model.documents[index].isDirty
    }
}

#Preview {
    ContentView()
}
