import Models
import SwiftUI

struct SettingsView: View {
    @AppStorage("\(Preferences.colorScheme)")
    private var colorScheme: Models.ColorScheme = .light

    @AppStorage("\(Preferences.autoRefreshQuote)")
    private var autoRefreshQuote: Bool = false

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                SettingsAppSection()
                SettingsAppearanceSection()
                SettingsGeneralSection()
            }
            .scrollContentBackground(.hidden)
            .background(Color(.literatureBackground))
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.literatureBackground).opacity(0.30), for: .navigationBar)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done").bold()
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview("Light") {
    SettingsView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
}
#endif
