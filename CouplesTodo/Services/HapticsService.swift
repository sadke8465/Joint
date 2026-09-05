import SwiftUI

enum AppHaptics {
    static let selection: SensoryFeedback = .selection
    static let add: SensoryFeedback = .impact(weight: .light)
    static let warning: SensoryFeedback = .warning

    static func taskCompletion(isCompleted: Bool) -> SensoryFeedback {
        isCompleted ? .success : .impact(weight: .light)
    }
}
