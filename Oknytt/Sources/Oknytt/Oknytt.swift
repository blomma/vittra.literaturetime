import Foundation
import os

// get current dispatch queue label
extension DispatchQueue {
    public static var currentLabel: String {
        return String(validatingCString: __dispatch_queue_get_label(nil)) ?? "unknown"
    }
}

extension Logger {
    public func logf(
        level: OSLogType,
        message: String,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        #if DEBUG
        if level == .debug {
            self.log(level: level, "🟩 \(file) : \(function) : \(line) : \(column) - \(message) 🟩")
        }
        #endif

        if level != .debug {
            self.log(level: level, "🟩 \(file) : \(function) : \(line) : \(column) - \(message) 🟩")
        }
    }
}
