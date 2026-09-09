import XCTest

@MainActor
final class CouplesTodoLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testListLaunchesFirstAndModesUseTheFixedHeader() {
        let app = launchApp()

        XCTAssertTrue(app.descendants(matching: .any)["list-screen"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["mode-list"].isSelected)
        XCTAssertFalse(app.tabBars.element.isHittable)
        XCTAssertTrue(app.buttons["add-task"].exists)

        app.buttons["mode-week"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["week-screen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["add-task"].exists)

        app.buttons["mode-calendar"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["calendar-screen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["add-task"].exists)
    }

    func testHeaderAndListToolbarRemainFixedWhileListScrolls() {
        let app = launchApp()
        let modeSwitcher = app.buttons["mode-list"]
        let toolbarControl = app.buttons["filter-all"]
        XCTAssertTrue(toolbarControl.waitForExistence(timeout: 3))
        let modeSwitcherY = modeSwitcher.frame.minY
        let toolbarY = toolbarControl.frame.minY

        app.descendants(matching: .any)["list-screen"].swipeUp()

        XCTAssertEqual(modeSwitcher.frame.minY, modeSwitcherY, accuracy: 2)
        XCTAssertEqual(toolbarControl.frame.minY, toolbarY, accuracy: 2)
    }

    func testQuickAddAndRapidEntryUseDeterministicFixtureStore() {
        let app = launchApp()
        app.buttons["add-task"].tap()

        let title = app.textFields["task-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 2))
        title.typeText("Pick up dry cleaning\n")
        XCTAssertTrue(title.exists)
        XCTAssertFalse((title.value as? String ?? "").contains("Pick up dry cleaning"))

        title.typeText("Book train")
        app.buttons["composer-add"].tap()
        let updatedCount = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "8 open tasks")
        ).firstMatch
        XCTAssertTrue(updatedCount.waitForExistence(timeout: 2))
    }

    func testListFilterAndModeLocalStateSurviveSwitching() {
        let app = launchApp()
        app.buttons["filter-assignee-me"].tap()
        XCTAssertTrue(app.buttons["filter-assignee-me"].isSelected)

        app.buttons["mode-calendar"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["calendar-screen"].waitForExistence(timeout: 2))
        app.buttons["mode-list"].tap()

        XCTAssertTrue(app.descendants(matching: .any)["list-screen"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["filter-assignee-me"].isSelected)
    }

    func testMoreReachesArchiveEmojiListsAndTrash() {
        let app = launchApp()
        app.buttons["profile-settings"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["settings-shell"].waitForExistence(timeout: 2))

        app.buttons["tasks-archive"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["archive-screen"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["tasks-lists"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["emoji-lists-screen"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["settings-trash"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["trash-screen"].waitForExistence(timeout: 2))
    }

    func testDarkSystemAppearanceStillUsesTheLightAppTheme() {
        let app = launchApp(extraArguments: ["-AppleInterfaceStyle", "Dark"])

        XCTAssertTrue(app.descendants(matching: .any)["list-screen"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["add-task"].isHittable)
        capture(app, name: "List-Dark-System-Light-App")
    }

    func testHebrewLaunchUsesRTLModeOrder() {
        let app = launchApp(extraArguments: ["-AppleLanguages", "(he)", "-AppleLocale", "he_IL"])
        let list = app.buttons["mode-list"]
        let calendar = app.buttons["mode-calendar"]

        XCTAssertTrue(list.waitForExistence(timeout: 3))
        XCTAssertEqual(list.label, "רשימה")
        XCTAssertGreaterThan(list.frame.midX, calendar.frame.midX)
        capture(app, name: "List-Hebrew-RTL")
    }

    func testAccessibilityTextAndReduceMotionKeepNavigationUsable() {
        let app = launchApp(extraArguments: [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            "-UIAccessibilityReduceMotion",
            "YES"
        ])

        XCTAssertTrue(app.buttons["mode-list"].isHittable)
        XCTAssertTrue(app.buttons["mode-week"].isHittable)
        XCTAssertTrue(app.buttons["mode-calendar"].isHittable)
        XCTAssertTrue(app.buttons["add-task"].isHittable)
    }

    private func launchApp(extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + extraArguments
        app.launch()
        return app
    }

    private func capture(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
