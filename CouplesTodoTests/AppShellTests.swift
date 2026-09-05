import XCTest
@testable import CouplesTodo

final class AppShellTests: XCTestCase {
    func testWeekIsTheDefaultMode() {
        XCTAssertEqual(MainMode.defaultMode, .week)
    }

    func testAllMainModesHaveStableIdentifiers() {
        XCTAssertEqual(MainMode.allCases.map(\.id), ["week", "list", "calendar"])
    }

    func testMockTasksHaveUniqueIdentifiers() {
        let tasks = MockContent.activeTasks + MockContent.completedTasks
        XCTAssertEqual(Set(tasks.map(\.id)).count, tasks.count)
    }

    func testMockContentCoversEveryAssignmentStyle() {
        XCTAssertEqual(Set(MockContent.activeTasks.map(\.assignee)), Set(MemberStyle.allCases))
    }
}
