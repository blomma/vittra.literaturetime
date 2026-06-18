# TODO

## Platform Expansion (PLAT)

- [ ] **PLAT-1 · WidgetKit widget (Lock Screen / Home Screen / StandBy)** — A quote tied to the current minute is the canonical widget use case. Map the per-minute model onto a `TimelineProvider`. No widget extension exists today; highest-leverage surface to add.
  - Constraint: WidgetKit will not honour a literal per-minute refresh (daily budget is ~40–70 reloads). Precompute a `Timeline` of entries — one per minute for a forward window (e.g. the next 60 min) — and call `reloadTimeline` when the window is exhausted. Each entry should be self-contained so the system can advance through them without a process wake.
  - Constraint: the SwiftData store is loaded from `Bundle.main` (`ModelProvider.productionContainer`, subdirectory `Quotes`). A widget extension has its own bundle, so it cannot read the app's bundled store. Either add `literatureTimes.store` as a resource to the widget target, or relocate it into a shared App Group container and read from there. `Providers` / `Models` / `LiteratureSchema` are otherwise reusable as-is.
- [ ] **PLAT-2 · watchOS app + complication / Smart Stack** — No watch target exists (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`). A glanceable literary quote suits watchOS well. The `Providers` / `Models` / `LiteratureSchema` packages are already cleanly separated, so the data layer is reusable; the lift is a watch UI plus a complication.
  - Note: complications are WidgetKit-based on modern watchOS (ClockKit is deprecated), so the same timeline-budget and shared-store constraints from PLAT-1 apply. A short attributed quote fragment fits `.accessoryRectangular`; longer quotes need truncation tuned per family.

## Accessibility (A11Y)

- [ ] **A11Y-1 · Time fragment is distinguished by colour alone** — `quoteTime` is rendered only with `.foregroundStyle(.literatureTime)` (`LiteratureTimeView.swift:50`). Colour-only encoding is invisible to colour-vision-deficient users and washes out under Increase Contrast. VoiceOver is unaffected (the combined label reads the whole quote), but verify the `.literatureTime` vs `.literature` contrast ratio in both schemes; consider a second, subtle cue if it fails.
- [ ] **A11Y-2 · Quote cross-fade ignores Reduce Motion** — `.animation(.default, value: model.literatureTime)` (`LiteratureTimeView.swift:73`) animates every quote swap. Gate it on `@Environment(\.accessibilityReduceMotion)` and fall back to no animation (or a plain opacity change) when it's enabled.

## UX Polish (UX)

- [ ] **UX-1 · Blank-then-pop on cold launch** — the model starts at `.empty` and the first real quote animates in, so the first frame is empty canvas. A redacted/placeholder treatment (or suppressing the entry animation for the very first load) would remove the flash.
- [ ] **UX-2 · Possible brief stale-quote flash on foregrounding (auto-refresh on)** — the per-minute `.task` loop sleeps with `Task.sleep(for:)`, whose default `ContinuousClock` keeps advancing while the app is suspended, so on foreground the overdue deadline fires almost immediately and `autoRefreshIfMinuteChanged` catches up within a frame or two — not "until the next minute boundary". The residual is a possible sub-second flash of the previous quote before the resumed loop updates it. To make the update synchronous at the moment of foregrounding, add an `onChange(of: scenePhase)` handler scoped to `autoRefreshQuote == true` that calls `autoRefreshIfMinuteChanged(currentDate:)`. Note this overlaps the loop's own catch-up (both `@MainActor`, worst case a redundant fetch) and reintroduces the `scenePhase` dependency, so only worth it if the flash is observed in practice. (The previously removed `!autoRefreshQuote`-gated handler never applied to this case.)

## Internationalisation (INTL)

- [ ] **INTL-1 · No String Catalog** — all user-facing copy is inline English string literals. SwiftUI `Text` is localizable by default, so adding an `.xcstrings` catalog unlocks translation with almost no code change; without one the app is English-only despite being structurally ready.

## Tech Debt (TECH)

- [x] **TECH-1 · Stray capabilities in the app config** — `VittraApp.entitlements` declares `aps-environment` (push) and empty iCloud container/service arrays, and `Info.plist` declares an empty `UIBackgroundModes`. None are used by the app. Remove them to avoid provisioning friction and App Review questions about unused entitlements.
- [ ] **TECH-2 · `refreshRandomQuote` exclusion logic is hard to follow** — the multi-branch, double-fetch retry in `LiteratureTimeModel.refreshRandomQuote` (`LiteratureTimeModel.swift:43`) encodes several subtle cases (no results, only-current excluded, more-than-current excluded) inline. Simplify/extract before this logic is duplicated into the widget and watch targets.
