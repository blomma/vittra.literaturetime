import Models
import SwiftUI

struct QuoteContextMenu: View {
    let literatureTime: LiteratureTime
    @Binding
    var shouldPresentSettings: Bool

    /// Invoked after a copy action places text on the pasteboard, so the host
    /// can confirm the otherwise-silent action (e.g. with haptic feedback).
    var onCopy: () -> Void = {}

    /// Invoked when the user requests a new quote. The host owns the asynchronous
    /// refresh so this menu can be shared by both `Menu` and `contextMenu`.
    var onRefresh: () -> Void = {}

    private var gutenbergURL: URL? {
        guard !literatureTime.gutenbergReference.isEmpty else { return nil }
        return URL(string: "https://www.gutenberg.org/ebooks/\(literatureTime.gutenbergReference)")
    }

    var body: some View {
        ShareLink(item: literatureTime.quotation) {
            Label("Share quote", systemImage: "square.and.arrow.up")
        }

        Button("Copy quote", systemImage: "doc.on.doc", action: copyQuote)

        Button("Refresh quote", systemImage: "arrow.clockwise", action: onRefresh)

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
        UIPasteboard.general.string = literatureTime.quotation
        AccessibilityNotification.Announcement("Quote copied").post()
        onCopy()
    }

    private func copyGutenbergLink() {
        guard let gutenbergURL else { return }
        UIPasteboard.general.string = gutenbergURL.absoluteString
        AccessibilityNotification.Announcement("Link copied").post()
        onCopy()
    }

    private func presentSettings() {
        shouldPresentSettings = true
    }
}
