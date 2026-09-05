import SwiftUI

@main
struct CouplesTodoApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .tint(AppColors.accent)
                .preferredColorScheme(.light)
        }
    }
}
