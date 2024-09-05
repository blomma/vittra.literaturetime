import SwiftUI

@MainActor
struct AboutView: View {
    let versionNumber: String

    init() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionNumber = version + " "
        } else {
            versionNumber = ""
        }
    }

    var body: some View {
        List {
            Section {
                Text("Timely quote is an open-source application for showing quotes taken from the books of project gutenberg, the twist is that the quotes in question have a reference to the current time of day.")
                    .font(.system(.callout, design: .default, weight: .regular))
                    .foregroundStyle(.literature)
            }
            .listRowBackground(Color(.literatureBackground))

            Section {
                Link(destination: URL(string: "https://github.com/blomma/vittra.literaturetime/blob/main/PRIVACY.md")!) {
                    Label("Privacy Policy", systemImage: "lock")
                }
                Link(destination: URL(string: "https://github.com/blomma/vittra.literaturetime/blob/main/LICENSE")!) {
                    Label("License", systemImage: "checkmark.shield")
                }
            } footer: {
                Text("\(versionNumber)©2024 Mikael Hultgren")
            }
            .listRowBackground(Color(.literatureBackground))

            Section {
                Text("""
                • [Project Gutenberg](https://www.gutenberg.org)

                • [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
                """)
                .multilineTextAlignment(.leading)
            } header: {
                Text("Timely Quote is built with the following open source projects:")
                    .textCase(nil)
            }
            .listRowBackground(Color(.literatureBackground))
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.literatureBackground))
        .navigationTitle(Text("Timely Quote"))
        .navigationBarTitleDisplayMode(.large)
    }
}

#if DEBUG
#Preview {
    AboutView()
}
#endif
