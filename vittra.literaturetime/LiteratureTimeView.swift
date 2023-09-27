import CoreData
import Mimer
import SwiftData
import SwiftUI

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(suffix(toLength))
        }
    }
}

struct LiteratureTimeState: Equatable {
    var literatureTime: LiteratureTime?
}

enum LiteratureTimeAction: Equatable {
    case searchRandom(query: String)
    case setResults(literatureTime: LiteratureTime?)
}

struct LiteratureTimeReducer: Reducer {
    func reduce(oldState: LiteratureTimeState, with action: LiteratureTimeAction) -> LiteratureTimeState {
        var state = oldState

        switch action {
        case let .setResults(literatureTime):
            state.literatureTime = literatureTime
        default:
            return state
        }

        return state
    }
}

struct LiteratureTimeMiddleware: Middleware {
    struct Dependencies {
        let search: (String) async throws -> LiteratureTime?

        static var production: Dependencies {
            .init(search: { query in
                var descriptor = FetchDescriptor<LiteratureTime>()
                descriptor.predicate = #Predicate { item in
                    item.time == query
                }

                let modelContext = ModelContext(ModelContexts.productionContainer)
                guard let literatureTimeCount = try? modelContext.fetchCount(descriptor), literatureTimeCount > 0 else {
                    return nil
                }

                descriptor.fetchLimit = 1
                descriptor.fetchOffset = Int.random(in: 0 ... literatureTimeCount - 1)

                guard let literatureTimes = try? modelContext.fetch(descriptor), let literatureTime = literatureTimes.first else {
                    return nil
                }

                return LiteratureTime(
                    time: literatureTime.time,
                    quoteFirst: literatureTime.quoteFirst,
                    quoteTime: literatureTime.quoteTime,
                    quoteLast: literatureTime.quoteLast,
                    title: literatureTime.title,
                    author: literatureTime.author,
                    id: literatureTime.id
                )
            })
        }

        static var preview: Dependencies {
            .init(search: { query in
                var descriptor = FetchDescriptor<LiteratureTime>()
                descriptor.predicate = #Predicate { item in
                    item.time == query
                }

                let modelContext = ModelContext(ModelContexts.previewContainer)
                guard let literatureTimeCount = try? modelContext.fetchCount(descriptor), literatureTimeCount > 0 else {
                    return nil
                }

                descriptor.fetchLimit = 1
                descriptor.fetchOffset = Int.random(in: 0 ... literatureTimeCount - 1)

                guard let literatureTimes = try? modelContext.fetch(descriptor), let literatureTime = literatureTimes.first else {
                    return nil
                }

                return LiteratureTime(
                    time: literatureTime.time,
                    quoteFirst: literatureTime.quoteFirst,
                    quoteTime: literatureTime.quoteTime,
                    quoteLast: literatureTime.quoteLast,
                    title: literatureTime.title,
                    author: literatureTime.author,
                    id: literatureTime.id
                )
            })
        }
    }

    let dependencies: Dependencies

    func process(state: LiteratureTimeState, with action: LiteratureTimeAction) async -> LiteratureTimeAction? {
        switch action {
        case let .searchRandom(query):
            let results = try? await dependencies.search(query)

            guard !Task.isCancelled else {
                return .setResults(literatureTime: state.literatureTime)
            }

            guard let results = results else {
                return .setResults(literatureTime: LiteratureTime.fallback)
            }

            return .setResults(literatureTime: results)
        default:
            return nil
        }
    }
}

typealias LiteratureTimeStore = Store<LiteratureTimeState, LiteratureTimeAction>

struct LiteratureTimeView: View {
    @State var store = LiteratureTimeStore(
        initialState: .init(),
        reducer: LiteratureTimeReducer(),
        middlewares: [LiteratureTimeMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading) {
                    
                    let literatureTime = store.literatureTime ?? LiteratureTime.fallback
                    
                    VStack(alignment: .leading) {
                        Text(literatureTime.quoteFirst)
                            + Text(literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(literatureTime.quoteLast)
                    }
                    .font(.system(.title, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(literatureTime.title), ")
                            + Text(literatureTime.author)
                            .italic()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .padding(25)
                .padding(.top, 10)
                .allowsTightening(false)
            }
            .foregroundStyle(.literature)
        }
        .task {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            await store.send(.searchRandom(query: query))
        }
        .refreshable {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            await store.send(.searchRandom(query: query))
        }
    }
}

#Preview {
    LiteratureTimeView(store: .init(
        initialState: .init(),
        reducer: LiteratureTimeReducer(),
        middlewares: [LiteratureTimeMiddleware(dependencies: .preview)]
    ))
    .modelContainer(ModelContexts.previewContainer)
}
