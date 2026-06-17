import Models

/// A `LiteratureTimeProviding` stub that always returns a fixed quote, used to
/// drive SwiftUI previews (and tests) with deterministic content. Because it
/// satisfies every fetch with the same quote, the view's normal load path runs
/// unchanged and renders the injected quote instead of falling back.
public struct PreviewLiteratureTimeProvider: LiteratureTimeProviding {
    private let literatureTime: LiteratureTime

    public init(literatureTime: LiteratureTime) {
        self.literatureTime = literatureTime
    }

    public func fetchRandomForTimeExcluding(
        hour _: Int,
        minute _: Int,
        excludingIds _: Set<String>
    ) async throws -> Result<LiteratureTime, FetchLiteratureTimeError> {
        .success(literatureTime)
    }

    public func fetch(id _: String) async throws -> Result<LiteratureTime, FetchLiteratureTimeError> {
        .success(literatureTime)
    }
}
