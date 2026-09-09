import SwiftUI

enum TaskCardContext: Hashable {
    case week
    case tasks
    case agenda
    case archive
}

struct TaskCard: View {
    let task: TaskItem
    let identity: LocalIdentity
    let emojiList: EmojiList?
    let emojiLists: [EmojiList]
    let onToggle: () -> Void
    let context: TaskCardContext
    @Binding var isExpanded: Bool
    let onUpdate: ((TaskDraft) -> Void)?
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let onReschedule: ((Date?) -> Void)?

    init(
        task: TaskItem,
        identity: LocalIdentity,
        emojiList: EmojiList?,
        emojiLists: [EmojiList] = [],
        onToggle: @escaping () -> Void,
        context: TaskCardContext = .tasks,
        isExpanded: Binding<Bool> = .constant(false),
        onUpdate: ((TaskDraft) -> Void)? = nil,
        onEdit: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onReschedule: ((Date?) -> Void)? = nil
    ) {
        self.task = task
        self.identity = identity
        self.emojiList = emojiList
        self.emojiLists = emojiLists
        self.onToggle = onToggle
        self.context = context
        _isExpanded = isExpanded
        self.onUpdate = onUpdate
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onReschedule = onReschedule
    }

    var body: some View {
        VStack(spacing: 0) {
            TaskCardSummary(
                task: task,
                identity: identity,
                emojiList: emojiList,
                context: context,
                isExpanded: isExpanded,
                canExpand: onUpdate != nil,
                onToggle: onToggle,
                onOpen: openSummary,
                onEdit: onEdit,
                onDelete: onDelete,
                onReschedule: onReschedule
            )

            if isExpanded, let onUpdate {
                Divider()
                    .overlay(AppColors.border.opacity(0.72))
                    .padding(.horizontal, AppSpacing.large)

                TaskInlineEditor(
                    task: task,
                    emojiLists: emojiLists,
                    onUpdate: onUpdate,
                    onMoreDetails: onEdit
                )
                .id(task.updatedAt)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            rowBackground,
            in: RoundedRectangle(cornerRadius: rowRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: rowRadius, style: .continuous)
                .strokeBorder(AppColors.border.opacity(usesBorder ? 0.72 : 0), lineWidth: 1)
        }
        .opacity(task.isCompleted ? 0.76 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-\(task.id.uuidString)")
    }

    private func openSummary() {
        if onUpdate != nil {
            isExpanded.toggle()
        } else {
            onEdit?()
        }
    }

    private var rowRadius: CGFloat {
        context == .archive ? AppRadius.control : AppRadius.card
    }

    private var rowBackground: Color {
        context == .archive ? .clear : AppColors.surface
    }

    private var usesBorder: Bool {
        context != .archive
    }
}

private struct TaskCardSummary: View {
    let task: TaskItem
    let identity: LocalIdentity
    let emojiList: EmojiList?
    let context: TaskCardContext
    let isExpanded: Bool
    let canExpand: Bool
    let onToggle: () -> Void
    let onOpen: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    let onReschedule: ((Date?) -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            TaskCheckbox(isCompleted: task.isCompleted, action: onToggle)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(task.title)
                        .font(AppTypography.taskTitle)
                        .foregroundStyle(
                            task.isCompleted ? AppColors.tertiaryText : AppColors.primaryText
                        )
                        .strikethrough(task.isCompleted, color: AppColors.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    TaskMetadata(
                        task: task,
                        identity: identity,
                        emojiList: emojiList,
                        context: context
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, AppSpacing.xSmall)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canExpand && onEdit == nil)
            .accessibilityHint(canExpand ? Text("task.edit") : Text(""))

            Menu {
                Button(
                    LocalizedStringKey(
                        task.isCompleted ? "task.mark_incomplete" : "task.mark_complete"
                    ),
                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark",
                    action: onToggle
                )

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
                    Divider()
                    Button("task.delete", systemImage: "trash", role: .destructive, action: onDelete)
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up.circle" : "ellipsis")
                    .font(.body.weight(.bold))
                    .frame(width: 40, height: 40)
                    .background(AppColors.groupedBackground, in: Circle())
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(AppColors.secondaryText)
            .accessibilityLabel(Text("task.actions"))
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .accessibilityActions {
            Button(
                LocalizedStringKey(
                    task.isCompleted ? "task.mark_incomplete" : "task.mark_complete"
                ),
                action: onToggle
            )
            if let onEdit {
                Button("task.edit", action: onEdit)
            }
            if let onDelete {
                Button("task.delete", action: onDelete)
            }
        }
    }
}

private struct TaskMetadata: View {
    let task: TaskItem
    let identity: LocalIdentity
    let emojiList: EmojiList?
    let context: TaskCardContext

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.small) { metadataItems }
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) { metadataItems }
        }
    }

    @ViewBuilder
    private var metadataItems: some View {
        if context != .week {
            MemberBadge(style: MemberStyle(task: task, identity: identity), compact: true)
        }

        if context != .week, let dueDate = task.dueDate {
            Label {
                Text(dueDate, format: .dateTime.month(.abbreviated).day())
            } icon: {
                Image(systemName: task.isOverdue() ? "exclamationmark.calendar" : "calendar")
            }
            .font(AppTypography.caption)
            .foregroundStyle(task.isOverdue() ? AppColors.danger : AppColors.secondaryText)
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
                .font(AppTypography.metadata)
                .accessibilityLabel(Text(emojiList.title))
        }

        if task.notes?.isEmpty == false {
            Image(systemName: "text.alignleft")
                .font(.caption)
                .foregroundStyle(AppColors.tertiaryText)
                .accessibilityLabel(Text("composer.notes"))
        }
    }
}

private struct TaskInlineEditor: View {
    let task: TaskItem
    let emojiLists: [EmojiList]
    let onUpdate: (TaskDraft) -> Void
    let onMoreDetails: (() -> Void)?

    @State private var hasDate: Bool
    @State private var dueDate: Date
    @State private var selectedListID: UUID?
    @State private var notes: String
    @FocusState private var notesFocused: Bool
    @Environment(\.openURL) private var openURL

    init(
        task: TaskItem,
        emojiLists: [EmojiList],
        onUpdate: @escaping (TaskDraft) -> Void,
        onMoreDetails: (() -> Void)?
    ) {
        self.task = task
        self.emojiLists = emojiLists
        self.onUpdate = onUpdate
        self.onMoreDetails = onMoreDetails
        _hasDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? .now)
        _selectedListID = State(initialValue: task.listID)
        _notes = State(initialValue: task.notes ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Toggle(isOn: dateBinding) {
                Label("composer.date", systemImage: "calendar")
            }
            .tint(AppColors.accent)

            if hasDate {
                HStack(spacing: AppSpacing.small) {
                    DatePicker(
                        "composer.date_value",
                        selection: dueDateBinding,
                        displayedComponents: .date
                    )
                    .labelsHidden()

                    Spacer(minLength: 0)

                    if let calendarURL {
                        Button {
                            openURL(calendarURL)
                        } label: {
                            Label("settings.calendar", systemImage: "calendar.badge.plus")
                        }
                        .buttonStyle(.bordered)
                        .font(AppTypography.caption)
                        .accessibilityIdentifier("task-add-calendar")
                    }
                }
            }

            Menu {
                Button("composer.none", systemImage: "xmark") {
                    updateList(nil)
                }
                ForEach(emojiLists) { list in
                    Button("\(list.emoji) \(list.title)") {
                        updateList(list.id)
                    }
                }
            } label: {
                HStack {
                    Label(selectedListLabel, systemImage: "face.smiling")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)

            TextField("composer.notes_placeholder", text: $notes, axis: .vertical)
                .lineLimit(1...4)
                .focused($notesFocused)
                .submitLabel(.done)
                .onSubmit(commitNotes)
                .onChange(of: notesFocused) { _, focused in
                    if !focused { commitNotes() }
                }
                .padding(AppSpacing.medium)
                .background(AppColors.groupedBackground.opacity(0.68), in: RoundedRectangle(cornerRadius: AppRadius.control))
                .accessibilityIdentifier("task-inline-notes")

            if let onMoreDetails {
                Button("task.edit", systemImage: "slider.horizontal.3", action: onMoreDetails)
                    .font(AppTypography.caption)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .accessibilityIdentifier("task-more-details")
            }
        }
        .font(AppTypography.body)
        .padding(AppSpacing.large)
        .background(AppColors.groupedBackground.opacity(0.30))
    }

    private var dateBinding: Binding<Bool> {
        Binding(
            get: { hasDate },
            set: { newValue in
                hasDate = newValue
                var draft = TaskDraft(task: task)
                draft.dueDate = newValue ? dueDate : nil
                onUpdate(draft)
            }
        )
    }

    private var dueDateBinding: Binding<Date> {
        Binding(
            get: { dueDate },
            set: { newValue in
                dueDate = newValue
                var draft = TaskDraft(task: task)
                draft.dueDate = newValue
                onUpdate(draft)
            }
        )
    }

    private var selectedListLabel: LocalizedStringKey {
        guard let list = emojiLists.first(where: { $0.id == selectedListID }) else {
            return "composer.none"
        }
        return LocalizedStringKey("\(list.emoji) \(list.title)")
    }

    private func updateList(_ listID: UUID?) {
        selectedListID = listID
        var draft = TaskDraft(task: task)
        draft.listID = listID
        onUpdate(draft)
    }

    private func commitNotes() {
        guard notes != (task.notes ?? "") else { return }
        var draft = TaskDraft(task: task)
        draft.notes = notes
        onUpdate(draft)
    }

    private var calendarURL: URL? {
        guard let dueDate = task.dueDate else { return nil }
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 1, to: dueDate) ?? dueDate
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"

        var components = URLComponents(string: "https://calendar.google.com/calendar/render")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "TEMPLATE"),
            URLQueryItem(name: "text", value: task.title),
            URLQueryItem(
                name: "dates",
                value: "\(formatter.string(from: dueDate))/\(formatter.string(from: endDate))"
            ),
            URLQueryItem(name: "details", value: task.notes)
        ]
        return components?.url
    }
}
