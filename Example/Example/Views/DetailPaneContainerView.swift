//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SwiftUI

struct DetailPaneContainerView: View {
    @Binding var selectedDocument: ShowcaseDocument?
    @Binding var selectedPane: WorkbenchPane
    let onOpenFiles: () -> Void
    let onPreviewFullDiff: (ShowcaseDocument) -> Void

    var body: some View {
        Group {
            if let documentBinding = bindingToDocument {
                DocumentWorkbenchView(
                    document: documentBinding,
                    pane: selectedPane,
                    onPreviewFullDiff: onPreviewFullDiff
                )
                .padding(14)
            } else {
                EmptyWorkbenchView(onOpen: onOpenFiles)
                    .padding(20)
            }
        }
    }

    private var bindingToDocument: Binding<ShowcaseDocument>? {
        guard let snapshot = selectedDocument else {
            return nil
        }
        return Binding(
            get: { selectedDocument ?? snapshot },
            set: { selectedDocument = $0 }
        )
    }
}
