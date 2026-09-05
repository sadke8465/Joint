import Foundation
import SwiftData

@Model
final class StoredTask {
    @Attribute(.unique) var id: UUID
    var coupleID: UUID
    var title: String
    var notes: String?
    var assigneeKindRawValue: String
    var assigneeUserID: UUID?
    var dueDate: Date?
    var dueHour: Int?
    var dueMinute: Int?
    var listID: UUID?
    var statusRawValue: String
    var createdBy: UUID
    var createdAt: Date
    var updatedAt: Date
    var completedBy: UUID?
    var completedAt: Date?
    var deletedAt: Date?

    init(
        id: UUID,
        coupleID: UUID,
        title: String,
        notes: String?,
        assigneeKind: AssigneeKind,
        assigneeUserID: UUID?,
        dueDate: Date?,
        dueTime: DateComponents?,
        listID: UUID?,
        status: TaskStatus,
        createdBy: UUID,
        createdAt: Date,
        updatedAt: Date,
        completedBy: UUID?,
        completedAt: Date?,
        deletedAt: Date?
    ) {
        self.id = id
        self.coupleID = coupleID
        self.title = title
        self.notes = notes
        assigneeKindRawValue = assigneeKind.rawValue
        self.assigneeUserID = assigneeUserID
        self.dueDate = dueDate
        dueHour = dueTime?.hour
        dueMinute = dueTime?.minute
        self.listID = listID
        statusRawValue = status.rawValue
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedBy = completedBy
        self.completedAt = completedAt
        self.deletedAt = deletedAt
    }

    convenience init(task: TaskItem) {
        self.init(
            id: task.id,
            coupleID: task.coupleID,
            title: task.title,
            notes: task.notes,
            assigneeKind: task.assigneeKind,
            assigneeUserID: task.assigneeUserID,
            dueDate: task.dueDate,
            dueTime: task.dueTime,
            listID: task.listID,
            status: task.status,
            createdBy: task.createdBy,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
            completedBy: task.completedBy,
            completedAt: task.completedAt,
            deletedAt: task.deletedAt
        )
    }

    var domainValue: TaskItem {
        TaskItem(
            id: id,
            coupleID: coupleID,
            title: title,
            notes: notes,
            assigneeKind: AssigneeKind(rawValue: assigneeKindRawValue) ?? .together,
            assigneeUserID: assigneeUserID,
            dueDate: dueDate,
            dueTime: dueTime,
            listID: listID,
            status: TaskStatus(rawValue: statusRawValue) ?? .active,
            createdBy: createdBy,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedBy: completedBy,
            completedAt: completedAt,
            deletedAt: deletedAt
        )
    }

    func apply(_ draft: TaskDraft, updatedAt: Date) {
        let draft = draft.normalized
        title = draft.title
        notes = draft.notes
        assigneeKindRawValue = draft.assigneeKind.rawValue
        assigneeUserID = draft.assigneeUserID
        dueDate = draft.dueDate
        dueHour = draft.dueTime?.hour
        dueMinute = draft.dueTime?.minute
        listID = draft.listID
        self.updatedAt = updatedAt
    }

    private var dueTime: DateComponents? {
        guard dueHour != nil || dueMinute != nil else { return nil }
        return DateComponents(hour: dueHour, minute: dueMinute)
    }
}
