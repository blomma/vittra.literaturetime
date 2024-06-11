import Foundation
import os

let subsystem = Bundle.main.bundleIdentifier!
let logger = Logger(subsystem: subsystem, category: "DEBUG")

public func DLog(
    message: String,
    view: String = "",
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    #if DEBUG
    logger.debug("🟩 \(file) : \(view) : \(function) : \(line) : \(column) - \(message) 🟩")
    #endif
}

// get current dispatch queue label
public extension DispatchQueue {
    static var currentLabel: String {
        return String(validatingCString: __dispatch_queue_get_label(nil)) ?? "unknown"
    }
}
