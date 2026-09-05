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
}
