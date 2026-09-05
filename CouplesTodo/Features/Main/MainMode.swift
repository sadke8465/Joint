import SwiftUI

enum MainMode: String, CaseIterable, Identifiable {
    case week
    case list
    case calendar

    static let defaultMode: MainMode = .week

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .week: "main.mode.week"
        case .list: "main.mode.list"
        case .calendar: "main.mode.calendar"
        }
    }

    var iconName: String {
        switch self {
        case .week: "rectangle.3.group"
        case .list: "checklist"
        case .calendar: "calendar"
        }
    }
}
