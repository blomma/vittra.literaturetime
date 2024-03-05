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
                generalSection
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
        } footer: {
            switch userPreferences.colorScheme {
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

    @ViewBuilder
    private var generalSection: some View {
        @Bindable var userPreferences = userPreferences
        Section {
            Toggle(isOn: $userPreferences.autoRefreshQuote) {
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

#if DEBUG
    #Preview("Light") {
        SettingsView()
            .preferredColorScheme(.light)
            .environment(UserPreferences())
    }

    #Preview("Dark") {
        SettingsView()
            .preferredColorScheme(.dark)
            .environment(UserPreferences())
    }
#endif
