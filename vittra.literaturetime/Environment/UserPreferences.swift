import Foundation
import SwiftUI

public enum ColorScheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    public var id: Self { self }
}

@MainActor
@Observable
public final class UserPreferences {
    class UserPreferencesStorage {
        @AppStorage("colorScheme")
        public var colorScheme: ColorScheme = .light
    }

    private let userPreferencesStorage = UserPreferencesStorage()

    public static let shared = UserPreferences()

    public var colorScheme: ColorScheme {
        didSet {
            userPreferencesStorage.colorScheme = colorScheme
        }
    }

    private init() {
        colorScheme = userPreferencesStorage.colorScheme
    }
}
