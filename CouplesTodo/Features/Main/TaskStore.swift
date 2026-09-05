import Foundation
import Observation

@MainActor
@Observable
final class TaskStore {
    private(set) var tasks: [TaskItem] = []
    private(set) var emojiLists: [EmojiList] = []
    private(set) var recentlyDeletedTaskID: UUID?
    private(set) var hasLoaded = false
    var errorMessage: String?

    let identity: LocalIdentity

    @ObservationIgnored private let taskRepository: any TaskRepository
    @ObservationIgnored private let emojiListRepository: any EmojiListRepository
    @ObservationIgnored private var undoExpiryTask: Task<Void, Never>?

    init(
        identity: LocalIdentity,
        taskRepository: any TaskRepository,
        emojiListRepository: any EmojiListRepository
    ) {
        self.identity = identity
        self.taskRepository = taskRepository
        self.emojiListRepository = emojiListRepository
    }

    var activeTasks: [TaskItem] {
        tasks.filter { !$0.isDeleted && $0.status == .active }
    }

    var completedTasks: [TaskItem] {
        tasks
            .filter { !$0.isDeleted && $0.status == .completed }
            .sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }

    var trashedTasks: [TaskItem] {
        tasks
            .filter(\.isDeleted)
            .sorted { ($0.deletedAt ?? $0.updatedAt) > ($1.deletedAt ?? $1.updatedAt) }
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        reload()
    }

    func task(id: UUID?) -> TaskItem? {
        guard let id else { return nil }
        return tasks.first { $0.id == id }
    }

    func emojiList(id: UUID?) -> EmojiList? {
        guard let id else { return nil }
        return emojiLists.first { $0.id == id }
    }

    @discardableResult
    func create(_ draft: TaskDraft) -> Bool {
        performMutation {
            _ = try taskRepository.create(from: draft, identity: identity, now: .now)
        }
    }

    @discardableResult
    func update(id: UUID, with draft: TaskDraft) -> Bool {
        performMutation {
            try taskRepository.update(id: id, with: draft, now: .now)
        }
    }

    func toggleCompletion(for task: TaskItem) {
        _ = performMutation {
            try taskRepository.setCompletion(
                id: task.id,
                isCompleted: !task.isCompleted,
                userID: identity.currentUserID,
                now: .now
            )
        }
    }

    func moveToTrash(_ task: TaskItem) {
        guard performMutation({ try taskRepository.moveToTrash(id: task.id, now: .now) }) else {
            return
        }

        undoExpiryTask?.cancel()
        recentlyDeletedTaskID = task.id
        undoExpiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled else { return }
            self?.recentlyDeletedTaskID = nil
        }
    }

    func undoLastDelete() {
        guard let id = recentlyDeletedTaskID else { return }
        undoExpiryTask?.cancel()
        guard performMutation({ try taskRepository.restoreFromTrash(id: id, now: .now) }) else {
            return
        }
        recentlyDeletedTaskID = nil
    }

    func restoreFromTrash(_ task: TaskItem) {
        _ = performMutation {
            try taskRepository.restoreFromTrash(id: task.id, now: .now)
        }
        if recentlyDeletedTaskID == task.id {
            undoExpiryTask?.cancel()
            recentlyDeletedTaskID = nil
        }
    }

    func deletePermanently(_ task: TaskItem) {
        _ = performMutation {
            try taskRepository.deletePermanently(id: task.id)
        }
        if recentlyDeletedTaskID == task.id {
            undoExpiryTask?.cancel()
            recentlyDeletedTaskID = nil
        }
    }

    @discardableResult
    func createEmojiList(emoji: String, title: String) -> EmojiList? {
        do {
            let list = try emojiListRepository.create(
                emoji: emoji,
                title: title,
                coupleID: identity.coupleID,
                now: .now
            )
            reload()
            return list
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func removeEmojiList(_ list: EmojiList) {
        _ = performMutation {
            try emojiListRepository.remove(id: list.id)
        }
    }

    private func performMutation(_ mutation: () throws -> Void) -> Bool {
        do {
            try mutation()
            reload()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func reload() {
        do {
            tasks = try taskRepository.fetchAll(coupleID: identity.coupleID)
            emojiLists = try emojiListRepository.fetchAll(coupleID: identity.coupleID)
            errorMessage = nil
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
