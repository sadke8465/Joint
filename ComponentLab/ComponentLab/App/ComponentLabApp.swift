import SwiftUI

@main
struct ComponentLabApp: App {
    var body: some Scene {
        WindowGroup {
            if LaunchOptions.opensSuggestion {
                NavigationStack { ClaudeSuggestionLab() }
            } else if LaunchOptions.opensFilterLab {
                NavigationStack { FilterLab() }
            } else if LaunchOptions.opensFinalPlayground {
                NavigationStack { FinalPlayground() }
            } else if LaunchOptions.opensMoveDownLab {
                NavigationStack { MoveDownLab() }
            } else if LaunchOptions.opensMotionLab {
                NavigationStack { TaskCompletionLab() }
            } else {
                ComponentCatalogView()
            }
        }
    }
}
