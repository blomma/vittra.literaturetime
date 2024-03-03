import CoreData
import Foundation
import SwiftData

protocol LiteratureTimeViewProviding {
    func search(query: String) throws -> LiteratureTime?
    func searchFor(Id: String) throws -> LiteratureTime?
}

struct LiteratureTimeProvider: LiteratureTimeViewProviding {}
extension LiteratureTimeProvider {
    func search(query: String) throws -> LiteratureTime? {
        var descriptor = FetchDescriptor<Database.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.time == query
        }

        let modelContext = ModelContext(.productionContainer)
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
            gutenbergReference: literatureTime.gutenbergReference,
            id: literatureTime.id
        )
    }

    func searchFor(Id: String) throws -> LiteratureTime? {
        var descriptor = FetchDescriptor<Database.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.id == Id
        }

        let modelContext = ModelContext(.productionContainer)
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
            gutenbergReference: literatureTime.gutenbergReference,
            id: literatureTime.id
        )
    }
}
