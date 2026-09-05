import Foundation

struct TaskDraft: Equatable, Sendable {
    var title: String
    var notes: String?
    var assigneeKind: AssigneeKind
    var assigneeUserID: UUID?
    var dueDate: Date?
    var dueTime: DateComponents?
    var listID: UUID?

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
