import Foundation
import Models
import SwiftData

public enum FetchLiteratureTimeError: Error {
    case notFound
}

public actor LiteratureTimeProvider {
    public nonisolated let modelExecutor: any ModelExecutor
    public nonisolated let modelContainer: ModelContainer

    private var modelContext: ModelContext { modelExecutor.modelContext }

    public init(modelContainer: ModelContainer) {
        modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
        self.modelContainer = modelContainer
    }

    public func fetchRandomForTimeExcluding(
        hour: Int,
        minute: Int,
        excludingIds: Set<String>
    ) async throws -> Result<LiteratureTime, FetchLiteratureTimeError> {
        let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
        let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

        let time = "\(paddedHour):\(paddedMinute)"

        var descriptor = FetchDescriptor<CurrentScheme.LiteratureTime>(
            predicate: #Predicate { item in
                item.time == time && !excludingIds.contains(item.id)
            }
        )

        let literatureTimeCount = try modelContext.fetchCount(descriptor)
        guard literatureTimeCount > 0 else {
            return Result.failure(.notFound)
        }

        descriptor.fetchLimit = 1
        descriptor.fetchOffset = Int.random(in: 0...literatureTimeCount - 1)

        let literatureTimes = try modelContext.fetch(descriptor)

        // Feels weird, but this database is readonly and
        // we have already checked that this descriptor returns more than 0
        let literatureTime = literatureTimes.first!

        return Result.success(
            LiteratureTime(
                time: literatureTime.time,
                quoteFirst: literatureTime.quoteFirst,
                quoteTime: literatureTime.quoteTime,
                quoteLast: literatureTime.quoteLast,
                title: literatureTime.title,
                author: literatureTime.author,
                gutenbergReference: literatureTime.gutenbergReference,
                id: literatureTime.id
            )
        )
    }

    public func fetch(id: String) async throws -> Result<LiteratureTime, FetchLiteratureTimeError> {
        let descriptor = FetchDescriptor<CurrentScheme.LiteratureTime>(
            predicate: #Predicate { item in
                item.id == id
            }
        )

        let literatureTimes = try modelContext.fetch(descriptor)
        guard
            let literatureTime = literatureTimes.first
        else {
            return .failure(.notFound)
        }

        return .success(
            LiteratureTime(
                time: literatureTime.time,
                quoteFirst: literatureTime.quoteFirst,
                quoteTime: literatureTime.quoteTime,
                quoteLast: literatureTime.quoteLast,
                title: literatureTime.title,
                author: literatureTime.author,
                gutenbergReference: literatureTime.gutenbergReference,
                id: literatureTime.id
            )
        )
    }
}
