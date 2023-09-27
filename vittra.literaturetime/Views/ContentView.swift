import SwiftUI

struct ContentView: View {
    @State private var store = ContentViewStore(
        initialState: .init(),
        reducer: ContentViewReducer(),
        middlewares: [ContentViewMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            if !store.isLoading {
                LiteratureTimeView()
            }
        }
        .task {
            await store.send(.load)
        }
    }
}

#Preview("Light") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
