import SwiftData
import SwiftUI

func createQuery() -> String? {
    let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

    guard let hour = hm.hour, let minute = hm.minute else {
        return nil
    }

    let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
    let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

    return "\(paddedHour):\(paddedMinute)"
}

struct LiteratureTimeView: View {
    @Environment(\.scenePhase) var scenePhase
    @State var model = ViewModel(
        initialState: .empty,
        provider: LiteratureTimeProvider()
    )

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
                    contextMenu
                }
            }
            .padding(15)
            .foregroundStyle(.literature)
        }
        .task {
            guard let query = createQuery() else {
                return
            }

            model.search(query: query)
        }
        .refreshable {
            guard let query = createQuery() else {
                return
            }

            model.search(query: query)
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
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
    @Observable @dynamicMemberLookup
    public final class ViewModel {
        private var state: LiteratureTimeViewState
        private var provider: LiteratureTimeViewProviding

        public init(
            initialState state: LiteratureTimeViewState,
            provider: LiteratureTimeViewProviding
        ) {
            self.state = state
            self.provider = provider
        }

        public subscript<T>(dynamicMember keyPath: KeyPath<LiteratureTimeViewState, T>) -> T {
            state[keyPath: keyPath]
        }

        func search(query: String) {
            let literatureTime = try? provider.search(query: query)

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
