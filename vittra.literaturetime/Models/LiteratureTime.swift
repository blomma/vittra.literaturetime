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
