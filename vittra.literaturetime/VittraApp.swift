import Models
import Providers
import SwiftUI

@main
struct VittraApp: App {
    @AppStorage("\(Preferences.colorScheme)")
    private var colorScheme: Models.ColorScheme = .light

    @Environment(\.scenePhase)
    private var scenePhase

    let modelContainer = ModelProvider.shared.productionContainer

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: colorScheme) { _, _ in
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle =
                colorScheme == .automatic ? .unspecified
                    : colorScheme == .dark ? .dark : .light
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle =
                    colorScheme == .automatic ? .unspecified
                        : colorScheme == .dark ? .dark : .light
            }
        }
    }
}
