import SwiftUI

// MARK: - Owner

enum TaskOwner: String, Sendable {
    case noam
    case omer
    case joint
}

extension TaskItemContent {
    /// Derived from the indicator dots rather than the display name, so it survives
    /// localisation and renaming.
    var owner: TaskOwner {
        let hasNoam = assigneeIndicators.contains(.cyan)
        let hasOmer = assigneeIndicators.contains(.pink)
        if hasNoam && hasOmer { return .joint }
        return hasNoam ? .noam : .omer
    }
}

// MARK: - Filter

enum TaskFilter: String, CaseIterable, Identifiable, Codable, Sendable {
    case all
    case noam
    case omer
    case joint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .noam: "Noam"
        case .omer: "Omer"
        case .joint: "Joint"
        }
    }

    /// Inclusive: filtering to a person keeps the work shared with them. Filtering to
    /// yourself should never hide what you are doing together.
    func matches(_ item: TaskItemContent) -> Bool {
        switch self {
        case .all: true
        case .noam: item.owner == .noam || item.owner == .joint
        case .omer: item.owner == .omer || item.owner == .joint
        case .joint: item.owner == .joint
        }
    }

    func visibleIds(in items: [TaskItemContent]) -> Set<String> {
        Set(items.filter(matches).map(\.id))
    }
}

// MARK: - Samples

/// Ten rows, because filter motion needs length to read — and one of the four styles is
/// specifically about propagating down a list. Joint 3, Noam 4, Omer 3, so the pills land on
/// 10 / 7 / 6 / 3.
enum FilterSamples {
    static let list: [TaskItemContent] = [
        item("dishes", "Do the dishes", "Today", .joint),
        item("groceries", "Order groceries", "Today", .noam),
        item("vet", "Book the vet", "Tomorrow", .omer),
        item("rent", "Pay the rent", "In 3 Days", .joint),
        item("flights", "Book flights home", "12.03.2026", .noam),
        item("laundry", "Fold the laundry", "Tomorrow", .omer),
        item("plants", "Water the plants", "Today", .noam),
        item("bins", "Take out the bins", "Tonight", .omer),
        item("insurance", "Renew the insurance", "Next week", .joint),
        item("dentist", "Call the dentist", "In 5 Days", .noam)
    ]

    private static func item(
        _ id: String,
        _ title: String,
        _ due: String,
        _ owner: TaskOwner
    ) -> TaskItemContent {
        let indicators: [TaskAssigneeIndicator]
        let name: String
        switch owner {
        case .noam: indicators = [.cyan]; name = "Noam"
        case .omer: indicators = [.pink]; name = "Omer"
        case .joint: indicators = [.pink, .cyan]; name = "Joint"
        }
        return TaskItemContent(
            id: id,
            title: title,
            dueText: due,
            assignee: name,
            assigneeIndicators: indicators,
            isCompleted: false
        )
    }
}
