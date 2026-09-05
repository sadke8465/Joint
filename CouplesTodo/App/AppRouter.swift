import Observation
import Foundation

@MainActor
@Observable
final class AppRouter {
    var presentedSheet: SheetDestination?
}

enum SheetDestination: Identifiable, Hashable {
    case taskComposer(taskID: UUID?)
    case settings

    var id: String {
        switch self {
        case .taskComposer(let taskID):
            "task-composer-\(taskID?.uuidString ?? "new")"
        case .settings:
            "settings"
        }
    }
}
