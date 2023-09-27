import SwiftUI

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(suffix(toLength))
        }
    }
}

struct LiteratureTimeView: View {
    @State var store = LiteratureTimeViewStore(
        initialState: .init(),
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading) {
                    
                    let literatureTime = store.literatureTime ?? LiteratureTime.fallback
                    
                    VStack(alignment: .leading) {
                        Text(literatureTime.quoteFirst)
                            + Text(literatureTime.quoteTime)
                            .foregroundStyle(.literatureTime)
                            + Text(literatureTime.quoteLast)
                    }
                    .font(.system(.title, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(literatureTime.title), ")
                            + Text(literatureTime.author)
                            .italic()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .font(.system(.footnote, design: .serif, weight: .regular))
                }
                .padding(25)
                .padding(.top, 10)
                .allowsTightening(false)
            }
            .foregroundStyle(.literature)
        }
        .task {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            await store.send(.searchRandom(query: query))
        }
        .refreshable {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let query = "\(paddedHour):\(paddedMinute)"

            await store.send(.searchRandom(query: query))
        }
    }
}

#Preview {
    LiteratureTimeView(store: .init(
        initialState: .init(),
        reducer: LiteratureTimeViewReducer(),
        middlewares: [LiteratureTimeViewMiddleware(dependencies: .preview)]
    ))
    .modelContainer(ModelContexts.previewContainer)
}
