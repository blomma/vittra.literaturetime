import SwiftData

actor LiteratureTimeModelActor: ModelActor {
    let modelContainer: ModelContainer
    let modelExecutor: any ModelExecutor

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        modelExecutor = DefaultSerialModelExecutor(modelContext: context)
    }

    func insert(time: String, quoteFirst: String, quoteTime: String, quoteLast: String, title: String, author: String, gutenbergReference: String, id: String) throws {
        let literatureTime = LiteratureTime(
            time: time,
            quoteFirst: quoteFirst,
            quoteTime: quoteTime,
            quoteLast: quoteLast,
            title: title,
            author: author,
            gutenbergReference: gutenbergReference,
            id: id
        )

        modelContext.insert(literatureTime)
    }

    func save() throws {
        try modelContext.save()
    }
}
