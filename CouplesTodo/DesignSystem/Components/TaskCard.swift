import SwiftUI

struct TaskCard: View {
    let task: TaskItem
    let identity: LocalIdentity
    let emojiList: EmojiList?
    let onToggle: () -> Void
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?
    var onReschedule: ((Date?) -> Void)?

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
                                Image(systemName: task.isOverdue() ? "exclamationmark.calendar" : "calendar")
                            }
                            .font(AppTypography.caption)
                            .foregroundStyle(task.isOverdue() ? Color.red : AppColors.secondaryText)
                            .accessibilityLabel(dueDateAccessibilityLabel(dueDate))
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

            if onEdit != nil || onDelete != nil || onReschedule != nil {
                Menu {
                    if let onEdit {
                        Button("task.edit", systemImage: "pencil", action: onEdit)
                    }
                    if let onReschedule {
                        Menu("task.reschedule", systemImage: "calendar.badge.clock") {
                            Button("date.today", systemImage: "sun.max") {
                                onReschedule(Calendar.current.startOfDay(for: .now))
                            }
                            Button("date.tomorrow", systemImage: "sunrise") {
                                onReschedule(
                                    Calendar.current.date(byAdding: .day, value: 1, to: .now)
                                )
                            }
                            Button("list.someday", systemImage: "calendar.badge.minus") {
                                onReschedule(nil)
                            }
                        }
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
        .accessibilityElement(children: .combine)
        .accessibilityAction {
            if let onEdit {
                onEdit()
            } else {
                onToggle()
            }
        }
        .accessibilityActions {
            Button(
                LocalizedStringKey(task.isCompleted ? "task.mark_incomplete" : "task.mark_complete"),
                action: onToggle
            )
            if let onEdit {
                Button("task.edit", action: onEdit)
            }
            if let onDelete {
                Button("task.delete", action: onDelete)
            }
        }
        .accessibilityIdentifier("task-\(task.id.uuidString)")
    }

    private func dueDateAccessibilityLabel(_ dueDate: Date) -> Text {
        if task.isOverdue() {
            Text("filter.overdue") + Text(", ") + Text(dueDate, format: .dateTime.month(.wide).day())
        } else {
            Text(dueDate, format: .dateTime.month(.wide).day())
        }
    }
}
