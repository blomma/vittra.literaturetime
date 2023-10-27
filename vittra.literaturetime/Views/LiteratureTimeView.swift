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
        initialState: .init(literatureTime: LiteratureTime.emptyFallback),
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
                        Text(store.literatureTime.quoteFirst)
                            + Text(store.literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(store.literatureTime.quoteLast)
                    }
                    .font(.system(.title, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(store.literatureTime.title), ")
                            + Text(store.literatureTime.author)
                            + Text("   \(store.literatureTime.gutenbergReference)")
                            .italic()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .animation(.easeInOut(duration: 0.5), value: store.literatureTime)
                .padding(25)
                .padding(.top, 10)
                .allowsTightening(false)
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = store.literatureTime.description
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

#Preview {
    LiteratureTimeView(store: .init(
        initialState: .init(literatureTime: LiteratureTime.emptyFallback),
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .preview)]
    ))
    .modelContainer(ModelContexts.previewContainer)
}
