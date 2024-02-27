import CoreData
import Foundation
import SwiftData

protocol LiteratureTimeViewProviding {
    func search(query: String) async throws -> LiteratureTime?
    func searchFor(Id: String) async throws -> LiteratureTime?
}

struct LiteratureTimeProviderPreview: LiteratureTimeViewProviding {}
extension LiteratureTimeProviderPreview {
    func search(query _: String) throws -> LiteratureTime? {
        return LiteratureTime(
            time: "21:05",
            quoteFirst: "It was ",
            quoteTime: "five minutes past nine",
            quoteLast: " when I entered our joint sitting-room for breakfast on the following morning.",
            title: "The Murder on the Links",
            author: "Agatha Christie",
            gutenbergReference: "58866",
            id: "e42d5465bc978b08ec08d6711a0bc165d5381eaeaced8321fb33b95c85b97157"
        )
    }

    func searchFor(Id _: String) async throws -> LiteratureTime? {
        return LiteratureTime(
            time: "21:05",
            quoteFirst: "It was ",
            quoteTime: "five minutes past nine",
            quoteLast: " when I entered our joint sitting-room for breakfast on the following morning.",
            title: "The Murder on the Links",
            author: "Agatha Christie",
            gutenbergReference: "58866",
            id: "e42d5465bc978b08ec08d6711a0bc165d5381eaeaced8321fb33b95c85b97157"
        )
    }
}

@ModelActor
actor LiteratureTimeProvider: LiteratureTimeViewProviding {}
extension LiteratureTimeProvider {
    func search(query: String) throws -> LiteratureTime? {
        var descriptor = FetchDescriptor<Database.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.time == query
        }

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

    func searchFor(Id: String) async throws -> LiteratureTime? {
        var descriptor = FetchDescriptor<Database.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.id == Id
        }

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
