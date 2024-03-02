import SwiftUI

extension UIApplication {
    /// https://stackoverflow.com/a/58031897
    ///
    /// As this thread keeps getting traffic three years later,
    /// I want to share what I consider the most elegant solution with current functionality.
    /// It also works with SwiftUI.
    ///
    /// # iOS 16-17, compatible down to iOS 15
    ///
    /// ```
    /// UIApplication
    ///     .shared
    ///     .connectedScenes
    ///     .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    ///     .last
    /// ```
    /// # iOS 15 and 16, compatible down to iOS 13
    ///
    /// ```
    /// UIApplication
    ///     .shared
    ///     .connectedScenes
    ///     .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
    ///     .last { $0.isKeyWindow }
    /// ```
    /// Note that connectedScenes is available only since iOS 13. If you need to support
    /// earlier versions of iOS, you have to place this in an if #available(iOS 13, *) statement.
    ///
    /// A variant that is longer, but easier to understand:
    /// ```
    /// UIApplication
    ///     .shared
    ///     .connectedScenes
    ///     .compactMap { $0 as? UIWindowScene }
    ///     .flatMap { $0.windows }
    ///     .last { $0.isKeyWindow }
    /// ```
    ///
    /// Earlier versions of this answer selected the first instead of the last of multiple
    /// key windows. As @TengL and @Rob pointed out in comments, this might lead to
    /// inconsistent behavior. Even worse, the iOS 13 / 14 solution would select a window
    /// that could be hidden behind another. The iOS 16 / 15 solutions might also lead to
    /// such an issue, though there is no exact specification.
    /// I have therefore updated all four solution variants in order to increase the chance
    /// that the selected key window is actually visible. This should be good enough for most
    /// apps running on iOS. More precise control for apps on iPadOS, particularly when they
    /// run on macOS, can be obtained by ordering scenes by their activationState or their custom function.
    var keyWindow: UIWindow? {
        return
            // Get connected scenes
            connectedScenes
            // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .last
    }
}
