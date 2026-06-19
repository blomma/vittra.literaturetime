import XCTest

final class ScreenshotUITests: XCTestCase {
    private let helper = ScreenshotTestHelper()

    @MainActor
    func testCaptureScreenshots() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        helper.launch(app)
        helper.capture(app, named: ScreenshotPlan.screens[0].name, in: self)

        let quoteActions = app.buttons["timelyQuote.quoteActions"]
        XCTAssertTrue(quoteActions.waitForExistence(timeout: 5))
        quoteActions.tap()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["timelyQuote.settings"].waitForExistence(timeout: 5)
        )
        helper.capture(app, named: ScreenshotPlan.screens[1].name, in: self)

        app.terminate()
        helper.launch(app, appearance: "Dark")
        helper.capture(app, named: ScreenshotPlan.screens[2].name, in: self)
    }
}
