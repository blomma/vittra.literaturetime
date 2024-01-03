import SwiftData

struct LiteratureTime: Equatable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
    var gutenbergReference: String
    var id: String
}

extension LiteratureTime: CustomStringConvertible {
    var description: String {
        return """
        \(quoteFirst)\(quoteTime)\(quoteLast)

        - \(title), \(author), \(gutenbergReference)
        """
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
            gutenbergReference: "",
            id: ""
        )
    }

    static var empty: LiteratureTime {
        LiteratureTime(
            time: "",
            quoteFirst: "",
            quoteTime: "",
            quoteLast: "",
            title: "",
            author: "",
            gutenbergReference: "",
            id: ""
        )
    }
}

enum Database {
    @Model
    final class LiteratureTime: Equatable {
        var time: String
        var quoteFirst: String
        var quoteTime: String
        var quoteLast: String
        var title: String
        var author: String
        var gutenbergReference: String
        var id: String

        init(time: String, quoteFirst: String, quoteTime: String, quoteLast: String, title: String, author: String, gutenbergReference: String, id: String) {
            self.time = time
            self.quoteFirst = quoteFirst
            self.quoteTime = quoteTime
            self.quoteLast = quoteLast
            self.title = title
            self.author = author
            self.gutenbergReference = gutenbergReference
            self.id = id
        }
    }
}
