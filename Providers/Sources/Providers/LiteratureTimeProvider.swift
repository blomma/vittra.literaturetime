import CoreData
import Foundation
import Models
import SwiftData
import SwiftUI

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(suffix(toLength))
        }
    }
}

public protocol LiteratureTimeProviding {
    var modelContext: ModelContext { get }

    func fetchRandomForTimeExcluding(
        hour: Int,
        minute: Int,
        excludingIds: [String]
    ) throws -> Result<LiteratureTime, FetchLiteratureTimeError>

    func fetch(id: String) throws -> Result<LiteratureTime, FetchLiteratureTimeError>
}

public enum FetchLiteratureTimeError: Error {
    case notFound
}

extension LiteratureTimeProviding {
    public var modelContext: ModelContext {
        return ModelContext(ModelProvider.shared.productionContainer)
    }

    public func fetchRandomForTimeExcluding(
        hour: Int,
        minute: Int,
        excludingIds: [String]
    ) throws -> Result<LiteratureTime, FetchLiteratureTimeError> {
        let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
        let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

        let time = "\(paddedHour):\(paddedMinute)"

        var descriptor = FetchDescriptor<CurrentScheme.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.time == time && !excludingIds.contains(item.id)
        }

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

    public func fetch(id: String) throws -> Result<LiteratureTime, FetchLiteratureTimeError> {
        var descriptor = FetchDescriptor<CurrentScheme.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.id == id
        }

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

public struct LiteratureTimeProvider: LiteratureTimeProviding {
    public init() {}
}

#if DEBUG
public struct LiteratureTimeProviderPreview: LiteratureTimeProviding {
    public var modelContext: ModelContext {
        return ModelContext(ModelProvider.shared.previewContainer)
    }

    public init() {}
}
#endif
