import Foundation

struct TaskDraft: Equatable, Sendable {
    var title: String
    var notes: String?
    var assigneeKind: AssigneeKind
    var assigneeUserID: UUID?
    var dueDate: Date?
    var dueTime: DateComponents?
    var listID: UUID?

    init(
        title: String,
        notes: String?,
        assigneeKind: AssigneeKind,
        assigneeUserID: UUID?,
        dueDate: Date?,
        dueTime: DateComponents?,
        listID: UUID?
    ) {
        self.title = title
        self.notes = notes
        self.assigneeKind = assigneeKind
        self.assigneeUserID = assigneeUserID
        self.dueDate = dueDate
        self.dueTime = dueTime
        self.listID = listID
    }

    init(task: TaskItem) {
        self.init(
            title: task.title,
            notes: task.notes,
            assigneeKind: task.assigneeKind,
            assigneeUserID: task.assigneeUserID,
            dueDate: task.dueDate,
            dueTime: task.dueTime,
            listID: task.listID
        )
    }

    var normalized: TaskDraft {
        TaskDraft(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            assigneeKind: assigneeKind,
            assigneeUserID: assigneeKind == .together ? nil : assigneeUserID,
            dueDate: dueDate,
            dueTime: dueDate == nil ? nil : dueTime,
            listID: listID
        )
    }

    var isValid: Bool {
        let candidate = normalized
        guard !candidate.title.isEmpty else { return false }

        switch candidate.assigneeKind {
        case .person:
            return candidate.assigneeUserID != nil
        case .together:
            return candidate.assigneeUserID == nil
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
