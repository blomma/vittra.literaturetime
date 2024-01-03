import SwiftData
import SwiftUI

extension ModelContainer {
    static let productionContainer: ModelContainer = {
        do {
            guard let storeURL = Bundle.main.url(
                forResource: "literatureTimes",
                withExtension: "store"
            ) else {
                fatalError("Failed to find literatureTimes.store")
            }

            let schema = Schema([Database.LiteratureTime.self])
            let configuration = ModelConfiguration(url: storeURL, allowsSave: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }()

    static let previewContainer: ModelContainer = {
        do {
            let schema = Schema([Database.LiteratureTime.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])

            Task { @MainActor in
                container.mainContext.insert(Database.LiteratureTime(
                    time: "",
                    quoteFirst: "“Time is an illusion. Lunchtime doubly so.”",
                    quoteTime: "",
                    quoteLast: "",
                    title: "The Hitchhiker's Guide to the Galaxy",
                    author: "Douglas Adams",
                    gutenbergReference: "",
                    id: ""
                ))
            }

            return container
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }()
}
