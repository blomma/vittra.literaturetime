import CoreData
import Mimer
import SwiftData

struct LiteratureTimeViewState: Equatable {
    var literatureTime: LiteratureTime?
}

enum LiteratureTimeViewAction: Equatable {
    case searchRandom(query: String)
    case setResults(literatureTime: LiteratureTime?)
}

struct LiteratureTimeViewReducer: Reducer {
    func reduce(oldState: LiteratureTimeViewState, with action: LiteratureTimeViewAction) -> LiteratureTimeViewState {
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

struct LiteratureTimeViewMiddleware: Middleware {
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

    func process(state: LiteratureTimeViewState, with action: LiteratureTimeViewAction) async -> LiteratureTimeViewAction? {
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

typealias LiteratureTimeViewStore = Store<LiteratureTimeViewState, LiteratureTimeViewAction>

