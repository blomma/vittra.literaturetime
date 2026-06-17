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

    @State
    private var copyFeedbackTrigger = 0

    @State
    private var refreshFeedbackTrigger = 0

    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Environment(\.colorScheme)
    private var colorScheme

    @State
    private var model: LiteratureTimeModel

    init(
        provider: any LiteratureTimeProviding = LiteratureTimeProvider(
            modelContainer: ModelProvider.shared.productionContainer
        )
    ) {
        _model = State(initialValue: LiteratureTimeModel(provider: provider))
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
                // Cap the text column to a comfortable measure rather than
                // padding by a fixed amount: on wide layouts (iPad, landscape)
                // a fixed inset still yields an over-long line that hurts
                // readability, so we constrain the width and centre the column.
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 30)
                .padding(.vertical, 45)
                .animation(.default, value: model.literatureTime)
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                // Read the quote and its attribution as a single, natural
                // utterance instead of two separate elements (and avoid the
                // leading hyphen being spoken as "dash").
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    Text(
                        "\(model.literatureTime.quoteFirst)\(model.literatureTime.quoteTime)\(model.literatureTime.quoteLast). \(model.literatureTime.title), by \(model.literatureTime.author)"
                    )
                )
                .contextMenu {
                    QuoteContextMenu(
                        literatureTime: model.literatureTime,
                        shouldPresentSettings: $shouldPresentSettings,
                        onCopy: { copyFeedbackTrigger += 1 }
                    )
                }
            }
            .scrollIndicators(.hidden)
            .foregroundStyle(.literature)
            .onChange(of: model.literatureTime) { _, newValue in
                // Persist whatever is shown so it can be restored on next
                // launch — including the placeholder, which carries a stable
                // sentinel id. Only the initial `.empty` state (empty id) is
                // skipped, so an empty persisted id keeps meaning "nothing has
                // been loaded yet".
                guard !newValue.id.isEmpty else { return }
                literatureTimeId = newValue.id
            }
            .refreshable {
                await model.refreshRandomQuote(currentDate: Date())
                refreshFeedbackTrigger += 1
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

            // Visible affordance mirroring the long-press context menu. A
            // context menu is an accelerator, not a primary path, so the same
            // actions need a discoverable control on the canvas; the menu
            // content is shared verbatim with `.contextMenu` above.
            Menu {
                QuoteContextMenu(
                    literatureTime: model.literatureTime,
                    shouldPresentSettings: $shouldPresentSettings,
                    onCopy: { copyFeedbackTrigger += 1 }
                )
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundStyle(.literature)
                    .padding(12)
                    .contentShape(Circle())
            }
            .accessibilityLabel("Quote actions")
            .padding(.trailing, horizontalSizeClass == .compact ? 12 : 80)
            .padding(.bottom, 8)
        }
        .sensoryFeedback(.success, trigger: copyFeedbackTrigger)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: refreshFeedbackTrigger)
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
                .preferredColorScheme(colorScheme)
        }
    }
}

#if DEBUG
#Preview("Light") {
    LiteratureTimeView(
        provider: PreviewLiteratureTimeProvider(literatureTime: .previewBig)
    )
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    LiteratureTimeView(
        provider: PreviewLiteratureTimeProvider(literatureTime: .previewSmall)
    )
    .preferredColorScheme(.dark)
}
#endif
