import Mimer
import SwiftUI

struct LiteratureTimeResponse: Equatable, Decodable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
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
        case .load:
            state.isLoading = true
        case .loadDone:
            state.isLoading = false
        }

        return state
    }
}

struct ContentViewMiddleware: Middleware {
    struct Dependencies {
        var load: () async throws -> [LiteratureTimeResponse]

        static var production: Dependencies {
            .init {
                guard let file = Bundle.main.path(forResource: "response_1693600338832", ofType: "json")
                else {
                    return .init([])
                }

                let data = try String(contentsOfFile: file).data(using: .utf8)

                guard let data = data
                else {
                    return .init([])
                }

                return try JSONDecoder().decode([LiteratureTimeResponse].self, from: data)
            }
        }
    }

    let dependencies: Dependencies

    func process(state _: ContentViewState, with action: ContentViewAction) async -> ContentViewAction? {
        switch action {
        case .load:
            let defaults = UserDefaults.standard

            if defaults.bool(forKey: "v1") { return .loadDone }

            let results = try? await dependencies.load()
            guard let results = results else {
                return .loadDone
            }

            guard !Task.isCancelled else {
                return .loadDone
            }

            let context = PersistenceController.shared.container.newBackgroundContext()
            context.performAndWait {
                for value in results {
                    let literaturetime = LiteratureTime(context: context)
                    literaturetime.author = value.author
                    literaturetime.title = value.title
                    literaturetime.quoteFirst = value.quoteFirst
                    literaturetime.quoteTime = value.quoteTime
                    literaturetime.quoteLast = value.quoteLast
                    literaturetime.time = value.time
                    literaturetime.id = value.hash
                }

                do {
                    try context.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }

            defaults.setValue(true, forKey: "v1")

            return .loadDone

        default:
            return nil
        }
    }
}

typealias ContentViewStore = Store<ContentViewState, ContentViewAction>

struct ContentView: View {
    @State private var store = ContentViewStore(
        initialState: .init(),
        reducer: ContentViewReducer(),
        middlewares: [ContentViewMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            if !store.isLoading {
                LiteratureTimeView()
            }
        }
        .task {
            await store.send(.load)
        }
    }
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
