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

    var model: ViewModel = .init(
        provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.productionContainer)
    )

    @State
    var state: StateModel = .init()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Group {
                        Text(state.literatureTime.quoteFirst)
                            + Text(state.literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(state.literatureTime.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("- \(state.literatureTime.title), \(Text(state.literatureTime.author).italic())")
                    }
                    .font(.system(.footnote, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 15)
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 100)
                .padding(.vertical, 45)
                .animation(.default, value: state.literatureTime)
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
                        let newState = await model.fetchQuote(
                            literatureTimeId: literatureTimeId,
                            state: state,
                            currentDate: Date()
                        )
                        setState(newState: newState)
                    }
                }
            }
            .refreshable {
                Task {
                    let newState = await model.fetchRandomQuote(
                        literatureTimeId: literatureTimeId,
                        state: state,
                        currentDate: Date()
                    )
                    setState(newState: newState)
                }
            }
            .onReceive(refreshTimer) { currentDate in
                if !autoRefreshQuote {
                    return
                }

                Task {
                    let newState = await model.autoRefreshQuote(
                        literatureTimeId: literatureTimeId,
                        state: state,
                        currentDate: currentDate
                    )
                    setState(newState: newState)
                }
            }
        }
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
        }
    }

    private func setState(newState: StateModel) {
        state.literatureTime = newState.literatureTime
        state.previousRefreshDate = newState.previousRefreshDate
        state.previousLiteratureTimeIds = newState.previousLiteratureTimeIds

        literatureTimeId = newState.literatureTime.id
    }

    @ViewBuilder
    private var makeContextMenu: some View {
        Button {
            UIPasteboard.general.string = state.literatureTime.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }

        if !state.literatureTime.gutenbergReference.isEmpty {
            Link(
                destination: URL(
                    string: "https://www.gutenberg.org/ebooks/\(state.literatureTime.gutenbergReference)"
                )!
            ) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string =
                    "https://www.gutenberg.org/ebooks/\(state.literatureTime.gutenbergReference)"
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
    @MainActor
    @Observable
    final class StateModel {
        @ObservationIgnored var previousLiteratureTimeIds: [String]
        @ObservationIgnored var previousRefreshDate: Date

        var literatureTime: LiteratureTime

        init(
            previousLiteratureTimeIds: [String] = [],
            previousRefreshDate: Date = .distantPast,
            literatureTime: LiteratureTime = .empty
        ) {
            self.previousLiteratureTimeIds = previousLiteratureTimeIds
            self.previousRefreshDate = previousRefreshDate
            self.literatureTime = literatureTime
        }
    }

    actor ViewModel {
        private let provider: LiteratureTimeProvider

        public init(
            provider: LiteratureTimeProvider
        ) {
            self.provider = provider
        }

        func autoRefreshQuote(literatureTimeId: String, state: StateModel, currentDate: Date) async -> StateModel {
            let previousHourMinute = await Calendar.current.dateComponents(
                [.hour, .minute],
                from: state.previousRefreshDate
            )
            let currentHourMinute = Calendar.current.dateComponents([.hour, .minute], from: currentDate)

            guard let currentHour = currentHourMinute.hour,
                let currentMinute = currentHourMinute.minute,
                let previousHour = previousHourMinute.hour,
                let previousMinute = previousHourMinute.minute
            else {
                return await StateModel(
                    previousLiteratureTimeIds: state.previousLiteratureTimeIds,
                    previousRefreshDate: state.previousRefreshDate,
                    literatureTime: .fallback
                )
            }

            if currentHour == previousHour && currentMinute == previousMinute {
                return state
            }

            return await fetchRandomQuote(literatureTimeId: literatureTimeId, state: state, currentDate: currentDate)
        }

        func fetchQuote(literatureTimeId: String, state: StateModel, currentDate: Date) async -> StateModel {
            if !literatureTimeId.isEmpty {
                do {
                    let result = try await provider.fetch(id: literatureTimeId)
                    if case let .success(literatureTime) = result {
                        return await StateModel(
                            previousLiteratureTimeIds: state.previousLiteratureTimeIds,
                            previousRefreshDate: currentDate,
                            literatureTime: literatureTime
                        )
                    }
                } catch {
                    logger.logf(level: .error, message: error.localizedDescription)
                }
            }

            return await fetchRandomQuote(literatureTimeId: literatureTimeId, state: state, currentDate: currentDate)
        }

        func fetchRandomQuote(literatureTimeId: String, state: StateModel, currentDate: Date) async -> StateModel {
            let previousHourMinute = await Calendar.current.dateComponents(
                [.hour, .minute],
                from: state.previousRefreshDate
            )
            let currentHourMinute = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard
                let currentHour = currentHourMinute.hour,
                let currentMinute = currentHourMinute.minute,
                let previousHour = previousHourMinute.hour,
                let previousMinute = previousHourMinute.minute
            else {
                return await StateModel(
                    previousLiteratureTimeIds: state.previousLiteratureTimeIds,
                    previousRefreshDate: state.previousRefreshDate,
                    literatureTime: .fallback
                )
            }

            var previousLiteratureTimeIds = await state.previousLiteratureTimeIds

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
                    return await StateModel(
                        previousLiteratureTimeIds: previousLiteratureTimeIds,
                        previousRefreshDate: currentDate,
                        literatureTime: literatureTime
                    )
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
                    return await StateModel(
                        previousLiteratureTimeIds: previousLiteratureTimeIds,
                        previousRefreshDate: currentDate,
                        literatureTime: literatureTime
                    )
                }
            } catch {
                logger.logf(level: .error, message: error.localizedDescription)
            }

            return await StateModel(
                previousLiteratureTimeIds: previousLiteratureTimeIds,
                previousRefreshDate: state.previousRefreshDate,
                literatureTime: .fallback
            )
        }
    }
}

#if DEBUG
#Preview("Light") {
    LiteratureTimeView(
        model: .init(
            provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.previewContainer)
        ),
        state: .init(literatureTime: .previewSmall)
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LiteratureTimeView(
        model: .init(
            provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.previewContainer)
        ),
        state: .init(literatureTime: .previewSmall)
    )
    .preferredColorScheme(.dark)
}
#endif
