import XCTest

final class CouplesTodoLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsAppName() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["launch-title"].waitForExistence(timeout: 3),
            "The bootstrap screen should identify the app after launch."
        )
    }
}
