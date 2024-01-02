import Foundation
import SwiftData

protocol LiteratureTimeViewProviding {
    func search(query: String) throws -> LiteratureTimeViewState?
}

extension LiteratureTimeViewProviding {
    func search(query: String) throws -> LiteratureTimeViewState? {
        var descriptor = FetchDescriptor<LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.time == query
        }

        let modelContext = ModelContext(ModelContexts.productionContainer)
        guard let literatureTimeCount = try? modelContext.fetchCount(descriptor), literatureTimeCount > 0 else {
            return nil
        }

        descriptor.fetchLimit = 1
        descriptor.fetchOffset = Int.random(in: 0 ... literatureTimeCount - 1)

        guard let literatureTimes = try? modelContext.fetch(descriptor), let literatureTime = literatureTimes.first else {
            return nil
        }

        return LiteratureTimeViewState(
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

struct LiteratureTimeProvider: LiteratureTimeViewProviding {}
struct LiteratureTimeProviderPreview: LiteratureTimeViewProviding {
    func search(query _: String) throws -> LiteratureTimeViewState? {
        var literatureTime: LiteratureTimeViewState = .fallback
        literatureTime.author = "Douglas Adamss"

        return literatureTime
    }
}
