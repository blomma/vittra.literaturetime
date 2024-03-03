import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            LiteratureTimeView(model: .init(
                initialState: .empty,
                provider: LiteratureTimeProvider()
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
