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
                        Text("- \(model.title), ")
                            + Text(model.author)
                            .italic()
                            + Text("   \(model.gutenbergReference)")
                    }
                    .padding(.top, 15)
                    .padding(.leading, 25)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .padding(15)
                .foregroundStyle(.literature)
                .contextMenu {
                    makeContextMenu
                }
            }
            .padding(15)
            .foregroundStyle(.literature)
        }
        .task {
            await model.fetchRandomQuote()
        }
        .refreshable {
            await model.fetchRandomQuote()
        }
    }

    @MainActor
    @ViewBuilder
    private var makeContextMenu: some View {
        Button {
            UIPasteboard.general.string = model.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }
        Link(
            destination: URL(string: "https://www.gutenberg.org/ebooks/\(model.gutenbergReference)")!)
        {
            Label("View book on gutenberg", systemImage: "book")
        }
    }
}

extension LiteratureTimeView {
    @MainActor
    @Observable @dynamicMemberLookup
    final class ViewModel {
        private var state: LiteratureTime
        private var provider: LiteratureTimeViewProviding

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

        func fetchRandomQuote() async {
            let actorQueueLabel = DispatchQueue.currentLabel
            print("Actor1 queue:", actorQueueLabel)

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
    }
}

#Preview {
    LiteratureTimeView(model: .init(
        initialState: .empty,
        provider: LiteratureTimeProviderPreview()
    ))
}
