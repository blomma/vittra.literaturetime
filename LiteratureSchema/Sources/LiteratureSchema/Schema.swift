import SwiftData

public typealias CurrentScheme = SchemaV1

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    public static var models: [any PersistentModel.Type] {
        [LiteratureTime.self]
    }

    @Model
    public final class LiteratureTime {
        #Index<LiteratureTime>([\.time], [\.id])

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
            id: String,
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
}
