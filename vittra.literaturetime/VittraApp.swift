import SwiftUI

@main
struct VittraApp: App {
    @State var userPreferences = UserPreferences.shared

    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: userPreferences.colorScheme) { _, _ in
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle =
                userPreferences.colorScheme == .automatic ? .unspecified
                    : userPreferences.colorScheme == .dark ? .dark : .light
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle =
                    userPreferences.colorScheme == .automatic ? .unspecified
                        : userPreferences.colorScheme == .dark ? .dark : .light
            }
        }
        .environment(UserPreferences.shared)
    }
}
