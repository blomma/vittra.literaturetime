import CoreData
import Mimer
import SwiftData

struct LiteratureTimeViewState: Equatable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
    var gutenbergReference: String
    var id: String
}

extension LiteratureTimeViewState: CustomStringConvertible {
    var description: String {
        return """
        \(quoteFirst)\(quoteTime)\(quoteLast)

        - \(title), \(author), \(gutenbergReference)
        """
    }
}

extension LiteratureTimeViewState {
    static var fallback: LiteratureTimeViewState {
        LiteratureTimeViewState(
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

    static var empty: LiteratureTimeViewState {
        LiteratureTimeViewState(
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


enum LiteratureTimeViewAction: Equatable {
    case searchRandom(query: String)
    case setResults(literatureTime: LiteratureTimeViewState)
    case setFallback
}

struct LiteratureTimeViewReducer: Reducer {
    func reduce(oldState: LiteratureTimeViewState, with action: LiteratureTimeViewAction) -> LiteratureTimeViewState {
        var state = oldState

        switch action {
        case let .setResults(literatureTime):
            state = literatureTime
        case .setFallback:
            state = .fallback
        default:
            return state
        }

        return state
    }
}

struct LiteratureTimeViewMiddleware: Middleware {
    struct Dependencies {
        let search: (String) async throws -> LiteratureTime?

        static var production: Dependencies {
            .init(search: { query in
                var descriptor = FetchDescriptor<LiteratureTime>()
//                descriptor.predicate = #Predicate { item in
//                    item.time == query
//                }

                let modelContext = ModelContext(ModelContexts.productionContainer)
                guard let literatureTimeCount = try? modelContext.fetchCount(descriptor), literatureTimeCount > 0 else {
                    return nil
                }

                descriptor.fetchLimit = 1
                descriptor.fetchOffset = Int.random(in: 0 ... literatureTimeCount - 1)

                guard let literatureTimes = try? modelContext.fetch(descriptor), let literatureTime = literatureTimes.first else {
                    return nil
                }

                return literatureTime
            })
        }

        static var preview: Dependencies {
            .init(search: { _ in
                nil
            })
        }
    }

    let dependencies: Dependencies

    func process(state _: LiteratureTimeViewState, with action: LiteratureTimeViewAction) async -> LiteratureTimeViewAction? {
        switch action {
        case let .searchRandom(query):
            let result = try? await dependencies.search(query)

            guard let result = result else {
                return .setFallback
            }

            return .setResults(literatureTime: LiteratureTimeViewState(
                time: result.time,
                quoteFirst: result.quoteFirst.replacingOccurrences(of: "\n", with: " "),
                quoteTime: result.quoteTime.replacingOccurrences(of: "\n", with: " "),
                quoteLast: result.quoteLast.replacingOccurrences(of: "\n", with: " "),
                title: result.title,
                author: result.author,
                gutenbergReference: result.gutenbergReference,
                id: result.id
            ))
        default:
            return nil
        }
    }
}

typealias LiteratureTimeViewStore = Store<LiteratureTimeViewState, LiteratureTimeViewAction>
