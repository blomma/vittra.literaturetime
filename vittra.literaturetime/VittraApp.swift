import Models
import Providers
import SwiftUI
import os

let subsystem = Bundle.main.bundleIdentifier!
let logger = Logger(subsystem: subsystem, category: "")

@main
struct VittraApp: App {
    @AppStorage("\(Preferences.colorScheme)")
    private var colorScheme: Models.ColorScheme = .light

    @Environment(\.scenePhase)
    private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: colorScheme) { _, _ in
            UIApplication.shared.keyWindow?.overrideUserInterfaceStyle =
                colorScheme == .automatic
                ? .unspecified
                : colorScheme == .dark ? .dark : .light
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                UIApplication.shared.keyWindow?.overrideUserInterfaceStyle =
                    colorScheme == .automatic
                    ? .unspecified
                    : colorScheme == .dark ? .dark : .light
            }
        }
    }
}
