import SwiftData
import SwiftUI

struct LiteratureTimeView: View {
    @State var model: ViewModel
    @State var shouldPresentSettings = false

    @Environment(\.colorScheme) private var colorScheme
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(.title2, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(model.state.title), \(Text(model.state.author).italic())")
                    }
                    .padding(.top, 15)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.system(.footnote, design: .serif, weight: .regular))
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
                    Task {
                        await model.fetchQuote(autoRefresh: userPreferences.autoRefreshQuote)
                    }
                }
            }
            .onChange(of: userPreferences.autoRefreshQuote) {
                Task {
                    await model.fetchQuote(autoRefresh: userPreferences.autoRefreshQuote)
                }
            }
            .refreshable {
                await model.refreshQuote()
            }

            Button {
                shouldPresentSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.literature)
                    .opacity(0.5)
            }
            .offset(x: -30)
        }
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
                .preferredColorScheme(
                    // Workaround for a bug, once preferredColorScheme is set to something explicit,
                    // like .light or .dark and then reset back to .none, for a presentation dialog
                    // like sheet, it will no longer respect the global system colorScheme no matter
                    // what you do, so this gets around it by just listening for changes in colorScheme,
                    // since that triggers correctly
                    colorScheme == .dark ? .dark : .light
                )
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

        func refreshQuote() async {
            await fetchRandomQuote()
        }

        func fetchQuote(autoRefresh: Bool) async {
            quoteTimer?.invalidate()
            quoteTimer = nil

            if autoRefresh {
                await fetchRandomQuote()

                let now = Date.timeIntervalSinceReferenceDate
                let delayFraction = trunc(now) - now

                let delay = 60.0 - Double(Int(now) % 60) + delayFraction

                quoteTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                    Task { @MainActor in
                        await self.fetchRandomQuote()

                        // Now create a repeating timer that fires once a minute.
                        self.quoteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                            Task { @MainActor in
                                await self.fetchRandomQuote()
                            }
                        }
                    }
                }

                return
            }

            if !literatureTimeId.isEmpty {
                await fetchQuoteFrom(Id: literatureTimeId)
            }

            if !state.id.isEmpty {
                return
            }

            await fetchRandomQuote()
        }

        private func fetchRandomQuote() async {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                state = .fallback
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            let literatureTime = try? await provider.search(query: query)

            guard let literatureTime = literatureTime else {
                literatureTimeId = .init()
                state = .fallback

                return
            }

            literatureTimeId = literatureTime.id
            state = literatureTime
        }

        private func fetchQuoteFrom(Id: String) async {
            let literatureTime = try? await provider.searchFor(Id: Id)

            guard let literatureTime = literatureTime else {
                state = .fallback
                return
            }

            state = literatureTime
        }
    }
}

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
