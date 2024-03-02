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
            if userPreferences.colorScheme != .system {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = userPreferences.colorScheme == .dark ? .dark : .light
            } else {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .unspecified
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if userPreferences.colorScheme != .system {
                    UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = userPreferences.colorScheme == .dark ? .dark : .light
                } else {
                    UIApplication.shared.keyWindow?.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
        .environment(UserPreferences.shared)
    }
}
