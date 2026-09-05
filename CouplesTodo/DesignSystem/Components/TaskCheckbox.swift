import SwiftUI

struct TaskCheckbox: View {
    let isCompleted: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(isCompleted ? AppColors.accent : AppColors.tertiaryText)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? Text("task.mark_incomplete") : Text("task.mark_complete"))
        .accessibilityValue(isCompleted ? Text("task.completed") : Text("task.incomplete"))
        .animation(AppMotion.content(reduceMotion: reduceMotion), value: isCompleted)
        .sensoryFeedback(trigger: isCompleted) { _, newValue in
            AppHaptics.taskCompletion(isCompleted: newValue)
        }
    }
}
