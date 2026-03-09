import Models
import SwiftUI

struct SettingsAppearanceSection: View {
    @AppStorage("\(Preferences.colorScheme)")
    private var colorScheme: Models.ColorScheme = .light

    var body: some View {
        Section {
            Picker("ColorScheme", selection: $colorScheme) {
                ForEach(Models.ColorScheme.allCases) { colorScheme in
                    Text(colorScheme.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Apperance")
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
}
