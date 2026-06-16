import Foundation
import LiteratureSchema
import SQLite3
import SwiftData

enum SeedError: Error {
    case sqlite(String)
}

func importLiteratureTime(fromFile: String, toStore: String) {
    do {
        let data = try Data(contentsOf: URL(filePath: fromFile))
        let imports = try JSONDecoder().decode([LiteratureTimeImport].self, from: data)

        // Seed into a scratch location first, then copy the finished single-file
        // store into place. Keeping this separate from the destination means a
        // failed run never leaves a half-written store behind.
        let workURL = URL.temporaryDirectory.appending(path: "literatureTimes-seed.store")
        try? FileManager.default.removeItem(at: workURL)

        try seed(imports, into: workURL)
        try consolidate(workURL)

        let destination = URL(filePath: toStore)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.copyItem(at: workURL, to: destination)
    } catch {
        fatalError("Failed to seed store: \(error)")
    }
}

/// Inserts every quote into a fresh SwiftData store using the same schema the app
/// reads with, so there is a single source of truth for the model.
private func seed(_ imports: [LiteratureTimeImport], into url: URL) throws {
    let container = try ModelContainer(
        for: Schema(CurrentScheme.models),
        configurations: [ModelConfiguration(url: url)]
    )
    let context = ModelContext(container)

    for item in imports {
        context.insert(
            CurrentScheme.LiteratureTime(
                time: item.time,
                quoteFirst: item.quoteFirst,
                quoteTime: item.quoteTime,
                quoteLast: item.quoteLast,
                title: item.title,
                author: item.author,
                gutenbergReference: item.gutenbergReference,
                id: item.hash
            )
        )
    }

    try context.save()
    // `container` is released here, closing SwiftData's connections so the
    // checkpoint below can take the store's write lock cleanly.
}

/// SwiftData writes in WAL mode, leaving `-wal`/`-shm` sidecar files. The app
/// opens the bundled store read-only, so fold the WAL back into the main file and
/// switch to a single-file journal — the SwiftData equivalent of the old Core Data
/// `journal_mode = DELETE`.
private func consolidate(_ url: URL) throws {
    var db: OpaquePointer?
    guard sqlite3_open(url.path, &db) == SQLITE_OK else {
        let message = db.map { String(cString: sqlite3_errmsg($0)) } ?? "open failed"
        sqlite3_close(db)
        throw SeedError.sqlite(message)
    }
    defer { sqlite3_close(db) }

    for pragma in ["PRAGMA wal_checkpoint(TRUNCATE);", "PRAGMA journal_mode=DELETE;"] {
        guard sqlite3_exec(db, pragma, nil, nil, nil) == SQLITE_OK else {
            throw SeedError.sqlite(String(cString: sqlite3_errmsg(db)))
        }
    }
}
