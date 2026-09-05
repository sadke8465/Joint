import XCTest
@testable import CouplesTodo

final class AppShellTests: XCTestCase {
    func testWeekIsTheDefaultMode() {
        XCTAssertEqual(MainMode.defaultMode, .week)
    }

    func testAllMainModesHaveStableIdentifiers() {
        XCTAssertEqual(MainMode.allCases.map(\.id), ["week", "list", "calendar"])
    }

    func testTogetherAssignmentNeverKeepsAPersonIdentifier() {
        let draft = TaskDraft(
            title: "Plan dinner",
            notes: nil,
            assigneeKind: .together,
            assigneeUserID: PrototypeIdentity.shared.currentUserID,
            dueDate: nil,
            dueTime: nil,
            listID: nil
        )

        XCTAssertNil(draft.normalized.assigneeUserID)
        XCTAssertTrue(draft.isValid)
    }

    func testPersonAssignmentRequiresAMemberIdentifier() {
        let draft = TaskDraft(
            title: "Plan dinner",
            notes: nil,
            assigneeKind: .person,
            assigneeUserID: nil,
            dueDate: nil,
            dueTime: nil,
            listID: nil
        )

        XCTAssertFalse(draft.isValid)
    }

    func testEmojiListsRequireOneEmojiGrapheme() {
        XCTAssertTrue(EmojiList.isValidEmoji("👩‍❤️‍👨"))
        XCTAssertFalse(EmojiList.isValidEmoji("🛒🏠"))
        XCTAssertFalse(EmojiList.isValidEmoji("a"))
    }

    func testDateOnlyTaskBecomesOverdueAfterItsCalendarDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let dueDate = Date(timeIntervalSince1970: 86_400)
        let now = Date(timeIntervalSince1970: 172_800)

        XCTAssertTrue(makeTask(title: "Past task", dueDate: dueDate).isOverdue(
            relativeTo: now,
            calendar: calendar
        ))
        XCTAssertFalse(makeTask(title: "Today's task", dueDate: now).isOverdue(
            relativeTo: now,
            calendar: calendar
        ))
    }

    func testEnglishWeekSummaryJoinsTaskTitlesDeterministically() {
        let formatter = TaskSentenceFormatter(locale: Locale(identifier: "en_US"))
        let tasks = [
            makeTask(title: "buy wine"),
            makeTask(title: "call the venue")
        ]

        XCTAssertEqual(
            formatter.sentence(for: tasks, assignee: .together),
            "Together: buy wine and call the venue."
        )
    }

    private func makeTask(title: String, dueDate: Date? = nil) -> TaskItem {
        TaskItem(
            id: UUID(),
            coupleID: PrototypeIdentity.shared.coupleID,
            title: title,
            notes: nil,
            assigneeKind: .together,
            assigneeUserID: nil,
            dueDate: dueDate,
            dueTime: nil,
            listID: nil,
            status: .active,
            createdBy: PrototypeIdentity.shared.currentUserID,
            createdAt: .now,
            updatedAt: .now,
            completedBy: nil,
            completedAt: nil,
            deletedAt: nil
        )
    }
}
