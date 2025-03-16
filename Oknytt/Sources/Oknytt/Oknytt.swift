import Foundation
import os

// get current dispatch queue label
public extension DispatchQueue {
    static var currentLabel: String {
        return String(validatingCString: __dispatch_queue_get_label(nil)) ?? "unknown"
    }
}

public extension Logger {
    func logf(
        level: OSLogType,
        message: String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        #if DEBUG
        if level == .debug {
            log(level: level, "🟩 \(file) : \(function) : \(line) : \(column) - \(message) 🟩")
        }
        #endif

        if level != .debug {
            log(level: level, "🟩 \(file) : \(function) : \(line) : \(column) - \(message) 🟩")
        }
    }
}
