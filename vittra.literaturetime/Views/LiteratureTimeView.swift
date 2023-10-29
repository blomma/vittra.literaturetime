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
        initialState: .init(viewModel: .empty),
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(store.viewModel.quoteFirst)
                            + Text(store.viewModel.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(store.viewModel.quoteLast)
                    }
                    .font(.system(.title, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(store.viewModel.title), ")
                            + Text(store.viewModel.author)
                            + Text("   \(store.viewModel.gutenbergReference)")
                            .italic()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .animation(.easeInOut(duration: 0.5), value: store.viewModel)
                .padding(25)
                .padding(.top, 10)
                .allowsTightening(false)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = store.viewModel.description
                    } label: {
                        Label("Copy quote", systemImage: "heart")
                    }
                }
            }
            .foregroundStyle(.literature)
        }
        .task {
            guard let query = createQuery() else {
                return
            }

            await store.send(.searchRandom(query: query))
        }
//        .onChange(of: scenePhase, initial: true) { _, newValue in
//            if newValue == .active {
//                Task {
//                    guard let query = createQuery() else {
//                        return
//                    }
//
//                    await store.send(.searchRandom(query: query))
//                }
//            }
//        }
        .refreshable {
            guard let query = createQuery() else {
                return
            }

            await store.send(.searchRandom(query: query))
        }
    }
}

extension LiteratureTimeView {
    struct ViewModel: Equatable {
        var time: String
        var quoteFirst: String
        var quoteTime: String
        var quoteLast: String
        var title: String
        var author: String
        var gutenbergReference: String
        var id: String

        init(time: String, quoteFirst: String, quoteTime: String, quoteLast: String, title: String, author: String, gutenbergReference: String, id: String) {
            self.time = time
            self.quoteFirst = quoteFirst
            self.quoteTime = quoteTime
            self.quoteLast = quoteLast
            self.title = title
            self.author = author
            self.gutenbergReference = gutenbergReference
            self.id = id
        }
    }
}

extension LiteratureTimeView.ViewModel: CustomStringConvertible {
    var description: String {
        return """
        \(quoteFirst)\(quoteTime)\(quoteLast)

        - \(title), \(author), \(gutenbergReference)
        """
    }
}

extension LiteratureTimeView.ViewModel {
    static var fallback: LiteratureTimeView.ViewModel {
        LiteratureTimeView.ViewModel(
            time: "",
            quoteFirst: "“Time is an illusion. Lunchtime doubly so.”",
            quoteTime: "",
            quoteLast: "",
            title: "The Hitchhiker's Guide to the Galaxy",
            author: "Douglas Adams",
            gutenbergReference: "",
            id: ""
        )
    }

    static var empty: LiteratureTimeView.ViewModel {
        LiteratureTimeView.ViewModel(
            time: "",
            quoteFirst: "",
            quoteTime: "",
            quoteLast: "",
            title: "",
            author: "",
            gutenbergReference: "",
            id: ""
        )
    }
}

#Preview {
    LiteratureTimeView(store: .init(
        initialState: .init(viewModel: .empty),
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .preview)]
    ))
    .modelContainer(ModelContexts.previewContainer)
}
