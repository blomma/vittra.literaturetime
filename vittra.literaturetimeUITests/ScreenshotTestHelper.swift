import XCTest

struct ScreenshotTestHelper {
    @MainActor
    func launch(_ app: XCUIApplication, appearance: String = "light") {
        let appearance = appearance.lowercased()
        XCUIDevice.shared.appearance = appearance == "dark" ? .dark : .light

        app.launchArguments = [
            "-autoRefreshQuote", "false",
            "-literatureTimeId", ScreenshotPlan.literatureTimeID,
            "-colorScheme", appearance,
            "-AppleLanguages", "(en)",
            "-AppleLocale", ScreenshotPlan.locale,
            "-UIViewAnimationDuration", "0",
            "-CALayerAnimationDuration", "0",
        ]

        app.launch()
        XCTAssertTrue(
            app.scrollViews["timelyQuote.home"].waitForExistence(timeout: 10),
            "The quote view did not finish loading"
        )
    }

    @MainActor
    func capture(_ app: XCUIApplication, named name: String, in testCase: XCTestCase) {
        Thread.sleep(forTimeInterval: 0.5)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(ScreenshotPlan.locale)__\(name)"
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }
}

extension XCUIElement {
    @MainActor
    func tapUnhittable() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
