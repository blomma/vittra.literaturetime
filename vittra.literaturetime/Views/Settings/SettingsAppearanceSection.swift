import Models
import SwiftUI

struct SettingsAppearanceSection: View {
    @AppStorage("\(Preferences.colorScheme)")
    private var colorScheme: Models.ColorScheme = .automatic

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        Section {
            if dynamicTypeSize.isAccessibilitySize {
                colorSchemePicker
                    .pickerStyle(.menu)
            } else {
                colorSchemePicker
                    .pickerStyle(.segmented)
            }
        } header: {
            Text("Appearance")
        } footer: {
            switch colorScheme {
            case .automatic:
                Text("Automatically switch between light and dark themes when your system does")
            case .light:
                Text("Always use light theme")
            case .dark:
                Text("Always use dark theme")
            }
        }
        .listRowBackground(Color(.literatureBackground))
    }

    private var colorSchemePicker: some View {
        Picker("Color scheme", selection: $colorScheme) {
            ForEach(Models.ColorScheme.allCases) { colorScheme in
                Text(colorScheme.rawValue.capitalized)
                    .tag(colorScheme)
            }
        }
    }
}
