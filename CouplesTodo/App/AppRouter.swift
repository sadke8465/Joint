import Foundation
import Observation

@MainActor
@Observable
final class AppRouter {
    var selectedMode = MainMode.defaultMode
    var presentedSheet: SheetDestination?
}

enum MoreRoute: CaseIterable, Hashable {
    case archive
    case emojiLists
    case trash
}

enum SheetDestination: Identifiable, Hashable {
    case quickAdd(TaskCreationDefaults)
    case taskEditor(taskID: UUID)
    case dayDetails(Date)
    case more

    var id: String {
        switch self {
        case .quickAdd: "quick-add"
        case .taskEditor(let taskID): "task-editor-\(taskID.uuidString)"
        case .dayDetails(let date): "day-details-\(date.timeIntervalSinceReferenceDate)"
        case .more: "more"
        }
    }
}
