# SwiftUI accessibility audit checklist

Scope: `vittra.literaturetime` iOS/iPadOS SwiftUI target (deployment target iOS 18.6).

## VoiceOver

- [ ] Launch with VoiceOver enabled and confirm the quote is announced once as quote, title, and author; no leading dash is spoken.
- [ ] Open VoiceOver's **More Content** rotor for the quote and confirm the highlighted phrase is available once as **Time reference**, without being repeated in the primary announcement.
- [ ] Before the initial quote finishes loading, confirm **Loading quote** is exposed once and no empty or malformed quote element is exposed.
- [ ] After loading, confirm the loading status disappears and focus can move to the quote and **Quote actions**.
- [ ] Focus **Quote actions** and confirm it opens the same Share, Copy, Gutenberg (when available), and Settings actions as the context menu.
- [ ] Activate **Copy quote** and **Copy link to Gutenberg** and confirm “Quote copied” or “Link copied” is announced once.
- [ ] Confirm Settings and About sections, links, toggles, picker, navigation controls, and version text follow visual reading order without duplicate labels.

## Voice Control and Switch Control

- [ ] Say “Tap Quote actions,” “Tap Share quote,” “Tap Copy quote,” and “Tap Settings”; confirm each visible control can be activated by its spoken name.
- [ ] With Switch Control, scan the quote screen and Settings; confirm every action is reached once and no action requires pull-to-refresh or a long press.
- [ ] Confirm the quote can be refreshed through an accessible action in addition to the pull gesture.
- [ ] Refresh when no different quote is available; confirm the app does not announce a successful refresh and instead reports that no different quote is available.

## Dynamic Type and layout

- [ ] Test Default, XXXL, Accessibility 3, and Accessibility 5 text sizes on the smallest supported iPhone and in iPad Split View.
- [ ] Confirm the complete quote and attribution scroll vertically without clipping or horizontal scrolling.
- [ ] Confirm the appearance picker’s three choices remain readable and operable at Accessibility 5.
- [ ] Confirm all controls remain at least approximately 44×44 points and do not overlap the quote.

## Color and differentiation

- [ ] Test Light, Dark, Increase Contrast, Differentiate Without Color, and Smart Invert.
- [ ] Confirm body text, links, controls, and the highlighted time meet contrast requirements against `LiteratureBackground`.
- [ ] Confirm the highlighted time remains identifiable without relying only on color.

## Motion and feedback

- [ ] With Reduce Motion enabled, refresh and auto-refresh the quote; confirm the quote change does not animate.
- [ ] With haptics disabled or unavailable, confirm copy operations still provide the spoken announcement.

## Regression expectation

Quote selection, refresh timing, sharing, copying, navigation, settings persistence, visible copy, and layout should remain unchanged except where an accessibility fix explicitly adds semantics, discoverability, or a non-color cue.
