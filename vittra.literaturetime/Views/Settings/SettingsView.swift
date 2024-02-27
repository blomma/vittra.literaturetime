import SwiftUI

@MainActor
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserPreferences.self) private var userPreferences

    var body: some View {
        NavigationStack {
            Form {
                appSection
                displaySection
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

    private var appSection: some View {
        Section {
            Link(destination: URL(string: "https://github.com/blomma/vittra.literaturetime")!) {
                Label("Source (GitHub)", systemImage: "link")
            }

            NavigationLink(destination: AboutView()) {
                Label("About", systemImage: "info.circle")
            }
        } header: {
            Text("App")
        } footer: {
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("App Version: \(appVersion)").frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listRowBackground(Color(.literatureBackground))
    }

    @ViewBuilder
    private var displaySection: some View {
        @Bindable var userPreferences = userPreferences
        Section {
            Picker("ColorScheme", selection: $userPreferences.colorScheme) {
                ForEach(ColorScheme.allCases) { colorScheme in
                    Text(colorScheme.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Apperance")
        }
        .listRowBackground(Color(.literatureBackground))
    }
}

#Preview("Light") {
    SettingsView()
        .preferredColorScheme(.light)
        .environment(UserPreferences.shared)
}

#Preview("Dark") {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(UserPreferences.shared)
}
