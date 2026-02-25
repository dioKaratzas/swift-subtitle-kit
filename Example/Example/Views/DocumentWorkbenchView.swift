//
//  SubtitleKit
//  A Swift 6 library for parsing, converting, resyncing, and saving subtitle files.
//

import SwiftUI

struct DocumentWorkbenchView: View {
    @Binding var document: ShowcaseDocument
    @State var isResyncSheetPresented = false
    let pane: WorkbenchPane
    let onPreviewFullDiff: (ShowcaseDocument) -> Void

    var body: some View {
        switch pane {
        case .subtitles:
            VStack(spacing: 12) {
                headerCard
                cueTableCard
                cueInspectorCard
            }
        case .cleaning:
            ScrollView {
                VStack(spacing: 12) {
                    headerCard
                    cleanOptionsCard
                    diffPreviewCard
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.bottom, 2)
            }
        }
    }
}
