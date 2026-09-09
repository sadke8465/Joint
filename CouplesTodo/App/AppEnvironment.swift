import Foundation
import SwiftData

@MainActor
final class AppEnvironment {
    let modelContainer: ModelContainer
    let taskStore: TaskStore

    init(isStoredInMemoryOnly: Bool = false) throws {
        let container = try LocalStoreFactory.makeContainer(
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
        let context = container.mainContext

        modelContainer = container
        taskStore = TaskStore(
            identity: PrototypeIdentity.shared,
            taskRepository: SwiftDataTaskRepository(context: context),
            emojiListRepository: SwiftDataEmojiListRepository(context: context)
        )
    }

    static func live() -> AppEnvironment {
        do {
            return try AppEnvironment()
        } catch {
            fatalError("Unable to open the local task store: \(error.localizedDescription)")
        }
    }

    static func app(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        guard arguments.contains("--ui-testing") else { return live() }

        do {
            let environment = try AppEnvironment(isStoredInMemoryOnly: true)
            if !arguments.contains("--ui-empty") {
                try PreviewFixtures.populate(environment)
            }
            return environment
        } catch {
            fatalError("Unable to open the UI-test task store: \(error.localizedDescription)")
        }
    }

    static func preview(populated: Bool = false) -> AppEnvironment {
        do {
            let environment = try AppEnvironment(isStoredInMemoryOnly: true)
            if populated {
                try PreviewFixtures.populate(environment)
            }
            return environment
        } catch {
            fatalError("Unable to open the preview task store: \(error.localizedDescription)")
        }
    }
}

@MainActor
enum PreviewFixtures {
    static func populate(_ environment: AppEnvironment) throws {
        let identity = PrototypeIdentity.shared
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let later = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let shoppingListID = UUID(uuidString: "A0000000-0000-0000-0000-000000000001")!

        environment.modelContainer.mainContext.insert(
            StoredEmojiList(
                id: shoppingListID,
                coupleID: identity.coupleID,
                emoji: "🛒",
                title: "Shopping",
                createdAt: yesterday
            )
        )

        let tasks = [
            task(
                id: "B0000000-0000-0000-0000-000000000001",
                title: "Buy groceries",
                dueDate: today,
                listID: shoppingListID,
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000002",
                title: "Call the plumber",
                assigneeUserID: identity.currentUserID,
                dueDate: today,
                dueTime: DateComponents(hour: 14, minute: 30),
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000003",
                title: "Pick up the package",
                assigneeUserID: identity.partnerUserID,
                dueDate: tomorrow,
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000004",
                title: "Plan the weekend",
                dueDate: later,
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000005",
                title: "Sort the photos",
                dueDate: nil,
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000006",
                title: "Send the RSVP",
                dueDate: yesterday,
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000007",
                title: "Book the restaurant",
                dueDate: today,
                status: .completed,
                completedAt: now.addingTimeInterval(-7_200),
                identity: identity,
                now: now
            ),
            task(
                id: "B0000000-0000-0000-0000-000000000008",
                title: "Old packing note",
                dueDate: nil,
                deletedAt: now.addingTimeInterval(-86_400),
                identity: identity,
                now: now
            )
        ]

        tasks.forEach { environment.modelContainer.mainContext.insert(StoredTask(task: $0)) }
        try environment.modelContainer.mainContext.save()
        environment.taskStore.loadIfNeeded()
    }

    private static func task(
        id: String,
        title: String,
        assigneeUserID: UUID? = nil,
        dueDate: Date?,
        dueTime: DateComponents? = nil,
        listID: UUID? = nil,
        status: TaskStatus = .active,
        completedAt: Date? = nil,
        deletedAt: Date? = nil,
        identity: LocalIdentity,
        now: Date
    ) -> TaskItem {
        TaskItem(
            id: UUID(uuidString: id)!,
            coupleID: identity.coupleID,
            title: title,
            notes: nil,
            assigneeKind: assigneeUserID == nil ? .together : .person,
            assigneeUserID: assigneeUserID,
            dueDate: dueDate,
            dueTime: dueTime,
            listID: listID,
            status: status,
            createdBy: identity.currentUserID,
            createdAt: now.addingTimeInterval(-172_800),
            updatedAt: completedAt ?? deletedAt ?? now,
            completedBy: completedAt == nil ? nil : identity.currentUserID,
            completedAt: completedAt,
            deletedAt: deletedAt
        )
    }
}
