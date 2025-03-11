import Models
import Providers
import SwiftUI

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
