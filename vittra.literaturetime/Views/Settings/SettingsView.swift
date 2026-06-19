import SwiftUI

struct SettingsView: View {
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
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done").bold()
                    }
                }
            }
        }
        .accessibilityIdentifier("timelyQuote.settings")
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
