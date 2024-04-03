import Foundation
import SwiftUI

public enum ColorScheme: String, CaseIterable, Identifiable {
    case automatic
    case light
    case dark

    public var id: Self { self }
}

public enum Preferences: String, CaseIterable, Identifiable {
    case colorScheme
    case autoRefreshQuote
    case literatureTimeId

    public var id: Self { self }
}
