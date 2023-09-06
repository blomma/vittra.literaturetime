import CoreData
import Mimer
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

struct LiteratureTimeModel: Equatable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
}

struct LiteratureTimeState: Equatable {
    var literatureTime: LiteratureTimeModel
}

enum LiteratureTimeAction: Equatable {
    case searchRandom(query: String)
    case setResults(literatureTime: LiteratureTimeModel)
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
        var search: (String) async throws -> LiteratureTimeModel?

        static var production: Dependencies {
            .init { query in
                let context = PersistenceController.shared.container.viewContext

                let fetchRequest = NSFetchRequest<LiteratureTime>(entityName: "\(LiteratureTime.self)")
                fetchRequest.predicate = NSPredicate(format: "(%K == %@)", argumentArray: ["time", query])

                guard let fetchRequestCount = try? context.count(for: fetchRequest) else {
                    return nil
                }

                fetchRequest.fetchOffset = Int.random(in: 0 ... fetchRequestCount)
                fetchRequest.fetchLimit = 1

                var fetchResults: [LiteratureTime]?
                context.performAndWait {
                    fetchResults = try? fetchRequest.execute()
                }

                guard let fetchResults = fetchResults else {
                    return nil
                }

                guard fetchResults.count > 0 else {
                    return nil
                }

                guard
                    let literatureTime = fetchResults.first,
                    let time = literatureTime.time,
                    let quoteFirst = literatureTime.quoteFirst,
                    let quoteTime = literatureTime.quoteTime,
                    let quoteLast = literatureTime.quoteLast,
                    let title = literatureTime.title,
                    let author = literatureTime.author
                else {
                    return nil
                }

                return LiteratureTimeModel(time: time, quoteFirst: quoteFirst, quoteTime: quoteTime, quoteLast: quoteLast, title: title, author: author)
            }
        }

        static var preview: Dependencies {
            .init { _ in
                nil
            }
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
                return .setResults(literatureTime: state.literatureTime)
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
        initialState: .init(
            literatureTime:
            LiteratureTimeModel(
                time: "",
                quoteFirst: "“Time is an illusion. Lunchtime doubly so.”",
                quoteTime: "",
                quoteLast: "",
                title: "The Hitchhiker's Guide to the Galaxy",
                author: "Douglas Adams"
            )),
        reducer: LiteratureTimeReducer(),
        middlewares: [LiteratureTimeMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(store.literatureTime.quoteFirst)
                            + Text(store.literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(store.literatureTime.quoteLast)
                    }
                    .font(.system(.largeTitle, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(store.literatureTime.title), ")
                            + Text(store.literatureTime.author)
                            .italic()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .padding(10)
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

            let fileName = "\(paddedHour):\(paddedMinute)"

            await store.send(.searchRandom(query: fileName))
        }
        .refreshable {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let fileName = "\(paddedHour):\(paddedMinute)"

            await store.send(.searchRandom(query: fileName))
        }
    }
}

#Preview {
    LiteratureTimeView(store: .init(
        initialState: .init(
            literatureTime:
            LiteratureTimeModel(
                time: "",
                quoteFirst: "“Time is an illusion. Lunchtime doubly so.”",
                quoteTime: "",
                quoteLast: "",
                title: "The Hitchhiker's Guide to the Galaxy",
                author: "Douglas Adams"
            )),
        reducer: LiteratureTimeReducer(),
        middlewares: [LiteratureTimeMiddleware(dependencies: .production)]
    ))
}
