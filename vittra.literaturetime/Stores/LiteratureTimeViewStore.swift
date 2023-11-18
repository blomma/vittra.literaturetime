import CoreData
import Mimer
import SwiftData

struct LiteratureTimeViewState: Equatable {
    var viewModel: LiteratureTimeView.ViewModel
}

enum LiteratureTimeViewAction: Equatable {
    case searchRandom(query: String)
    case setResults(literatureTime: LiteratureTimeView.ViewModel)
    case setFallback
}

struct LiteratureTimeViewReducer: Reducer {
    func reduce(oldState: LiteratureTimeViewState, with action: LiteratureTimeViewAction) -> LiteratureTimeViewState {
        var state = oldState

        switch action {
        case let .setResults(literatureTime):
            state.viewModel = literatureTime
        case .setFallback:
            state.viewModel = .fallback
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

            return .setResults(literatureTime: LiteratureTimeView.ViewModel(
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
