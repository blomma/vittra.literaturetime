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
    var model: ViewModel = .init(
        provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.productionContainer)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Group {
                        Text(model.literatureTime.quoteFirst)
                            + Text(model.literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(model.literatureTime.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("- \(model.literatureTime.title), \(Text(model.literatureTime.author).italic())")
                    }
                    .font(.system(.footnote, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 15)
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 100)
                .padding(.vertical, 45)
                .animation(.default, value: model.literatureTime)
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
                        await model.fetchQuote(
                            literatureTimeId: literatureTimeId,
                            currentDate: Date()
                        )
                        literatureTimeId = model.literatureTime.id
                    }
                }
            }
            .refreshable {
                await model.fetchRandomQuote(
                    literatureTimeId: literatureTimeId,
                    currentDate: Date()
                )
                literatureTimeId = model.literatureTime.id
            }
            .onReceive(refreshTimer) { currentDate in
                if !autoRefreshQuote {
                    return
                }

                Task {
                    await model.autoRefreshQuote(
                        literatureTimeId: literatureTimeId,
                        currentDate: currentDate
                    )
                    literatureTimeId = model.literatureTime.id
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
            UIPasteboard.general.string = model.literatureTime.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }

        if !model.literatureTime.gutenbergReference.isEmpty {
            Link(
                destination: URL(
                    string: "https://www.gutenberg.org/ebooks/\(model.literatureTime.gutenbergReference)"
                )!
            ) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string =
                    "https://www.gutenberg.org/ebooks/\(model.literatureTime.gutenbergReference)"
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
    @Observable
    final class ViewModel {
        @ObservationIgnored var previousLiteratureTimeIds: [String]
        @ObservationIgnored var previousRefreshDate: Date

        var literatureTime: LiteratureTime

        private let provider: LiteratureTimeProvider

        public init(
            provider: LiteratureTimeProvider,
            previousLiteratureTimeIds: [String] = [],
            previousRefreshDate: Date = .distantPast,
            literatureTime: LiteratureTime = .empty
        ) {
            self.provider = provider

            self.previousLiteratureTimeIds = previousLiteratureTimeIds
            self.previousRefreshDate = previousRefreshDate
            self.literatureTime = literatureTime
        }

        func autoRefreshQuote(literatureTimeId: String, currentDate: Date) async {
            let previousHourMinute = Calendar.current.dateComponents(
                [.hour, .minute],
                from: previousRefreshDate
            )
            let currentHourMinute = Calendar.current.dateComponents([.hour, .minute], from: currentDate)

            guard let currentHour = currentHourMinute.hour,
                let currentMinute = currentHourMinute.minute,
                let previousHour = previousHourMinute.hour,
                let previousMinute = previousHourMinute.minute
            else {
                self.literatureTime = .fallback

                return
            }

            if currentHour == previousHour && currentMinute == previousMinute {
                return
            }

            return await fetchRandomQuote(literatureTimeId: literatureTimeId, currentDate: currentDate)
        }

        func fetchQuote(literatureTimeId: String, currentDate: Date) async {
            if !literatureTimeId.isEmpty {
                do {
                    let result = try await provider.fetch(id: literatureTimeId)
                    if case let .success(literatureTime) = result {
                        self.previousRefreshDate = currentDate
                        self.literatureTime = literatureTime

                        return
                    }
                } catch {
                    logger.logf(level: .error, message: error.localizedDescription)
                }
            }

            return await fetchRandomQuote(literatureTimeId: literatureTimeId, currentDate: currentDate)
        }

        func fetchRandomQuote(literatureTimeId: String, currentDate: Date) async {
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
                literatureTime = .fallback

                return
            }

            if previousHour != currentHour || previousMinute != currentMinute {
                previousLiteratureTimeIds.removeAll()
            } else {
                previousLiteratureTimeIds.append(literatureTimeId)
            }

            do {
                var result = try await provider.fetchRandomForTimeExcluding(
                    hour: currentHour,
                    minute: currentMinute,
                    excludingIds: previousLiteratureTimeIds
                )

                if case let .success(literatureTime) = result {
                    self.previousRefreshDate = currentDate
                    self.literatureTime = literatureTime

                    return
                }

                if case let .failure(failure) = result, case .notFound = failure {
                    let previousLiteratureTimeIdsCount = previousLiteratureTimeIds.count
                    if previousLiteratureTimeIdsCount > 1 {
                        previousLiteratureTimeIds.removeAll(where: { $0 != literatureTimeId })
                    } else {
                        previousLiteratureTimeIds.removeAll()
                    }
                }

                result = try await provider.fetchRandomForTimeExcluding(
                    hour: currentHour,
                    minute: currentMinute,
                    excludingIds: previousLiteratureTimeIds
                )

                if case let .success(literatureTime) = result {
                    self.previousRefreshDate = currentDate
                    self.literatureTime = literatureTime

                    return
                }
            } catch {
                logger.logf(level: .error, message: error.localizedDescription)
            }

            literatureTime = .fallback
        }
    }
}

#if DEBUG
#Preview("Light") {
    LiteratureTimeView(
        model: .init(
            provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.previewContainer),
            literatureTime: .previewSmall
        )
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LiteratureTimeView(
        model: .init(
            provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.previewContainer),
            literatureTime: .previewSmall
        )
    )
    .preferredColorScheme(.dark)
}
#endif
