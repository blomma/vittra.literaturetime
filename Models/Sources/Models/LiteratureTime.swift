public struct LiteratureTime: Equatable, Sendable {
    public let time: String
    public let quoteFirst: String
    public let quoteTime: String
    public let quoteLast: String
    public let title: String
    public let author: String
    public let gutenbergReference: String
    public let id: String

    public init(
        time: String,
        quoteFirst: String,
        quoteTime: String,
        quoteLast: String,
        title: String,
        author: String,
        gutenbergReference: String,
        id: String
    ) {
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

extension LiteratureTime: CustomStringConvertible {
    public var description: String {
        return """
            \(quoteFirst)\(quoteTime)\(quoteLast)

            - \(title), \(author), \(gutenbergReference)
            """
    }
}

public extension LiteratureTime {
    static var fallback: LiteratureTime {
        LiteratureTime(
            time: "",
            quoteFirst:
                "Apologies, a quote has not yet been unearthed for the current time, instead, for now, I leave you with this quote from Douglas Adams.\n\n\n",
            quoteTime: "",
            quoteLast: "“Time is an illusion. Lunchtime doubly so.”",
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
