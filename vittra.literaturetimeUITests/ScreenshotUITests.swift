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

        // Open the quote-actions menu and capture it while it exposes the
        // "view book on gutenberg" action (04_ReadTheBook), before drilling in.
        let quoteActions = app.buttons["timelyQuote.quoteActions"]
        XCTAssertTrue(quoteActions.waitForExistence(timeout: 5))
        quoteActions.tap()

        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        helper.capture(app, named: ScreenshotPlan.screens[3].name, in: self)

        settings.tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["timelyQuote.settings"].waitForExistence(timeout: 5)
        )
        helper.capture(app, named: ScreenshotPlan.screens[1].name, in: self)

        // Drill into About for the open-source / privacy close (05_OpenSource).
        let about = app.buttons["About"]
        XCTAssertTrue(about.waitForExistence(timeout: 5))
        about.tap()
        XCTAssertTrue(app.buttons["Privacy Policy"].waitForExistence(timeout: 5))
        helper.capture(app, named: ScreenshotPlan.screens[4].name, in: self)

        app.terminate()
        helper.launch(app, appearance: "Dark")
        helper.capture(app, named: ScreenshotPlan.screens[2].name, in: self)
    }
}
