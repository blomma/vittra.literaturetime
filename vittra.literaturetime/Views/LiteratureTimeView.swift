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
    private var previousRefreshDate: Date = Date.now

    var model: ViewModel = .init(
        provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.productionContainer)
    )

    @State
    var state: LiteratureTime = LiteratureTime.empty

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Group {
                        Text(state.quoteFirst)
                            + Text(state.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(state.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("- \(state.title), \(Text(state.author).italic())")
                    }
                    .font(.system(.footnote, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 15)
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 100)
                .padding(.vertical, 45)
                .animation(.default, value: state)
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                .contextMenu {
                    makeContextMenu
                }
            }
            .foregroundStyle(.literature)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        state = await model.fetchQuote(literatureTimeId: literatureTimeId)
                        literatureTimeId = state.id
                    }
                }
            }
            .onChange(of: autoRefreshQuote) {
                Task {
                    state = await model.fetchQuote(literatureTimeId: literatureTimeId)
                    literatureTimeId = state.id
                }
            }
            .refreshable {
                Task {
                    state = await model.fetchRandomQuote(literatureTimeId: literatureTimeId)
                    literatureTimeId = state.id
                }
            }
            .onReceive(refreshTimer) { currentDate in
                if autoRefreshQuote {
                    let previousHourMinute = Calendar.current.dateComponents(
                        [.hour, .minute],
                        from: previousRefreshDate
                    )
                    let currentHourMinute = Calendar.current.dateComponents([.hour, .minute], from: currentDate)
                    if let currentHour = currentHourMinute.hour,
                        let currentMinute = currentHourMinute.minute,
                        let previousHour = previousHourMinute.hour,
                        let previousMinute = previousHourMinute.minute,
                        currentHour != previousHour || currentMinute != previousMinute
                    {
                        previousRefreshDate = currentDate
                        Task {
                            state = await model.fetchRandomQuote(literatureTimeId: literatureTimeId)
                            literatureTimeId = state.id
                        }
                    }
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
            UIPasteboard.general.string = state.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }

        if !state.gutenbergReference.isEmpty {
            Link(
                destination: URL(
                    string: "https://www.gutenberg.org/ebooks/\(state.gutenbergReference)"
                )!
            ) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string =
                    "https://www.gutenberg.org/ebooks/\(state.gutenbergReference)"
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
    actor ViewModel {
        private let provider: LiteratureTimeProvider

        private var currentHour: Int?
        private var currentMinute: Int?
        private var previousLiteratureTimeIds: [String] = []

        public init(
            provider: LiteratureTimeProvider
        ) {
            self.provider = provider
        }

        func fetchQuote(literatureTimeId: String) async -> LiteratureTime {
            if !literatureTimeId.isEmpty {
                do {
                    let result = try await provider.fetch(id: literatureTimeId)
                    if case .success(let literatureTime) = result {
                        return literatureTime
                    }
                } catch {
                    logger.logf(level: .error, message: error.localizedDescription)
                }
            }

            return await fetchRandomQuote(literatureTimeId: literatureTimeId)
        }

        func fetchRandomQuote(literatureTimeId: String) async -> LiteratureTime {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())
            guard let hour = hm.hour, let minute = hm.minute else {
                return .fallback
            }

            if hour != currentHour || minute != currentMinute {
                currentHour = hour
                currentMinute = minute
                previousLiteratureTimeIds.removeAll()
            } else {
                previousLiteratureTimeIds.append(literatureTimeId)
            }

            do {
                var result = try await provider.fetchRandomForTimeExcluding(
                    hour: hour,
                    minute: minute,
                    excludingIds: previousLiteratureTimeIds
                )

                if case .success(let literatureTime) = result {
                    return literatureTime
                }

                if case .failure(let failure) = result, case .notFound = failure {
                    previousLiteratureTimeIds.removeAll()
                }

                result = try await provider.fetchRandomForTimeExcluding(
                    hour: hour,
                    minute: minute,
                    excludingIds: previousLiteratureTimeIds
                )

                if case .success(let literatureTime) = result {
                    return literatureTime
                }

                return .fallback
            } catch {
                logger.logf(level: .error, message: error.localizedDescription)
                return .fallback
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    LiteratureTimeView(
        model: .init(
            provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.previewContainer)
        ),
        state: .previewBig
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LiteratureTimeView(
        model: .init(
            provider: LiteratureTimeProvider(modelContainer: ModelProvider.shared.previewContainer)
        ),
        state: .previewSmall
    )
    .preferredColorScheme(.dark)
}
#endif
