import XCTest

@MainActor
final class CouplesTodoLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsWeekByDefaultAndSwitchesModes() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.descendants(matching: .any)["week-screen"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["mode-week"].isSelected)
        capture(app, name: "Week-English")

        app.buttons["mode-list"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["list-screen"].waitForExistence(timeout: 2))
        capture(app, name: "List-English")

        app.buttons["mode-calendar"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["calendar-screen"].waitForExistence(timeout: 2))
        capture(app, name: "Calendar-English")
    }

    func testTaskComposerAndSettingsAreReachable() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["add-task"].tap()
        XCTAssertTrue(app.textFields["task-title"].waitForExistence(timeout: 2))
        capture(app, name: "Composer-English")
        app.buttons["composer-done"].tap()

        app.buttons["profile-settings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["settings-shell"].waitForExistence(timeout: 2))
    }

    func testHebrewLaunchUsesRTLModeOrder() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(he)", "-AppleLocale", "he_IL"]
        app.launch()

        let week = app.buttons["mode-week"]
        let calendar = app.buttons["mode-calendar"]

        XCTAssertTrue(week.waitForExistence(timeout: 3))
        XCTAssertEqual(week.label, "שבוע")
        XCTAssertGreaterThan(week.frame.midX, calendar.frame.midX)
        capture(app, name: "Week-Hebrew-RTL")
    }

    func testAccessibilityTextAndReduceMotionKeepNavigationUsable() {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "-UIAccessibilityReduceMotion",
            "YES"
        ]
        app.launch()

        XCTAssertTrue(app.buttons["mode-week"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["mode-list"].isHittable)
        XCTAssertTrue(app.buttons["mode-calendar"].isHittable)
        XCTAssertTrue(app.buttons["add-task"].isHittable)
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
