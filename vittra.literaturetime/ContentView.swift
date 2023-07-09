import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(.literatureBackground)
            
            VStack(alignment: .leading) {
                Text("It was ")
                + Text("eight minutes to six o'clock")
                    .foregroundStyle(.red)
                + Text(". “I must get him,” he told the telephone girl for the dozenth time.")
                
                Text("“Sorry- no one will answer,” she said wearily.")
                
                Text("- Jimmy Kirkland and the Plot for a Pennant, ")
                    .font(.system(size: 12, weight: .light, design: .serif))
                + Text("Hugh S. Fullerton")
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .italic()
            }
        }
        .ignoresSafeArea()
        
    }
}

#Preview {
    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
}
