import SwiftUI

struct TaskCard: View {
    let task: MockTask
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            TaskCheckbox(isCompleted: isCompleted, action: onToggle)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(LocalizedStringKey(task.titleKey))
                    .font(AppTypography.taskTitle)
                    .foregroundStyle(isCompleted ? AppColors.tertiaryText : AppColors.primaryText)
                    .strikethrough(isCompleted, color: AppColors.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: AppSpacing.small) {
                    MemberBadge(style: task.assignee, compact: true)

                    if let timeKey = task.timeKey {
                        Label {
                            Text(LocalizedStringKey(timeKey))
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                    }

                    if let emoji = task.emoji {
                        Text(emoji)
                            .accessibilityLabel(Text("task.emoji_list"))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 5)
        }
        .appCard()
        .opacity(isCompleted ? 0.72 : 1)
        .accessibilityIdentifier("task-\(task.id)")
    }
}
