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
        "65a6e80ec9faf825244bab5f261c1e5230f82813492900612015eaef4d6f5b0c"
    static let screens = [
        Screen(name: "01_LiteraryClock", caption: "Literature meets the moment"),
        Screen(name: "02_Personalize", caption: "Make every quote yours"),
        Screen(name: "03_DarkMode", caption: "Beautiful in every light"),
    ]
    static let devices = Device.allCases
}
