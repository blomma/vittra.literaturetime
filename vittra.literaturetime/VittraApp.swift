import Models
import SwiftUI
import os

let subsystem = Bundle.main.bundleIdentifier!
let logger = Logger(subsystem: subsystem, category: "")

@main
struct VittraApp: App {
    @AppStorage("\(Preferences.colorScheme)")
    private var colorScheme: Models.ColorScheme = .light

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme.swiftUIColorScheme)
        }
    }
}
