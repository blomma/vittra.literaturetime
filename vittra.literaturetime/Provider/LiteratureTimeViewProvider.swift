import CoreData
import Foundation
import SwiftData

// get current dispatch queue label
extension DispatchQueue {
    static var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil)) ?? "unknown"
    }
}

protocol LiteratureTimeViewProviding {
    func search(query: String) async throws -> LiteratureTime?
}

struct LiteratureTimeProviderPreview: LiteratureTimeViewProviding {
    func search(query _: String) throws -> LiteratureTime? {
        var literatureTime: LiteratureTime = .fallback
        literatureTime.author = "Douglas Adamss"

        return literatureTime
    }
}

@ModelActor
actor LiteratureTimeProvider: LiteratureTimeViewProviding {}

extension LiteratureTimeProvider {
    func search(query: String) throws -> LiteratureTime? {
        let actorQueueLabel = DispatchQueue.currentLabel
        print("Actor3 queue:", actorQueueLabel)

        var descriptor = FetchDescriptor<Database.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.time == query
        }

        guard let literatureTimeCount = try? modelContext.fetchCount(descriptor), literatureTimeCount > 0 else {
            return nil
        }

        print("literatureTimeCount:", literatureTimeCount)
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
}
