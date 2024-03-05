import SwiftUI

@MainActor
struct ContentView: View {
    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            LiteratureTimeView()
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
