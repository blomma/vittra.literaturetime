import Models
import SwiftUI

struct QuoteContextMenu: View {
    let literatureTime: LiteratureTime
    @Binding
    var shouldPresentSettings: Bool

    private var gutenbergURL: URL? {
        guard !literatureTime.gutenbergReference.isEmpty else { return nil }
        return URL(string: "https://www.gutenberg.org/ebooks/\(literatureTime.gutenbergReference)")
    }

    var body: some View {
        Button("Copy quote", systemImage: "doc.on.doc", action: copyQuote)

        if let gutenbergURL {
            Link(destination: gutenbergURL) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button("Copy link to gutenberg", systemImage: "link", action: copyGutenbergLink)
        }

        Divider()

        Button("Settings", systemImage: "gearshape", action: presentSettings)
    }

    private func copyQuote() {
        UIPasteboard.general.string = literatureTime.description
    }

    private func copyGutenbergLink() {
        guard let gutenbergURL else { return }
        UIPasteboard.general.string = gutenbergURL.absoluteString
    }

    private func presentSettings() {
        shouldPresentSettings = true
    }
}
