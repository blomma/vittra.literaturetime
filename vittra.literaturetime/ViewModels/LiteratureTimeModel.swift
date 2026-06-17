import Foundation
import Models
import Oknytt
import Providers

@MainActor
@Observable
final class LiteratureTimeModel {
    private(set) var literatureTime: LiteratureTime

    private let provider: any LiteratureTimeProviding
    private var literatureTimeIds: Set<String> = []
    private var previousRefreshDate: Date = .distantPast

    init(literatureTime: LiteratureTime = .empty, provider: any LiteratureTimeProviding) {
        self.literatureTime = literatureTime
        self.provider = provider
    }

    /// Restores the previously shown quote by id, falling back to a random one
    /// for the current time when it can't be found.
    func loadInitialQuote(persistedId: String, currentDate: Date) async {
        if !persistedId.isEmpty {
            do {
                let result = try await provider.fetch(id: persistedId)
                if case let .success(literatureTime) = result {
                    previousRefreshDate = currentDate
                    self.literatureTime = literatureTime
                    literatureTimeIds.insert(literatureTime.id)

                    return
                }
            } catch {
                logger.logf(level: .error, message: error.localizedDescription)
            }
        }

        await refreshRandomQuote(currentDate: currentDate)
    }

    /// Fetches a random quote for the current time, avoiding quotes already shown
    /// during this minute.
    func refreshRandomQuote(currentDate: Date) async {
        let previousHourMinute = Calendar.current.dateComponents(
            [.hour, .minute],
            from: previousRefreshDate
        )
        let currentHourMinute = Calendar.current.dateComponents(
            [.hour, .minute],
            from: currentDate
        )

        guard
            let currentHour = currentHourMinute.hour,
            let currentMinute = currentHourMinute.minute,
            let previousHour = previousHourMinute.hour,
            let previousMinute = previousHourMinute.minute
        else {
            useFallback()

            return
        }

        // We have crossed over to a new combination of hour and/or minute
        // so we reset the previous fetched id's of quotes
        if previousHour != currentHour || previousMinute != currentMinute {
            literatureTimeIds = []
        }

        do {
            var result = try await provider.fetchRandomForTimeExcluding(
                hour: currentHour,
                minute: currentMinute,
                excludingIds: literatureTimeIds
            )

            if case let .success(literatureTime) = result {
                previousRefreshDate = currentDate
                self.literatureTime = literatureTime
                literatureTimeIds.insert(literatureTime.id)

                return
            }

            // We didn't find anything and there were no exclusions, which means
            // there is nothing to be found for this timeslot
            // so we do an early exit and wait for a better time
            if literatureTimeIds.isEmpty {
                useFallback()

                return
            }

            // In this case, we excluded the current literaturetime
            // and got nothing back, which means we should just keep the current one
            if literatureTimeIds.count == 1 {
                previousRefreshDate = currentDate

                return
            }

            // In this case we excluded more than just the current literaturetime
            // so we keep the current literaturetime and try fetching again
            literatureTimeIds = [literatureTime.id]

            result = try await provider.fetchRandomForTimeExcluding(
                hour: currentHour,
                minute: currentMinute,
                excludingIds: literatureTimeIds
            )

            if case let .success(literatureTime) = result {
                previousRefreshDate = currentDate
                self.literatureTime = literatureTime
                literatureTimeIds.insert(literatureTime.id)

                return
            }
        } catch {
            logger.logf(level: .error, message: error.localizedDescription)
        }

        useFallback()
    }

    /// Refreshes the quote only when the wall-clock minute has changed since the
    /// last refresh, used to drive the per-minute auto refresh.
    func autoRefreshIfMinuteChanged(currentDate: Date) async {
        let previousHourMinute = Calendar.current.dateComponents(
            [.hour, .minute],
            from: previousRefreshDate
        )
        let currentHourMinute = Calendar.current.dateComponents(
            [.hour, .minute],
            from: currentDate
        )

        guard let currentHour = currentHourMinute.hour,
            let currentMinute = currentHourMinute.minute,
            let previousHour = previousHourMinute.hour,
            let previousMinute = previousHourMinute.minute
        else {
            useFallback()

            return
        }

        if currentHour == previousHour && currentMinute == previousMinute {
            return
        }

        await refreshRandomQuote(currentDate: currentDate)
    }

    private func useFallback() {
        literatureTime = .fallback
    }
}
