import SwiftUI
import SwiftData

@main
@MainActor
struct CouplesTodoApp: App {
    private let environment = AppEnvironment.app()

    var body: some Scene {
        WindowGroup {
            MainView(store: environment.taskStore)
                .tint(AppColors.accent)
                .preferredColorScheme(.light)
        }
        .modelContainer(environment.modelContainer)
    }
}
