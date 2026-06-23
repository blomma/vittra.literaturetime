import Models

/// Abstracts quote lookups so views and the view model can be driven by a real
/// SwiftData-backed provider in production and by a fixed-quote stub in previews
/// and tests, without branching on the environment.
public protocol LiteratureTimeProviding: Sendable {
    func fetchRandomForTimeExcluding(
        hour: Int,
        minute: Int,
        excludingIds: Set<String>,
    ) async throws -> Result<LiteratureTime, FetchLiteratureTimeError>

    func fetch(id: String) async throws -> Result<LiteratureTime, FetchLiteratureTimeError>
}
