import SwiftUI
import SwiftData

@main
struct vittra_literaturetimeApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Color(.literatureBackground))
       }
        .modelContainer(for: Item.self)
    }
}
