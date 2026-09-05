import SwiftUI

struct TaskCard: View {
    let task: TaskItem
    let identity: LocalIdentity
    let emojiList: EmojiList?
    let onToggle: () -> Void
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            TaskCheckbox(isCompleted: task.isCompleted, action: onToggle)

            Button(action: { onEdit?() }) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(task.title)
                        .font(AppTypography.taskTitle)
                        .foregroundStyle(task.isCompleted ? AppColors.tertiaryText : AppColors.primaryText)
                        .strikethrough(task.isCompleted, color: AppColors.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: AppSpacing.small) {
                        MemberBadge(
                            style: MemberStyle(task: task, identity: identity),
                            compact: true
                        )

                        if let dueDate = task.dueDate {
                            Label {
                                Text(dueDate, format: .dateTime.month(.abbreviated).day())
                            } icon: {
                                Image(systemName: "calendar")
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                        }

                        if task.dueTime != nil, let dueDateTime = task.dueDateTime() {
                            Label {
                                Text(dueDateTime, style: .time)
                            } icon: {
                                Image(systemName: "clock")
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.secondaryText)
                        }

                        if let emojiList {
                            Text(emojiList.emoji)
                                .accessibilityLabel(Text(emojiList.title))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(onEdit == nil)

            if onEdit != nil || onDelete != nil {
                Menu {
                    if let onEdit {
                        Button("task.edit", systemImage: "pencil", action: onEdit)
                    }
                    if let onDelete {
                        Button("task.delete", systemImage: "trash", role: .destructive, action: onDelete)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 36, height: 44)
                        .contentShape(Rectangle())
                }
                .foregroundStyle(AppColors.secondaryText)
                .accessibilityLabel(Text("task.actions"))
            }
        }
        .appCard()
        .opacity(task.isCompleted ? 0.72 : 1)
        .accessibilityIdentifier("task-\(task.id.uuidString)")
    }
}
