struct MockTask: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let fallbackTitle: String
    let assignee: MemberStyle
    let timeKey: String?
    let emoji: String?
}

struct MockDay: Identifiable {
    let id: String
    let titleKey: String
    let dateKey: String
    let tasks: [MockTask]
}

enum MockContent {
    static let package = MockTask(
        id: "package",
        titleKey: "fixture.task.package",
        fallbackTitle: "Pick up the package",
        assignee: .me,
        timeKey: "fixture.time.evening",
        emoji: nil
    )

    static let venue = MockTask(
        id: "venue",
        titleKey: "fixture.task.venue",
        fallbackTitle: "Call the venue",
        assignee: .partner,
        timeKey: nil,
        emoji: "🥂"
    )

    static let wine = MockTask(
        id: "wine",
        titleKey: "fixture.task.wine",
        fallbackTitle: "Buy wine",
        assignee: .together,
        timeKey: nil,
        emoji: "🛒"
    )

    static let flowers = MockTask(
        id: "flowers",
        titleKey: "fixture.task.flowers",
        fallbackTitle: "Choose the flowers",
        assignee: .together,
        timeKey: "fixture.time.afternoon",
        emoji: "🌿"
    )

    static let getaway = MockTask(
        id: "getaway",
        titleKey: "fixture.task.getaway",
        fallbackTitle: "Book a weekend away",
        assignee: .me,
        timeKey: nil,
        emoji: "✨"
    )

    static let rsvp = MockTask(
        id: "rsvp",
        titleKey: "fixture.task.rsvp",
        fallbackTitle: "Send the RSVP",
        assignee: .partner,
        timeKey: nil,
        emoji: nil
    )

    static let activeTasks = [package, venue, wine, flowers, getaway]
    static let completedTasks = [rsvp]

    static let weekDays = [
        MockDay(
            id: "today",
            titleKey: "date.today",
            dateKey: "fixture.date.september_6",
            tasks: [package, venue, wine]
        ),
        MockDay(
            id: "tomorrow",
            titleKey: "date.tomorrow",
            dateKey: "fixture.date.september_7",
            tasks: [flowers]
        )
    ]
}
