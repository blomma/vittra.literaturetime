#!/usr/bin/env swift

import Foundation

struct CommandFailure: Error, CustomStringConvertible {
    let command: [String]
    let status: Int32

    var description: String { "Command failed (\(status)): \(command.joined(separator: " "))" }
}

@discardableResult
func run(_ executable: String, _ arguments: [String], environment: [String: String]? = nil) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    if let environment { process.environment = environment }

    let output = Pipe()
    process.standardOutput = output
    process.standardError = FileHandle.standardError
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw CommandFailure(command: [executable] + arguments, status: process.terminationStatus)
    }
    return String(decoding: data, as: UTF8.self)
}

func attachmentRecords(in value: Any) -> [(exported: String, suggested: String)] {
    if let dictionary = value as? [String: Any] {
        var records: [(String, String)] = []
        if let exported = dictionary["exportedFileName"] as? String,
           let suggested = dictionary["suggestedHumanReadableName"] as? String {
            records.append((exported, suggested))
        }
        return records + dictionary.values.flatMap(attachmentRecords)
    }
    if let array = value as? [Any] {
        return array.flatMap(attachmentRecords)
    }
    return []
}

func simulatorUDID(named name: String, osVersion: String) throws -> String {
    let json = try run("/usr/bin/xcrun", ["simctl", "list", "devices", "available", "-j"])
    let root = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
    let devices = root?["devices"] as? [String: [[String: Any]]]
    let runtimeSuffix = "iOS-" + osVersion.replacingOccurrences(of: ".", with: "-")

    for (runtime, candidates) in devices ?? [:] where runtime.hasSuffix(runtimeSuffix) {
        if let match = candidates.first(where: { $0["name"] as? String == name }),
           let udid = match["udid"] as? String {
            return udid
        }
    }
    throw CocoaError(.fileNoSuchFile, userInfo: [
        NSLocalizedDescriptionKey: "No \(name) simulator is installed for iOS \(osVersion)",
    ])
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let automation = root.appendingPathComponent("ScreenshotAutomation")
let rawRoot = root.appendingPathComponent("screenshots/raw")
let outputRoot = root.appendingPathComponent("screenshots/en-US")
let processor = FileManager.default.temporaryDirectory.appendingPathComponent("timely-quote-screenshot-processor")

try? FileManager.default.removeItem(at: rawRoot)
try? FileManager.default.removeItem(at: outputRoot)
try FileManager.default.createDirectory(at: rawRoot, withIntermediateDirectories: true)

try run("/usr/bin/xcrun", [
    "swiftc",
    "-module-cache-path", FileManager.default.temporaryDirectory.appendingPathComponent("timely-quote-module-cache").path,
    root.appendingPathComponent("vittra.literaturetimeUITests/ScreenshotPlan.swift").path,
    automation.appendingPathComponent("CaptionOverlay.swift").path,
    automation.appendingPathComponent("ScreenshotProcessor.swift").path,
    "-o", processor.path,
])

let devices: [(rawValue: String, simulator: String)] = [
    ("iPhone_6.7", ProcessInfo.processInfo.environment["SCREENSHOT_IPHONE_SIMULATOR"] ?? "iPhone 17 Pro Max"),
    ("iPad_12.9", ProcessInfo.processInfo.environment["SCREENSHOT_IPAD_SIMULATOR"] ?? "iPad Pro 13-inch (M5)"),
]
let screenNames = ["01_LiteraryClock", "02_Personalize", "03_DarkMode", "04_ReadTheBook", "05_OpenSource"]
let simulatorOS = ProcessInfo.processInfo.environment["SCREENSHOT_SIMULATOR_OS"] ?? "26.5"

for device in devices {
    let simulatorUDID = try simulatorUDID(named: device.simulator, osVersion: simulatorOS)
    let resultBundle = rawRoot.appendingPathComponent("\(device.rawValue).xcresult")
    let attachments = rawRoot.appendingPathComponent(device.rawValue)

    try? run("/usr/bin/xcrun", ["simctl", "boot", simulatorUDID])
    try run("/usr/bin/xcrun", ["simctl", "bootstatus", simulatorUDID, "-b"])
    try run("/usr/bin/xcrun", [
        "simctl", "status_bar", simulatorUDID, "override",
        "--time", "10:38", "--batteryState", "charged", "--batteryLevel", "100",
        "--wifiBars", "3", "--cellularBars", "4",
    ])

    try run("/usr/bin/xcodebuild", [
        "test",
        "-project", "vittra.literaturetime.xcodeproj",
        "-scheme", "vittra.literaturetime",
        "-testPlan", "ScreenshotTests",
        "-destination", "platform=iOS Simulator,id=\(simulatorUDID)",
        "-resultBundlePath", resultBundle.path,
        "-derivedDataPath", root.appendingPathComponent(".build/ScreenshotDerivedData").path,
    ])

    try run("/usr/bin/xcrun", [
        "xcresulttool", "export", "attachments",
        "--path", resultBundle.path,
        "--output-path", attachments.path,
    ])

    let manifestData = try Data(contentsOf: attachments.appendingPathComponent("manifest.json"))
    let manifest = try JSONSerialization.jsonObject(with: manifestData)
    for record in attachmentRecords(in: manifest) {
        guard record.exported.hasSuffix(".png"),
              let screen = screenNames.first(where: { record.suggested.contains("__\($0)_") })
        else { continue }
        let input = attachments.appendingPathComponent(record.exported)
        let output = outputRoot
            .appendingPathComponent(device.rawValue)
            .appendingPathComponent("\(screen).png")
        try run(processor.path, [input.path, output.path, device.rawValue, screen])
    }

    try? run("/usr/bin/xcrun", ["simctl", "status_bar", simulatorUDID, "clear"])
}

print("Screenshots exported to \(outputRoot.path)")
