import SwiftData
import SwiftUI

struct LiteratureTimeView: View {
    @Environment(\.scenePhase) var scenePhase
    @State var model: ViewModel

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    Group {
                        Text(model.quoteFirst)
                            + Text(model.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(model.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(model.title), \(Text(model.author).italic())")
                    }
                    .padding(.top, 15)
                    .padding(.leading, 25)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .padding(15)
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                .contextMenu {
                    makeContextMenu
                }
            }
            .padding(15)
            .foregroundStyle(.literature)
            .task {
                await model.fetchQuote()
            }
            .refreshable {
                await model.refreshQuote()
            }
        }
    }

    @MainActor
    @ViewBuilder
    private var makeContextMenu: some View {
        Button {
            UIPasteboard.general.string = model.description
        } label: {
            Label("Copy quote to clipboard", systemImage: "doc.on.doc")
        }

        if model.gutenbergReference != "" {
            Link(
                destination: URL(string: "https://www.gutenberg.org/ebooks/\(model.gutenbergReference)")!)
            {
                Label("View book on gutenberg", systemImage: "book")
            }
        }
    }
}

extension LiteratureTimeView {
    @MainActor
    @Observable @dynamicMemberLookup
    final class ViewModel {
        @ObservationIgnored
        @AppStorage("literatureTimeId") 
        private var literatureTimeId = ""

        private var state: LiteratureTime
        private let provider: LiteratureTimeViewProviding

        public init(
            initialState state: LiteratureTime,
            provider: LiteratureTimeViewProviding
        ) {
            self.state = state
            self.provider = provider
        }

        public subscript<T>(dynamicMember keyPath: KeyPath<LiteratureTime, T>) -> T {
            state[keyPath: keyPath]
        }

        func refreshQuote() async {
            await fetchRandomQuote()

            if !state.id.isEmpty {
                literatureTimeId = state.id
            }
        }

        func fetchQuote() async {
            if !literatureTimeId.isEmpty {
                await fetchQuoteFrom(Id: literatureTimeId)
            }

            if !state.id.isEmpty {
                return
            }

            await fetchRandomQuote()
            if !state.id.isEmpty {
                literatureTimeId = state.id
            }
        }

        private func fetchRandomQuote() async {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                state = .fallback
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            let literatureTime = try? await provider.search(query: query)

            guard let literatureTime = literatureTime else {
                state = .fallback
                return
            }

            state = literatureTime
        }

        private func fetchQuoteFrom(Id: String) async {
            let literatureTime = try? await provider.searchFor(Id: Id)

            guard let literatureTime = literatureTime else {
                state = .fallback
                return
            }

            state = literatureTime
        }
    }
}

#Preview {
    LiteratureTimeView(model: .init(
        initialState: .empty,
        provider: LiteratureTimeProviderPreview()
    ))
}
