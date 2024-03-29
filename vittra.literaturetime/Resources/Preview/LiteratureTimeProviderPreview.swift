struct LiteratureTimeProviderPreview: LiteratureTimeViewProviding {}

extension LiteratureTimeProviderPreview {
    func fetchRandom(hour _: Int, minute _: Int, excludingId _: String) throws -> LiteratureTime? {
        return LiteratureTime(
            time: "21:05",
            quoteFirst: "It was ",
            quoteTime: "five minutes past nine",
            quoteLast: " when I entered our joint sitting-room for breakfast on the following morning.",
            title: "The Murder on the Links",
            author: "Agatha Christie",
            gutenbergReference: "58866",
            id: "e42d5465bc978b08ec08d6711a0bc165d5381eaeaced8321fb33b95c85b97157"
        )
    }

    func fetch(id _: String) throws -> LiteratureTime? {
        return LiteratureTime(
            time: "21:05",
            quoteFirst: "It was ",
            quoteTime: "five minutes past nine",
            quoteLast: " when I entered our joint sitting-room for breakfast on the following morning.",
            title: "The Murder on the Links",
            author: "Agatha Christie",
            gutenbergReference: "58866",
            id: "e42d5465bc978b08ec08d6711a0bc165d5381eaeaced8321fb33b95c85b97157"
        )
    }
}
