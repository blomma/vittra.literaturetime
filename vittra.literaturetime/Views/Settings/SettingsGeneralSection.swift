import Models
import SwiftUI

struct SettingsGeneralSection: View {
    @AppStorage("\(Preferences.autoRefreshQuote)")
    private var autoRefreshQuote: Bool = false

    var body: some View {
        Section {
            Toggle(isOn: $autoRefreshQuote) {
                Label("Auto refresh quote", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("General")
        } footer: {
            Text("Automatically refresh quote shown every minute on the minute")
        }
        .listRowBackground(Color(.literatureBackground))
    }
}
