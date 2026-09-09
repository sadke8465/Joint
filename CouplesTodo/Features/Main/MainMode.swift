import Foundation
import SwiftUI

enum MainMode: String, CaseIterable, Identifiable, Hashable {
    case list
    case week
    case calendar

    static let defaultMode: MainMode = .list

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .list: "main.mode.list"
        case .week: "main.mode.week"
        case .calendar: "main.mode.calendar"
        }
    }

    var iconName: String {
        switch self {
        case .list: "checklist"
        case .week: "rectangle.3.group"
        case .calendar: "calendar"
        }
    }
}

enum TaskFilter: Hashable, Identifiable {
    case all
    case assignee(MemberStyle)
    case emojiList(UUID)

    var id: String {
        switch self {
        case .all: "all"
        case .assignee(let style): "assignee-\(style.rawValue)"
        case .emojiList(let id): "emoji-list-\(id.uuidString)"
        }
    }

    func matches(_ task: TaskItem, identity: LocalIdentity) -> Bool {
        switch self {
        case .all:
            true
        case .assignee(let style):
            MemberStyle(task: task, identity: identity) == style
        case .emojiList(let id):
            task.listID == id
        }
    }

    var creationDefaults: TaskCreationDefaults {
        switch self {
        case .all:
            TaskCreationDefaults(assignee: .together)
        case .assignee(let style):
            TaskCreationDefaults(assignee: style)
        case .emojiList(let id):
            TaskCreationDefaults(assignee: .together, listID: id)
        }
    }
}

enum DateFilter: String, CaseIterable, Identifiable, Hashable {
    case all
    case today
    case thisWeek
    case overdue

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "filter.any_date"
        case .today: "filter.today"
        case .thisWeek: "filter.this_week"
        case .overdue: "filter.overdue"
        }
    }

    var iconName: String {
        switch self {
        case .all: "calendar"
        case .today: "sun.max"
        case .thisWeek: "calendar.badge.clock"
        case .overdue: "exclamationmark.calendar"
        }
    }
}

struct TaskCreationDefaults: Hashable {
    let assignee: MemberStyle
    let listID: UUID?

    init(assignee: MemberStyle = .together, listID: UUID? = nil) {
        self.assignee = assignee
        self.listID = listID
    }
}
