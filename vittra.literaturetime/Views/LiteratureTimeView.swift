import SwiftData
import SwiftUI

struct LiteratureTimeView: View {
    @State var model: ViewModel
    @State var shouldPresentSettings = false

    @Environment(UserPreferences.self) private var userPreferences
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
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
                .animation(.default, value: model.state)
                .padding(15)
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                .contextMenu {
                    makeContextMenu
                }
            }
            .padding(15)
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

            Button {
                shouldPresentSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.literature)
                    .opacity(0.3)
            }
            .offset(x: -30)
        }
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
        }
    }

    @MainActor
    @ViewBuilder
    private var makeContextMenu: some View {
        Section {
            Button {
                UIPasteboard.general.string = model.state.description
            } label: {
                Label("Copy quote to clipboard", systemImage: "doc.on.doc")
            }

            if !model.state.gutenbergReference.isEmpty {
                Link(
                    destination: URL(string: "https://www.gutenberg.org/ebooks/\(model.state.gutenbergReference)")!)
                {
                    Label("View book on gutenberg", systemImage: "link")
                }
            }
        }
        .listRowBackground(Color(.literatureBackground))
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

        func fetchQuote(autoRefresh: Bool)  {
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
        .environment(UserPreferences.shared)
        .preferredColorScheme(.light)
    }

    #Preview("Dark") {
        LiteratureTimeView(model: .init(
            initialState: .preview,
            provider: LiteratureTimeProviderPreview()
        ))
        .preferredColorScheme(.dark)
        .environment(UserPreferences.shared)
    }
#endif
