import Observation

@MainActor
@Observable
final class AppRouter {
    var presentedSheet: SheetDestination?
}

enum SheetDestination: String, Identifiable {
    case taskComposer
    case settings

    var id: String { rawValue }
}
