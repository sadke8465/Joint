import SwiftUI

struct TaskItemContent: Identifiable, Equatable {
    let id: String
    var title: String
    var dueText: String
    var assignee: String
    var assigneeIndicators: [TaskAssigneeIndicator]
    var isCompleted: Bool
}

enum TaskAssigneeIndicator: Equatable {
    case cyan
    case pink

    fileprivate var color: Color {
        switch self {
        case .cyan:
            TaskItemPalette.cyan
        case .pink:
            TaskItemPalette.pink
        }
    }
}

struct TaskItemView: View {
    let item: TaskItemContent
    let onToggleCompletion: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            regularLayout
            compactLayout
        }
        .padding(TaskItemMetrics.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            TaskItemPalette.surface,
            in: RoundedRectangle(
                cornerRadius: TaskItemMetrics.cardCornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: TaskItemMetrics.cardCornerRadius,
                style: .continuous
            )
            .strokeBorder(TaskItemPalette.border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 1)
    }

    private var regularLayout: some View {
        HStack(alignment: .top, spacing: TaskItemMetrics.outerSpacing) {
            leadingContent(reservesIdealTextWidth: true)

            Spacer(minLength: 0)

            assignee
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: TaskItemMetrics.contentSpacing) {
            leadingContent(reservesIdealTextWidth: false)

            assignee
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func leadingContent(reservesIdealTextWidth: Bool) -> some View {
        HStack(alignment: .top, spacing: TaskItemMetrics.contentSpacing) {
            TaskCompletionButton(
                title: item.title,
                isCompleted: item.isCompleted,
                action: onToggleCompletion
            )

            VStack(alignment: .leading, spacing: TaskItemMetrics.detailSpacing) {
                Text(item.title)
                    .foregroundStyle(TaskItemPalette.primaryText)

                Text(item.dueText)
                    .foregroundStyle(TaskItemPalette.secondaryText)
            }
            .font(.caption)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: reservesIdealTextWidth, vertical: true)
            .padding(.top, 1)
        }
    }

    private var assignee: some View {
        HStack(spacing: TaskItemMetrics.indicatorLabelSpacing) {
            Text(item.assignee)
                .font(.caption)
                .foregroundStyle(TaskItemPalette.secondaryText)
                .fixedSize(horizontal: true, vertical: false)

            HStack(spacing: -TaskItemMetrics.indicatorOverlap) {
                ForEach(Array(item.assigneeIndicators.enumerated()), id: \.offset) { _, indicator in
                    Circle()
                        .fill(indicator.color)
                        .frame(
                            width: TaskItemMetrics.indicatorSize,
                            height: TaskItemMetrics.indicatorSize
                        )
                }
            }
            .accessibilityHidden(true)
        }
    }
}

private struct TaskCompletionButton: View {
    let title: String
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        isCompleted
                            ? TaskItemPalette.completed
                            : TaskItemPalette.incompleteBackground
                    )

                if !isCompleted {
                    Circle()
                        .strokeBorder(TaskItemPalette.border, lineWidth: 1)
                }

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(
                width: TaskItemMetrics.completionSize,
                height: TaskItemMetrics.completionSize
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isCompleted ? "Mark \(title) incomplete" : "Mark \(title) complete"
        )
        .accessibilityValue(isCompleted ? "Completed" : "Incomplete")
    }
}

private enum TaskItemMetrics {
    static let cardPadding: CGFloat = 12
    static let cardCornerRadius: CGFloat = 12
    static let outerSpacing: CGFloat = 12
    static let contentSpacing: CGFloat = 8
    static let detailSpacing: CGFloat = 2
    static let completionSize: CGFloat = 32
    static let indicatorLabelSpacing: CGFloat = 4
    static let indicatorSize: CGFloat = 8
    static let indicatorOverlap: CGFloat = 4
}

private enum TaskItemPalette {
    static let surface = Color.white
    static let border = Color(red: 234 / 255, green: 234 / 255, blue: 234 / 255)
    static let incompleteBackground = Color(red: 246 / 255, green: 246 / 255, blue: 246 / 255)
    static let completed = Color(red: 49 / 255, green: 49 / 255, blue: 49 / 255)
    static let primaryText = completed
    static let secondaryText = primaryText.opacity(0.5)
    static let cyan = Color(red: 0 / 255, green: 201 / 255, blue: 249 / 255)
    static let pink = Color(red: 255 / 255, green: 0 / 255, blue: 48 / 255)
}
