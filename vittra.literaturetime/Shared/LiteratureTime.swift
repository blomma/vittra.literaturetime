import Foundation
import SwiftData

@Model
final class LiteratureTime: Equatable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
    var id: String

    init(time: String, quoteFirst: String, quoteTime: String, quoteLast: String, title: String, author: String, id: String) {
        self.time = time
        self.quoteFirst = quoteFirst
        self.quoteTime = quoteTime
        self.quoteLast = quoteLast
        self.title = title
        self.author = author
        self.id = id
    }
}

extension LiteratureTime {
    static var fallback: LiteratureTime {
        LiteratureTime(
            time: "",
            quoteFirst: "“Time is an illusion. Lunchtime doubly so.”",
            quoteTime: "",
            quoteLast: "",
            title: "The Hitchhiker's Guide to the Galaxy",
            author: "Douglas Adams",
            id: ""
        )
    }
}
