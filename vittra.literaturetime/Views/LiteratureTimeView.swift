import SwiftData
import SwiftUI

@MainActor
struct LiteratureTimeView: View {
    @State var model: ViewModel = .init(
        initialState: .empty,
        provider: LiteratureTimeProvider()
    )
    @State var shouldPresentSettings = false

    @Environment(UserPreferences.self) private var userPreferences
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

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
                    model.fetchQuote(autoRefresh: userPreferences.autoRefreshQuote)
                }
            }
            .onChange(of: userPreferences.autoRefreshQuote) {
                model.fetchQuote(autoRefresh: userPreferences.autoRefreshQuote)
            }
            .refreshable {
                model.refreshQuote()
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
                destination: URL(string: "https://www.gutenberg.org/ebooks/\(model.state.gutenbergReference)")!)
            {
                Label("View book on gutenberg", systemImage: "safari")
            }

            Button {
                UIPasteboard.general.string = "https://www.gutenberg.org/ebooks/\(model.state.gutenbergReference)"
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
        @AppStorage("literatureTimeId")
        private var literatureTimeId: String = .init()

        public var state: LiteratureTime
        private let provider: LiteratureTimeViewProviding

        private var quoteTimer: Timer?

        public init(
            initialState state: LiteratureTime,
            provider: LiteratureTimeViewProviding
        ) {
            self.state = state
            self.provider = provider
        }

        func refreshQuote() {
            fetchRandomQuote()
        }

        func fetchQuote(autoRefresh: Bool) {
            quoteTimer?.invalidate()
            quoteTimer = nil

            if autoRefresh {
                fetchRandomQuote()

                let now = Date.timeIntervalSinceReferenceDate
                let delayFraction = trunc(now) - now

                let delay = 60.0 - Double(Int(now) % 60) + delayFraction

                quoteTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                    Task { @MainActor in
                        self.fetchRandomQuote()

                        // Now create a repeating timer that fires once a minute.
                        self.quoteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                            Task { @MainActor in
                                self.fetchRandomQuote()
                            }
                        }
                    }
                }

                return
            }

            if !literatureTimeId.isEmpty {
                fetchQuoteFrom(Id: literatureTimeId)
            }

            if !state.id.isEmpty {
                return
            }

            fetchRandomQuote()
        }

        private func fetchRandomQuote() {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                state = .fallback
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            let literatureTime = try? provider.search(query: query)

            guard let literatureTime = literatureTime else {
                literatureTimeId = .init()
                state = .fallback

                return
            }

            literatureTimeId = literatureTime.id
            state = literatureTime
        }

        private func fetchQuoteFrom(Id: String) {
            let literatureTime = try? provider.searchFor(Id: Id)

            guard let literatureTime = literatureTime else {
                state = .fallback
                return
            }

            state = literatureTime
        }
    }
}

#if DEBUG
    #Preview("Light") {
        LiteratureTimeView(model: .init(
            initialState: .previewSmall,
            provider: LiteratureTimeProviderPreview()
        ))
        .environment(UserPreferences())
        .preferredColorScheme(.light)
    }

    #Preview("Dark") {
        LiteratureTimeView(model: .init(
            initialState: .preview,
            provider: LiteratureTimeProviderPreview()
        ))
        .preferredColorScheme(.dark)
        .environment(UserPreferences())
    }
#endif
