import Models
import OSLog
import Oknytt
import Providers
import SwiftData
import SwiftUI

@MainActor
struct LiteratureTimeView: View {
    @AppStorage("\(Preferences.autoRefreshQuote)")
    private var autoRefreshQuote: Bool = false

    @State
    var model: ViewModel = .init(
        initialState: LiteratureTime.empty,
        provider: LiteratureTimeProvider()
    )

    @State
    private var shouldPresentSettings = false

    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    private let refreshTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @State
    private var previousRefreshDate: Date = Date.now
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading) {
                    Group {
                        Text(model.state.quoteFirst)
                            + Text(model.state.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(model.state.quoteLast)
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text("- \(model.state.title), \(Text(model.state.author).italic())")
                    }
                    .font(.system(.footnote, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 15)
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 30 : 100)
                .padding(.vertical, 45)
                .animation(.default, value: model.state)
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                .contextMenu {
                    makeContextMenu
                }
            }
            .foregroundStyle(.literature)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    model.fetchQuote()
                }
            }
            .onChange(of: autoRefreshQuote) {
                model.fetchQuote()
            }
            .refreshable {
                model.fetchRandomQuote()
            }
            .onReceive(refreshTimer) { currentDate in
                if autoRefreshQuote {
                    let previousHourMinute = Calendar.current.dateComponents([.hour, .minute], from: previousRefreshDate)
                    let currentHourMinute = Calendar.current.dateComponents([.hour, .minute], from: currentDate)
                    if
                        let currentHour = currentHourMinute.hour,
                        let currentMinute = currentHourMinute.minute,
                        let previousHour = previousHourMinute.hour,
                        let previousMinute = previousHourMinute.minute,
                        currentHour != previousHour || currentMinute != previousMinute
                    {
                        previousRefreshDate = currentDate
                        model.fetchRandomQuote()
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
            UIPasteboard.general.string = model.state.description
        } label: {
            Label("Copy quote", systemImage: "doc.on.doc")
        }

        if !model.state.gutenbergReference.isEmpty {
            Link(
                destination: URL(
                    string: "https://www.gutenberg.org/ebooks/\(model.state.gutenbergReference)"
                )!
            ) {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string =
                    "https://www.gutenberg.org/ebooks/\(model.state.gutenbergReference)"
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
    final class ViewModel {
        @ObservationIgnored
        @AppStorage("\(Preferences.literatureTimeId)")
        private var literatureTimeId: String = .init()

        private let provider: LiteratureTimeProviding

        public var state: LiteratureTime

        private var currentHour: Int?
        private var currentMinute: Int?

        private var previousLiteratureTimeIds: [String] = []

        public init(
            initialState state: LiteratureTime,
            provider: LiteratureTimeProviding
        ) {
            self.state = state
            self.provider = provider
        }

        private func setLiteratureTime(literatureTime: LiteratureTime) {
            literatureTimeId = literatureTime.id
            state = literatureTime
        }

        func fetchQuote() {
            if !literatureTimeId.isEmpty {
                do {
                    let literatureTime = try provider.fetch(id: literatureTimeId)
                    if case .success(let literatureTime) = literatureTime {
                        setLiteratureTime(literatureTime: literatureTime)
                    }
                } catch {
                    logger.logf(level: .error, message: error.localizedDescription)
                }
            }

            if literatureTimeId.isEmpty {
                fetchRandomQuote()
            }
        }

        func fetchRandomQuote() {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())
            guard let hour = hm.hour, let minute = hm.minute else {
                setLiteratureTime(literatureTime: .fallback)
                return
            }

            if hour != currentHour || minute != currentMinute {
                currentHour = hour
                currentMinute = minute
                previousLiteratureTimeIds.removeAll()
            } else {
                previousLiteratureTimeIds.append(literatureTimeId)
            }

            do {
                var result = try provider.fetchRandomForTimeExcluding(
                    hour: hour,
                    minute: minute,
                    excludingIds: previousLiteratureTimeIds
                )

                if case .success(let literatureTime) = result {
                    setLiteratureTime(literatureTime: literatureTime)
                    return
                }

                if case .failure(let failure) = result, case .notFound = failure {
                    previousLiteratureTimeIds.removeAll()
                }

                result = try provider.fetchRandomForTimeExcluding(
                    hour: hour,
                    minute: minute,
                    excludingIds: previousLiteratureTimeIds
                )

                if case .success(let literatureTime) = result {
                    setLiteratureTime(literatureTime: literatureTime)
                    return
                }

                setLiteratureTime(literatureTime: .fallback)
            } catch {
                logger.logf(level: .error, message: error.localizedDescription)
                setLiteratureTime(literatureTime: .fallback)
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    LiteratureTimeView(
        model: .init(
            initialState: .previewSmall,
            provider: LiteratureTimeProviderPreview()
        )
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LiteratureTimeView(
        model: .init(
            initialState: .previewSmall,
            provider: LiteratureTimeProviderPreview()
        )
    )
    .preferredColorScheme(.dark)
}
#endif
