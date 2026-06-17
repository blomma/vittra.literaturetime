import Models
import Providers
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

    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var model: LiteratureTimeModel

    init(
        literatureTime: LiteratureTime = .empty,
        provider: LiteratureTimeProvider = .init(
            modelContainer: ModelProvider.shared.productionContainer
        )
    ) {
        _model = State(
            initialValue: LiteratureTimeModel(literatureTime: literatureTime, provider: provider)
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView(.vertical) {
                VStack(alignment: .leading) {
                    Group {
                        Text(
                            "\(model.literatureTime.quoteFirst)\(Text(model.literatureTime.quoteTime).foregroundStyle(.literatureTime))\(model.literatureTime.quoteLast)"
                        )
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text(
                            "- \(model.literatureTime.title), \(Text(model.literatureTime.author).italic())"
                        )
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
                    QuoteContextMenu(
                        literatureTime: model.literatureTime,
                        shouldPresentSettings: $shouldPresentSettings
                    )
                }
            }
            .scrollIndicators(.hidden)
            .foregroundStyle(.literature)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active && !autoRefreshQuote {
                    Task {
                        await model.loadInitialQuote(
                            persistedId: literatureTimeId,
                            currentDate: Date()
                        )
                    }
                }
            }
            .onChange(of: model.literatureTime) { _, newValue in
                literatureTimeId = newValue.id
            }
            .refreshable {
                await model.refreshRandomQuote(currentDate: Date())
            }
            .task(id: autoRefreshQuote) {
                // `.task` runs on appear (and whenever auto-refresh is toggled),
                // unlike `onChange(of: scenePhase)`, which doesn't fire for the
                // initial value and so can't be relied on for the cold-launch
                // load. When auto-refresh is off, this is the initial load that
                // restores the last quote (or a fresh one for the current time).
                guard autoRefreshQuote else {
                    await model.loadInitialQuote(
                        persistedId: literatureTimeId,
                        currentDate: Date()
                    )

                    return
                }

                // Refresh on each minute boundary. Scoping the loop to `.task` ties
                // it to the view's lifetime, so it's cancelled automatically on
                // disappear or when auto-refresh is toggled off — no overlapping
                // tasks and no reentrancy window on the shared state. Sleeping until
                // the next minute (rather than polling) keeps the view idle in
                // between.
                while !Task.isCancelled {
                    let now = Date()
                    await model.autoRefreshIfMinuteChanged(currentDate: now)

                    let nextMinute =
                        Calendar.current.nextDate(
                            after: now,
                            matching: DateComponents(second: 0),
                            matchingPolicy: .nextTime
                        ) ?? now.addingTimeInterval(60)

                    do {
                        try await Task.sleep(
                            for: .seconds(max(nextMinute.timeIntervalSince(now), 0.1))
                        )
                    } catch {
                        break
                    }
                }
            }
        }
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
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
