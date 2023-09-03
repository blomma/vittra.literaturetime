import Mimer
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

struct LiteratureTimeModel: Codable, Equatable {
    var time: String
    var quote_first: String
    var quote_time_case: String
    var quote_last: String
    var title: String
    var author: String
}

struct LiteratureTimeState: Equatable {
    var literatureTime: LiteratureTimeModel
}

enum LiteratureTimeAction: Equatable {
    case searchRandom(query: String)
    case setResults(literatureTime: LiteratureTimeModel)
}

struct LiteratureTimeReducer: Reducer {
    func reduce(oldState: LiteratureTimeState, with action: LiteratureTimeAction) -> LiteratureTimeState {
        var state = oldState

        switch action {
        case let .setResults(literatureTime):
            state.literatureTime = literatureTime
        default:
            return state
        }

        return state
    }
}

struct LiteratureTimeMiddleware: Middleware {
    struct Dependencies {
        var search: (String) async throws -> [LiteratureTimeModel]

        static var production: Dependencies {
            .init { query in
                guard let file = Bundle.main.path(forResource: query, ofType: "json", inDirectory: "Times")
                else {
                    return .init([])
                }

                let data = try String(contentsOfFile: file).data(using: .utf8)

                guard let data = data
                else {
                    return .init([])
                }

                return try JSONDecoder().decode([LiteratureTimeModel].self, from: data)
            }
        }
    }

    let dependencies: Dependencies

    func process(state: LiteratureTimeState, with action: LiteratureTimeAction) async -> LiteratureTimeAction? {
        switch action {
        case let .searchRandom(query):
            let results = try? await dependencies.search(query)

            guard !Task.isCancelled else {
                return .setResults(literatureTime: state.literatureTime)
            }

            let literatureTime = results?.randomElement()

            return .setResults(literatureTime: literatureTime ?? state.literatureTime)
        default:
            return nil
        }
    }
}

typealias LiteratureTimeStore = Store<LiteratureTimeState, LiteratureTimeAction>

struct LiteratureTimeView: View {
    @State private var store = LiteratureTimeStore(
        initialState: .init(
            literatureTime:
            LiteratureTimeModel(
                time: "",
                quote_first: "“Time is an illusion. Lunchtime doubly so.”",
                quote_time_case: "",
                quote_last: "",
                title: "The Hitchhiker's Guide to the Galaxy",
                author: "Douglas Adams"
            )),
        reducer: LiteratureTimeReducer(),
        middlewares: [LiteratureTimeMiddleware(dependencies: .production)]
    )

    var body: some View {
        ZStack {
            Color(.literatureBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(store.literatureTime.quote_first)
                            + Text(store.literatureTime.quote_time_case)
                            .foregroundStyle(.literatureTime)
                            + Text(store.literatureTime.quote_last)
                    }
                    .font(.system(.largeTitle, design: .serif, weight: .regular))

                    HStack {
                        Text("- \(store.literatureTime.title), ")
                            + Text(store.literatureTime.author)
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
        .task {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let fileName = "\(paddedHour)_\(paddedMinute)"

            await store.send(.searchRandom(query: fileName))
        }
        .refreshable {
            let hm = Calendar.current.dateComponents([.hour, .minute], from: Date())

            guard let hour = hm.hour, let minute = hm.minute else {
                return
            }

            let paddedHour = String(hour).leftPadding(toLength: 2, withPad: "0")
            let paddedMinute = String(minute).leftPadding(toLength: 2, withPad: "0")

            let fileName = "\(paddedHour)_\(paddedMinute)"

            await store.send(.searchRandom(query: fileName))
        }
    }
}

#Preview {
    LiteratureTimeView()
}
