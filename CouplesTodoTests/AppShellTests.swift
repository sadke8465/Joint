import XCTest
@testable import CouplesTodo

final class AppShellTests: XCTestCase {
    func testListIsTheDefaultMode() {
        XCTAssertEqual(MainMode.defaultMode, .list)
    }

    func testMainModesHaveStableWebOrder() {
        XCTAssertEqual(MainMode.allCases.map(\.id), ["list", "week", "calendar"])
    }

    func testMoreRoutesHaveStableIdentity() {
        XCTAssertEqual(Set(MoreRoute.allCases), Set([.archive, .emojiLists, .trash]))
    }

    func testTaskFiltersHaveStableIdentityAndMatchExpectedTasks() {
        let identity = PrototypeIdentity.shared
        let listID = UUID()
        let mine = makeTask(title: "Mine", assigneeUserID: identity.currentUserID)
        let partner = makeTask(title: "Partner", assigneeUserID: identity.partnerUserID)
        let together = makeTask(title: "Together")
        let listed = makeTask(title: "Listed", listID: listID)

        XCTAssertEqual(TaskFilter.all.id, "all")
        XCTAssertEqual(TaskFilter.assignee(.me).id, "assignee-me")
        XCTAssertEqual(TaskFilter.emojiList(listID).id, "emoji-list-\(listID.uuidString)")
        XCTAssertTrue(TaskFilter.assignee(.me).matches(mine, identity: identity))
        XCTAssertTrue(TaskFilter.assignee(.partner).matches(partner, identity: identity))
        XCTAssertTrue(TaskFilter.assignee(.together).matches(together, identity: identity))
        XCTAssertTrue(TaskFilter.emojiList(listID).matches(listed, identity: identity))
        XCTAssertFalse(TaskFilter.assignee(.me).matches(partner, identity: identity))
    }

    func testQuickAddDefaultsForEveryFilterKind() {
        let listID = UUID()

        XCTAssertEqual(TaskFilter.all.creationDefaults, TaskCreationDefaults(assignee: .together))
        XCTAssertEqual(
            TaskFilter.assignee(.me).creationDefaults,
            TaskCreationDefaults(assignee: .me)
        )
        XCTAssertEqual(
            TaskFilter.assignee(.partner).creationDefaults,
            TaskCreationDefaults(assignee: .partner)
        )
        XCTAssertEqual(
            TaskFilter.assignee(.together).creationDefaults,
            TaskCreationDefaults(assignee: .together)
        )
        XCTAssertEqual(
            TaskFilter.emojiList(listID).creationDefaults,
            TaskCreationDefaults(assignee: .together, listID: listID)
        )
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

    func testInlineDraftNormalizesNotesAndRemovesTimeWhenDateIsCleared() {
        let draft = TaskDraft(
            title: "  Book dinner  ",
            notes: "   ",
            assigneeKind: .together,
            assigneeUserID: PrototypeIdentity.shared.currentUserID,
            dueDate: nil,
            dueTime: DateComponents(hour: 18, minute: 45),
            listID: nil
        ).normalized

        XCTAssertEqual(draft.title, "Book dinner")
        XCTAssertNil(draft.notes)
        XCTAssertNil(draft.assigneeUserID)
        XCTAssertNil(draft.dueTime)
    }

    func testDueDateTimeCombinesDateAndTimeWithProvidedCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let day = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: 6)))
        let task = makeTask(
            title: "Dinner",
            dueDate: day,
            dueTime: DateComponents(hour: 19, minute: 30)
        )

        let combined = try XCTUnwrap(task.dueDateTime(calendar: calendar))
        XCTAssertEqual(calendar.component(.hour, from: combined), 19)
        XCTAssertEqual(calendar.component(.minute, from: combined), 30)
    }

    func testWeekBoundaryRespectsLocaleCalendarRules() throws {
        var sundayCalendar = Calendar(identifier: .gregorian)
        sundayCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        sundayCalendar.firstWeekday = 1
        let date = try XCTUnwrap(
            sundayCalendar.date(from: DateComponents(year: 2026, month: 9, day: 9))
        )

        let sundayStart = WeekCalendar.startOfWeek(
            containing: date,
            locale: Locale(identifier: "en_US"),
            calendar: sundayCalendar
        )

        var mondayCalendar = sundayCalendar
        mondayCalendar.firstWeekday = 2
        let mondayStart = WeekCalendar.startOfWeek(
            containing: date,
            locale: Locale(identifier: "en_GB"),
            calendar: mondayCalendar
        )

        XCTAssertEqual(sundayCalendar.component(.weekday, from: sundayStart), 1)
        XCTAssertEqual(mondayCalendar.component(.weekday, from: mondayStart), 2)
    }

    func testMemberLabelsHaveLocalizedFallbacks() {
        let english = Locale(identifier: "en_US")
        let hebrew = Locale(identifier: "he_IL")

        XCTAssertEqual(String(localized: "assignee.me", locale: english), "Me")
        XCTAssertEqual(String(localized: "assignee.partner", locale: english), "Partner")
        XCTAssertFalse(String(localized: "assignee.me", locale: hebrew).isEmpty)
        XCTAssertFalse(String(localized: "assignee.partner", locale: hebrew).isEmpty)
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

    private func makeTask(
        title: String,
        assigneeUserID: UUID? = nil,
        dueDate: Date? = nil,
        dueTime: DateComponents? = nil,
        listID: UUID? = nil
    ) -> TaskItem {
        TaskItem(
            id: UUID(),
            coupleID: PrototypeIdentity.shared.coupleID,
            title: title,
            notes: nil,
            assigneeKind: assigneeUserID == nil ? .together : .person,
            assigneeUserID: assigneeUserID,
            dueDate: dueDate,
            dueTime: dueTime,
            listID: listID,
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
