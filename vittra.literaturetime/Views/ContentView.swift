import Models
import Providers
import SwiftUI

@MainActor
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            LiteratureTimeView(model: .init(
                initialState: LiteratureTime.empty,
                provider: LiteratureTimeProvider(modelContext: modelContext)
            ))
        }
    }
}

#if DEBUG
#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
#endif
