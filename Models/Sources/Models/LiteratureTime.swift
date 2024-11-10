public struct LiteratureTime: Equatable {
    public var time: String
    public var quoteFirst: String
    public var quoteTime: String
    public var quoteLast: String
    public var title: String
    public var author: String
    public var gutenbergReference: String
    public var id: String

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

extension LiteratureTime {
    public static var fallback: LiteratureTime {
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

    public static var empty: LiteratureTime {
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
