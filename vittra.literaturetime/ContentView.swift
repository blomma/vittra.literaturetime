import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text("It was ")
                            + Text("eight minutes to six o'clock")
                            .foregroundStyle(.literatureTime)

                            + Text(". “I must get him,” he told the telephone girl for the dozenth time.")

                        Text("“Sorry- no one will answer,” she said wearily.")
                    }
                    .font(.system(.largeTitle, design: .serif, weight: .regular))

                    HStack {
                        Text("- Jimmy Kirkland and the Plot for a Pennant, ")
                            + Text("Hugh S. Fullerton")
                            .italic()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .padding(10)
                .allowsTightening(false)
            }
            .foregroundStyle(.literature)
        }
    }
}

#Preview {
    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
}
