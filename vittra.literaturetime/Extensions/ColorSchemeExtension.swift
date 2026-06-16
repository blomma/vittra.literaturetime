import Models
import SwiftUI

extension Models.ColorScheme {
    /// The SwiftUI color scheme to enforce, or `nil` to follow the system.
    var swiftUIColorScheme: SwiftUI.ColorScheme? {
        switch self {
            case .automatic: nil
            case .light: .light
            case .dark: .dark
        }
    }
}
