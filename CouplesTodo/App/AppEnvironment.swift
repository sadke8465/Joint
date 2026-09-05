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

    static func preview() -> AppEnvironment {
        do {
            return try AppEnvironment(isStoredInMemoryOnly: true)
        } catch {
            fatalError("Unable to open the preview task store: \(error.localizedDescription)")
        }
    }
}
