import Foundation
import SwiftData

enum TaskRepositoryError: LocalizedError {
    case invalidDraft
    case taskNotFound

    var errorDescription: String? {
        switch self {
        case .invalidDraft:
            "The task is missing required information."
        case .taskNotFound:
            "The task could not be found."
        }
    }
}

@MainActor
protocol TaskRepository {
    func fetchAll(coupleID: UUID) throws -> [TaskItem]
    func create(from draft: TaskDraft, identity: LocalIdentity, now: Date) throws -> TaskItem
    func update(id: UUID, with draft: TaskDraft, now: Date) throws
    func setCompletion(id: UUID, isCompleted: Bool, userID: UUID, now: Date) throws
    func moveToTrash(id: UUID, now: Date) throws
    func restoreFromTrash(id: UUID, now: Date) throws
    func deletePermanently(id: UUID) throws
}

@MainActor
final class SwiftDataTaskRepository: TaskRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
        context.autosaveEnabled = false
    }

    func fetchAll(coupleID: UUID) throws -> [TaskItem] {
        let descriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate { $0.coupleID == coupleID }
        )

        return try context.fetch(descriptor)
            .map(\.domainValue)
            .sorted(by: taskSort)
    }

    func create(from draft: TaskDraft, identity: LocalIdentity, now: Date = .now) throws -> TaskItem {
        guard draft.isValid else { throw TaskRepositoryError.invalidDraft }
        let draft = draft.normalized
        let task = TaskItem(
            id: UUID(),
            coupleID: identity.coupleID,
            title: draft.title,
            notes: draft.notes,
            assigneeKind: draft.assigneeKind,
            assigneeUserID: draft.assigneeUserID,
            dueDate: draft.dueDate,
            dueTime: draft.dueTime,
            listID: draft.listID,
            status: .active,
            createdBy: identity.currentUserID,
            createdAt: now,
            updatedAt: now,
            completedBy: nil,
            completedAt: nil,
            deletedAt: nil
        )

        context.insert(StoredTask(task: task))
        try saveChanges()
        return task
    }

    func update(id: UUID, with draft: TaskDraft, now: Date = .now) throws {
        guard draft.isValid else { throw TaskRepositoryError.invalidDraft }
        let task = try storedTask(id: id)
        task.apply(draft, updatedAt: now)
        try saveChanges()
    }

    func setCompletion(id: UUID, isCompleted: Bool, userID: UUID, now: Date = .now) throws {
        let task = try storedTask(id: id)
        task.statusRawValue = isCompleted ? TaskStatus.completed.rawValue : TaskStatus.active.rawValue
        task.completedBy = isCompleted ? userID : nil
        task.completedAt = isCompleted ? now : nil
        task.updatedAt = now
        try saveChanges()
    }

    func moveToTrash(id: UUID, now: Date = .now) throws {
        let task = try storedTask(id: id)
        task.deletedAt = now
        task.updatedAt = now
        try saveChanges()
    }

    func restoreFromTrash(id: UUID, now: Date = .now) throws {
        let task = try storedTask(id: id)
        task.deletedAt = nil
        task.updatedAt = now
        try saveChanges()
    }

    func deletePermanently(id: UUID) throws {
        context.delete(try storedTask(id: id))
        try saveChanges()
    }

    private func storedTask(id: UUID) throws -> StoredTask {
        var descriptor = FetchDescriptor<StoredTask>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        guard let task = try context.fetch(descriptor).first else {
            throw TaskRepositoryError.taskNotFound
        }
        return task
    }

    private func saveChanges() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    private func taskSort(lhs: TaskItem, rhs: TaskItem) -> Bool {
        switch (lhs.dueDateTime(), rhs.dueDateTime()) {
        case let (left?, right?):
            if left != right { return left < right }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }

        return lhs.createdAt < rhs.createdAt
    }
}
