import Models
import SwiftUI

struct QuoteContextMenu: View {
    let literatureTime: LiteratureTime
    @Binding
    var shouldPresentSettings: Bool

    var body: some View {
        Button {
            UIPasteboard.general.string = literatureTime.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }

        if !literatureTime.gutenbergReference.isEmpty {
            Link(
                destination: URL(
                    string: "https://www.gutenberg.org/ebooks/\(literatureTime.gutenbergReference)"
                )!
            ) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string =
                    "https://www.gutenberg.org/ebooks/\(literatureTime.gutenbergReference)"
            } label: {
                Label("Copy link to gutenberg", systemImage: "link")
            }
        }

        Divider()

        Button {
            shouldPresentSettings.toggle()
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }
}
