import Models
import OSLog
import Oknytt
import Providers
import SwiftData
import SwiftUI

struct LiteratureTimeView: View {
    @AppStorage("\(Preferences.literatureTimeId)")
    private var literatureTimeId: String = .init()

    @AppStorage("\(Preferences.autoRefreshQuote)")
    private var autoRefreshQuote: Bool = false

    @State
    private var shouldPresentSettings = false

    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    private let refreshTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    @State
    private var literatureTimeIds: Set<String> = []

    @State
    private var previousRefreshDate: Date = .distantPast

    @State
    var literatureTime: LiteratureTime = .empty

    var provider = LiteratureTimeProvider(modelContainer: ModelProvider.shared.productionContainer)

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Group {
                        Text(literatureTime.quoteFirst)
                            + Text(literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(literatureTime.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("- \(literatureTime.title), \(Text(literatureTime.author).italic())")
                    }
                    .font(.system(.footnote, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 15)
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 100)
                .padding(.vertical, 45)
                .animation(.default, value: literatureTime)
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                .contextMenu {
                    makeContextMenu
                }
            }
            .foregroundStyle(.literature)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && !autoRefreshQuote {
                    Task {
                        await fetchQuote(currentDate: Date())
                    }
                }
            }
            .refreshable {
                await fetchRandomQuote(currentDate: Date())
            }
            .onReceive(refreshTimer) { currentDate in
                if !autoRefreshQuote {
                    return
                }

                Task {
                    await autoRefreshQuote(currentDate: currentDate)
                }
            }
        }
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
        }
    }

    @ViewBuilder
    private var makeContextMenu: some View {
        Button {
            UIPasteboard.general.string = literatureTime.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }

        if !literatureTime.gutenbergReference.isEmpty {
            Link(
                destination: URL(
                    string: "https://www.gutenberg.org/ebooks/\(literatureTime.gutenbergReference)"
                )!
            ) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string =
                    "https://www.gutenberg.org/ebooks/\(literatureTime.gutenbergReference)"
            } label: {
                Label("Copy link to gutenberg", systemImage: "link")
            }
        }

        Divider()

        Button {
            shouldPresentSettings.toggle()
        } label: {
            Label("Settings", systemImage: "gearshape")
        }
    }
}

extension LiteratureTimeView {
    func fallBack() {
        self.literatureTime = .fallback
        literatureTimeId = literatureTime.id
    }

    func autoRefreshQuote(currentDate: Date) async {
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
            fallBack()

            return
        }

        if currentHour == previousHour && currentMinute == previousMinute {
            return
        }

        return await fetchRandomQuote(currentDate: currentDate)
    }

    func fetchQuote(currentDate: Date) async {
        if !literatureTimeId.isEmpty {
            do {
                let result = try await provider.fetch(id: literatureTimeId)
                if case let .success(literatureTime) = result {
                    previousRefreshDate = currentDate
                    self.literatureTime = literatureTime
                    literatureTimeId = literatureTime.id
                    literatureTimeIds.insert(literatureTime.id)

                    return
                }
            } catch {
                logger.logf(level: .error, message: error.localizedDescription)
            }
        }

        return await fetchRandomQuote(currentDate: currentDate)
    }

    func fetchRandomQuote(currentDate: Date) async {
        let previousHourMinute = Calendar.current.dateComponents(
            [.hour, .minute],
            from: previousRefreshDate
        )
        let currentHourMinute = Calendar.current.dateComponents([.hour, .minute], from: Date())

        guard
            let currentHour = currentHourMinute.hour,
            let currentMinute = currentHourMinute.minute,
            let previousHour = previousHourMinute.hour,
            let previousMinute = previousHourMinute.minute
        else {
            fallBack()

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
                literatureTimeId = literatureTime.id
                literatureTimeIds.insert(literatureTimeId)

                return
            }

            // We didn't find anything and there were no exclusions, which means
            // there is nothing to be found for this timeslot
            // so we do an early exit and wait for a better time
            if literatureTimeIds.isEmpty {
                fallBack()

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
            literatureTimeIds = [literatureTimeId]

            result = try await provider.fetchRandomForTimeExcluding(
                hour: currentHour,
                minute: currentMinute,
                excludingIds: literatureTimeIds
            )

            if case let .success(literatureTime) = result {
                previousRefreshDate = currentDate
                self.literatureTime = literatureTime
                literatureTimeId = literatureTime.id
                literatureTimeIds.insert(literatureTimeId)

                return
            }
        } catch {
            logger.logf(level: .error, message: error.localizedDescription)
        }

        fallBack()
    }
}

#if DEBUG
#Preview("Light") {
    LiteratureTimeView(
        literatureTime: .previewSmall,
        provider: LiteratureTimeProvider(
            modelContainer: ModelProvider.shared.previewContainer
        )
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LiteratureTimeView(
        literatureTime: .previewSmall,
        provider: LiteratureTimeProvider(
            modelContainer: ModelProvider.shared.previewContainer
        )
    )
    .preferredColorScheme(.dark)
}
#endif
