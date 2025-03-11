import Foundation
import Models
import SwiftData

public final class ModelProvider: Sendable {
    public static let shared = ModelProvider()

    public let productionContainer: ModelContainer = {
        do {
            guard
                let storeURL = Bundle.main.url(
                    forResource: "literatureTimes",
                    withExtension: "store",
                    subdirectory: "Quotes"
                )
            else {
                fatalError("Failed to find literatureTimes.store")
            }

            let schema = Schema(CurrentScheme.models)
            let configuration = ModelConfiguration(url: storeURL, allowsSave: false)
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }()

    public let previewContainer: ModelContainer = {
        do {
            let schema = Schema(CurrentScheme.models)
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])

            return container
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }()
}
