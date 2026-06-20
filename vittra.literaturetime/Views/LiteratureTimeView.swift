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

    @Environment(\.scenePhase)
    private var scenePhase

    @Environment(\.accessibilityReduceMotion)
    private var accessibilityReduceMotion

    @Environment(\.accessibilityDifferentiateWithoutColor)
    private var accessibilityDifferentiateWithoutColor

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
                            "\(model.literatureTime.quoteFirst)\(Text(model.literatureTime.quoteTime).foregroundStyle(.literatureTime).underline(accessibilityDifferentiateWithoutColor))\(model.literatureTime.quoteLast)"
                        )
                    }
                    .font(.system(.title2, design: .serif, weight: .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(
                        Text(
                            "\(model.literatureTime.quoteFirst)\(model.literatureTime.quoteTime)\(model.literatureTime.quoteLast)"
                        )
                    )
                    .accessibilityCustomContent(
                        AccessibilityCustomContentKey("Time reference"),
                        model.literatureTime.quoteTime.isEmpty
                            ? nil
                            : Text(model.literatureTime.quoteTime)
                    )

                    HStack {
                        Text(
                            "- \(model.literatureTime.title), \(Text(model.literatureTime.author).italic())"
                        )
                        .accessibilityLabel(
                            Text(
                                "\(model.literatureTime.title), by \(model.literatureTime.author)"
                            )
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
                .animation(
                    accessibilityReduceMotion ? nil : .default,
                    value: model.literatureTime
                )
                .foregroundStyle(.literature)
                .contentShape(Rectangle())
                .accessibilityHidden(model.literatureTime.id.isEmpty)
                .contextMenu {
                    QuoteContextMenu(
                        literatureTime: model.literatureTime,
                        shouldPresentSettings: $shouldPresentSettings,
                        onCopy: { copyFeedbackTrigger += 1 },
                        onRefresh: {
                            Task { await refreshQuote() }
                        }
                    )
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, 64, for: .scrollContent)
            .accessibilityIdentifier("timelyQuote.home")
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
                await refreshQuote()
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
                    let previousId = model.literatureTime.id
                    await model.autoRefreshIfMinuteChanged(currentDate: now)

                    if !previousId.isEmpty,
                        model.literatureTime.id != previousId,
                        scenePhase == .active,
                        !shouldPresentSettings
                    {
                        AccessibilityNotification.Announcement(
                            "Quote updated for the current time"
                        ).post()
                    }

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
                    onCopy: { copyFeedbackTrigger += 1 },
                    onRefresh: {
                        Task { await refreshQuote() }
                    }
                )
            } label: {
                // Pin an explicit 48×48 hit target rather than deriving it from
                // the glyph's intrinsic size plus padding: this guarantees the
                // target stays above Apple's 44pt floor regardless of the symbol
                // or Dynamic Type mapping, and a rectangular content shape keeps
                // the corners — where an edge-arriving thumb lands — tappable.
                Image(systemName: "ellipsis.circle")
                    .font(.system(.title, weight: .thin))
                    // Tint with the app's single accent (the colour of the time
                    // word) rather than the prose colour: this reads as chrome,
                    // not content, and reuses the existing "accent = interactive"
                    // semantic. Held at 0.7 so it stays discoverable without
                    // pulling the eye off the quote.
                    .foregroundStyle(Color.literatureTime.opacity(0.6))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Quote actions")
            .accessibilityIdentifier("timelyQuote.quoteActions")
            .disabled(model.literatureTime.id.isEmpty)
            .accessibilityHidden(model.literatureTime.id.isEmpty)
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

    private func refreshQuote() async {
        let previousId = model.literatureTime.id

        await model.refreshRandomQuote(currentDate: Date())
        refreshFeedbackTrigger += 1

        let announcement =
            model.literatureTime.id == previousId
                ? "No different quote available for this time"
                : "Quote refreshed"

        AccessibilityNotification.Announcement(announcement).post()

        // `.refreshable` keeps the pull-to-refresh spinner visible until this
        // closure returns, then plays a retract animation. The fetch above is a
        // near-instant local lookup, so if the user pulls and immediately
        // switches apps, the closure can return while backgrounded — UIKit then
        // drops the retract animation (no active screen to run it on) and the
        // spinner stays stuck until the next pull. Hold the task open until the
        // app is active again so the spinner always dismisses on-screen.
        await waitUntilActive()
    }

    /// Suspends until a scene is foreground-active, returning immediately if
    /// one already is.
    ///
    /// Reads the scene-activation graph (`connectedScenes` +
    /// `UIScene.didActivateNotification`) rather than the app-global
    /// `UIApplication.applicationState`, so it stays correct when the app has
    /// more than one window. The `guard` reads the live state immediately
    /// before subscribing. Because the view is `@MainActor` and the observer
    /// is registered synchronously before the first suspension, no activation
    /// can be delivered in between, so there is no missed-notification window.
    ///
    /// The per-notification check is a `for await … break` rather than
    /// `first(where:)`: under Swift 6 strict concurrency the latter takes a
    /// `@concurrent` closure over the non-Sendable `Notification`, which is a
    /// data-race error. Cancellation terminates the sequence, so the loop exits
    /// and the function returns without any further state checks.
    private func waitUntilActive() async {
        guard !isForegroundActive else { return }

        for await _ in NotificationCenter.default.notifications(
            named: UIScene.didActivateNotification
        ) {
            if isForegroundActive { break }
        }
    }

    private var isForegroundActive: Bool {
        UIApplication.shared.connectedScenes.contains { scene in
            scene.activationState == .foregroundActive
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
