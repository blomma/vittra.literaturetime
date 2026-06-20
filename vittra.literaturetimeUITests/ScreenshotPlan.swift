import CoreGraphics
import Foundation

struct ScreenshotPlan: Sendable {
    struct Screen: Sendable {
        let name: String
        let caption: String
    }

    enum Device: String, CaseIterable, Sendable {
        case iPhone6_7 = "iPhone_6.7"
        case iPad12_9 = "iPad_12.9"

        var simulatorName: String {
            switch self {
            case .iPhone6_7: "iPhone 17 Pro Max"
            case .iPad12_9: "iPad Pro 13-inch (M5)"
            }
        }

        var screenshotSize: CGSize {
            switch self {
            case .iPhone6_7: CGSize(width: 1290, height: 2796)
            case .iPad12_9: CGSize(width: 2048, height: 2732)
            }
        }
    }

    static let locale = "en-US"
    static let literatureTimeID =
        "60ec21b8053497f65e26250aa9427618c56229c23aa0cff6aed4da8f47d5bac1"
    static let screens = [
        Screen(name: "01_LiteraryClock", caption: "A literary clock for your day"),
        Screen(name: "02_Personalize", caption: "A new book quote every minute"),
        Screen(name: "03_DarkMode", caption: "Light or dark, made for reading"),
        Screen(name: "04_ReadTheBook", caption: "Read the whole book, free"),
        Screen(name: "05_OpenSource", caption: "Private. No ads. Open source."),
    ]
    static let devices = Device.allCases
}
