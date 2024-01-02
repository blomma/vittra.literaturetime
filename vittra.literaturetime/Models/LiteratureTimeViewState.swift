struct LiteratureTimeViewState: Equatable {
    var time: String
    var quoteFirst: String
    var quoteTime: String
    var quoteLast: String
    var title: String
    var author: String
    var gutenbergReference: String
    var id: String
}

extension LiteratureTimeViewState: CustomStringConvertible {
    var description: String {
        return """
        \(quoteFirst)\(quoteTime)\(quoteLast)

        - \(title), \(author), \(gutenbergReference)
        """
    }
}

extension LiteratureTimeViewState {
    static var fallback: LiteratureTimeViewState {
        LiteratureTimeViewState(
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

    static var empty: LiteratureTimeViewState {
        LiteratureTimeViewState(
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
