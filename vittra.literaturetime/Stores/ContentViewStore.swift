import Mimer
import SwiftData
import SwiftUI

struct LiteratureTimeImport: Equatable, Decodable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
    var gutenbergReference: String
    var hash: String
}

struct ContentViewState: Equatable {
    var isLoading = true
}

enum ContentViewAction: Equatable {
    case load
    case loadDone
}

struct ContentViewReducer: Reducer {
    func reduce(oldState: ContentViewState, with action: ContentViewAction) -> ContentViewState {
        var state = oldState

        switch action {
        case .loadDone:
            state.isLoading = false
        case .load:
            state.isLoading = true
        }

        return state
    }
}

struct ContentViewMiddleware: Middleware {
    struct Dependencies {
        var load: () async throws -> [LiteratureTimeImport]
        var modelContainer: ModelContainer

        static var production: Dependencies {
            .init(load: {
                guard let file = Bundle.main.path(forResource: "literature", ofType: "json")
                else {
                    return .init([])
                }

                let data = try String(contentsOfFile: file).data(using: .utf8)

                guard let data = data
                else {
                    return .init([])
                }

                return try JSONDecoder().decode([LiteratureTimeImport].self, from: data)

            }, modelContainer: ModelContexts.productionContainer)
        }
    }

    let dependencies: Dependencies

    func process(state _: ContentViewState, with action: ContentViewAction) async -> ContentViewAction? {
        switch action {
        case .load:
            let defaults = UserDefaults.standard

            if defaults.bool(forKey: "v3") { return .loadDone }

            let results = try? await dependencies.load()
            guard let results = results else {
                return .loadDone
            }

            let modelContext = ModelContext(dependencies.modelContainer)
            do {
                try modelContext.delete(model: LiteratureTime.self)
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
            
            for value in results {
                let literatureTime = LiteratureTime(
                    time: value.time,
                    quoteFirst: value.quoteFirst,
                    quoteTime: value.quoteTime,
                    quoteLast: value.quoteLast,
                    title: value.title,
                    author: value.author,
                    gutenbergReference: value.gutenbergReference,
                    id: value.hash
                )

                modelContext.insert(literatureTime)
            }

            do {
                try modelContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }

            defaults.setValue(true, forKey: "v3")

            return .loadDone

        default:
            return nil
        }
    }
}

typealias ContentViewStore = Store<ContentViewState, ContentViewAction>
