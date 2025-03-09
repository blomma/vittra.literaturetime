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
    func fetchRandom(hour: Int, minute: Int, excludingIds: [String]) throws -> (literatureTime: LiteratureTime, excludingIds: [String])?
    func fetch(id: String) throws -> LiteratureTime?
}

extension LiteratureTimeProviding {
    public var modelContext: ModelContext {
        return ModelContext(ModelProvider.shared.productionContainer)
    }

    public func fetchRandom(hour: Int, minute: Int, excludingIds: [String]) throws -> (literatureTime: LiteratureTime, excludingIds: [String])? {
        let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
        let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

        let time = "\(paddedHour):\(paddedMinute)"

        var descriptor = FetchDescriptor<CurrentScheme.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.time == time && !excludingIds.contains(item.id)
        }

        if let literatureTimeCount = try? modelContext.fetchCount(descriptor),
            literatureTimeCount > 0
        {
            descriptor.fetchLimit = 1
            descriptor.fetchOffset = Int.random(in: 0...literatureTimeCount - 1)

            guard let literatureTimes = try? modelContext.fetch(descriptor),
                let literatureTime = literatureTimes.first
            else {
                return nil
            }

            return (LiteratureTime(
                time: literatureTime.time,
                quoteFirst: literatureTime.quoteFirst,
                quoteTime: literatureTime.quoteTime,
                quoteLast: literatureTime.quoteLast,
                title: literatureTime.title,
                author: literatureTime.author,
                gutenbergReference: literatureTime.gutenbergReference,
                id: literatureTime.id
            ), excludingIds)
        }

        descriptor.predicate = #Predicate { item in
            item.time == time
        }

        descriptor.fetchLimit = nil
        descriptor.fetchOffset = 0
        guard let literatureTimeCount = try? modelContext.fetchCount(descriptor),
            literatureTimeCount > 0
        else {
            return nil
        }

        descriptor.fetchLimit = 1
        descriptor.fetchOffset = Int.random(in: 0...literatureTimeCount - 1)
        guard let literatureTimes = try? modelContext.fetch(descriptor),
            let literatureTime = literatureTimes.first
        else {
            return nil
        }

        return (LiteratureTime(
            time: literatureTime.time,
            quoteFirst: literatureTime.quoteFirst,
            quoteTime: literatureTime.quoteTime,
            quoteLast: literatureTime.quoteLast,
            title: literatureTime.title,
            author: literatureTime.author,
            gutenbergReference: literatureTime.gutenbergReference,
            id: literatureTime.id
        ), [])
    }

    public func fetch(id: String) throws -> LiteratureTime? {
        var descriptor = FetchDescriptor<CurrentScheme.LiteratureTime>()
        descriptor.predicate = #Predicate { item in
            item.id == id
        }

        guard let literatureTimes = try? modelContext.fetch(descriptor),
            let literatureTime = literatureTimes.first
        else {
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
