import SwiftUI

@main
struct VittraApp: App {
    @Environment(\.colorScheme) private var colorScheme
    @State var userPreferences = UserPreferences.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    userPreferences.colorScheme == .system ? .none
                        : userPreferences.colorScheme == .dark ? .dark : .light
                )
        }
        .environment(UserPreferences.shared)
    }
}
