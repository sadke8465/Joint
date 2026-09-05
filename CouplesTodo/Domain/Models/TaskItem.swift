import Foundation

struct TaskItem: Identifiable, Equatable, Hashable, Sendable {
    let id: UUID
    let coupleID: UUID
    var title: String
    var notes: String?
    var assigneeKind: AssigneeKind
    var assigneeUserID: UUID?
    var dueDate: Date?
    var dueTime: DateComponents?
    var listID: UUID?
    var status: TaskStatus
    let createdBy: UUID
    let createdAt: Date
    var updatedAt: Date
    var completedBy: UUID?
    var completedAt: Date?
    var deletedAt: Date?

    var isCompleted: Bool {
        status == .completed
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    func matches(_ query: String) -> Bool {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else { return true }

        return title.localizedCaseInsensitiveContains(normalizedQuery)
            || notes?.localizedCaseInsensitiveContains(normalizedQuery) == true
    }

    func dueDateTime(calendar: Calendar = .current) -> Date? {
        guard let dueDate else { return nil }
        guard let dueTime else { return dueDate }

        return calendar.date(
            bySettingHour: dueTime.hour ?? 0,
            minute: dueTime.minute ?? 0,
            second: 0,
            of: dueDate
        )
    }
}

enum AssigneeKind: String, Codable, CaseIterable, Sendable {
    case person
    case together
}

enum TaskStatus: String, Codable, CaseIterable, Sendable {
    case active
    case completed
}
