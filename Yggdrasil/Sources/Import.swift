import CoreData
import Foundation

func importLiteratureTime(fromFile: String, toStore: String) {
    var data: Data?
    do {
        data = try String(contentsOfFile: fromFile).data(using: .utf8)
    } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }

    guard let data = data else {
        return
    }

    var literaturetimesImport: [LiteratureTimeImport]?
    do {
        literaturetimesImport = try JSONDecoder().decode([LiteratureTimeImport].self, from: data)
    } catch {
        let nsError = error as NSError
        fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
    }

    guard let literaturetimesImport = literaturetimesImport else {
        return
    }

    guard let modelURL = Bundle.module.url(forResource: "Model", withExtension: "momd") else {
        fatalError("Unresolved error, modelUrl is nil")
    }

    guard let model = NSManagedObjectModel(contentsOf: modelURL) else { fatalError("Unresolved error, model is nil")
    }

    let container = NSPersistentContainer(name: "Model", managedObjectModel: model)
    let storeURL = URL.documentsDirectory.appending(path: "literaturetimes.store")
    if let description = container.persistentStoreDescriptions.first {
        // Delete all existing data.
        try? FileManager.default.removeItem(at: storeURL)

        // Make Core Data write to our new store URL.
        description.url = storeURL

        // Force WAL mode off.
        description.setValue("DELETE" as NSObject, forPragmaNamed: "journal_mode")
        container.loadPersistentStores { _, error in
            do {
                for literatureTimeImport in literaturetimesImport {
                    let literatureTime = LiteratureTime(context: container.viewContext)
                    literatureTime.time = literatureTimeImport.time
                    literatureTime.quoteFirst = literatureTimeImport.quoteFirst
                    literatureTime.quoteTime = literatureTimeImport.quoteTime
                    literatureTime.quoteLast = literatureTimeImport.quoteLast
                    literatureTime.title = literatureTimeImport.title
                    literatureTime.author = literatureTimeImport.author
                    literatureTime.gutenbergReference = literatureTimeImport.gutenbergReference
                    literatureTime.id = literatureTimeImport.hash

                    container.viewContext.insert(literatureTime)
                }

                // Ensure all our changes are fully saved.
                try container.viewContext.save()

                // Adjust this to the actual location where you want the file to be saved.
                let destination = URL(filePath: toStore)
                try FileManager.default.removeItem(at: destination)
                try FileManager.default.copyItem(at: storeURL, to: destination)
            } catch {
                fatalError("Failed to create data: \(error.localizedDescription)")
            }
        }
    }
}
