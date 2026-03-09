import Models
import SwiftUI

struct SettingsAppSection: View {
    var body: some View {
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
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
                as? String,
                let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            {
                Text("App Version: \(appVersion).\(buildVersion)")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .listRowBackground(Color(.literatureBackground))
    }
}
