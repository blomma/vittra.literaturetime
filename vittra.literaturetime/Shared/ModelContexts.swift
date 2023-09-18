import SwiftData
import SwiftUI

struct ModelContexts {
    static let productionContainer: ModelContainer = {
        do {
            let schema = Schema([LiteratureTime.self])
            let configuration = ModelConfiguration()
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }()

    static let previewContainer: ModelContainer = {
        do {
            let schema = Schema([LiteratureTime.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            Task { @MainActor in
                container.mainContext.insert(LiteratureTime(
                    time: "",
                    quoteFirst: "“Time is an illusion. Lunchtime doubly so.”",
                    quoteTime: "",
                    quoteLast: "",
                    title: "The Hitchhiker's Guide to the Galaxy",
                    author: "Douglas Adams",
                    id: ""
                ))
            }
            
            return container
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }()

//    static var previewContainer: () throws -> ModelContainer = {
//        let schema = Schema([LiteratureTime.self])
//        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
//        let container = try! ModelContainer(for: schema, configurations: [configuration])
    ////        let sampleData: [any PersistentModel] = [
    ////            Trip.preview, BucketListItem.preview, LivingAccommodation.preview
    ////        ]
    ////        Task { @MainActor in
    ////            sampleData.forEach {
    ////                container.mainContext.insert($0)
    ////            }
    ////        }
//        return container
//    }
}
