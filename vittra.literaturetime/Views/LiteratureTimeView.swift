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
    @State var store = LiteratureTimeViewStore(
        initialState: .empty,
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    Group {
                        Text(store.quoteFirst)
                            + Text(store.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(store.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(store.title), ")
                            + Text(store.author)
                            .italic()
                            + Text("   \(store.gutenbergReference)")
                    }
                    .padding(.top, 15)
                    .padding(.leading, 25)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .foregroundStyle(.literature)
                .contextMenu {
                    contextMenu
                }
            }
            .padding(25)
            .foregroundStyle(.literature)
        }
        .task {
            guard let query = createQuery() else {
                return
            }

            await store.send(.searchRandom(query: query))
        }
        .refreshable {
            guard let query = createQuery() else {
                return
            }

            await store.send(.searchRandom(query: query))
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button {
            UIPasteboard.general.string = store.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }
        Link(
            destination: URL(string: "https://www.gutenberg.org/ebooks/\(store.gutenbergReference)")!)
        {
            Label("View book on gutenberg", systemImage: "lock")
        }
    }
}

#Preview {
    LiteratureTimeView(store: .init(
        initialState: .empty,
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .preview)]
    ))
    .modelContainer(ModelContexts.previewContainer)
}
