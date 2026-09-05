import SwiftUI
import SwiftData

struct TaskComposerView: View {
    let store: TaskStore
    let taskID: UUID?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var title: String
    @State private var notes: String
    @State private var assignee: MemberStyle
    @State private var hasDate: Bool
    @State private var dueDate: Date
    @State private var hasTime: Bool
    @State private var dueTime: Date
    @State private var selectedListID: UUID?
    @State private var showsListCreator = false
    @State private var newListEmoji = ""
    @State private var newListTitle = ""
    @State private var saveFeedbackTrigger = 0
    @FocusState private var titleIsFocused: Bool

    init(store: TaskStore, taskID: UUID?) {
        self.store = store
        self.taskID = taskID

        let task = store.task(id: taskID)
        let identity = store.identity
        let calendar = Calendar.current
        let defaultDate = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
        let storedDueDate = task?.dueDate ?? defaultDate
        let storedDueTime = task?.dueDateTime(calendar: calendar) ?? .now

        _title = State(initialValue: task?.title ?? "")
        _notes = State(initialValue: task?.notes ?? "")
        _assignee = State(initialValue: task.map { MemberStyle(task: $0, identity: identity) } ?? .together)
        _hasDate = State(initialValue: task?.dueDate != nil)
        _dueDate = State(initialValue: storedDueDate)
        _hasTime = State(initialValue: task?.dueTime != nil)
        _dueTime = State(initialValue: storedDueTime)
        _selectedListID = State(initialValue: task?.listID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                    titleField
                    assigneeSection
                    scheduleSection
                    emojiListSection
                    notesSection
                }
                .padding(AppSpacing.large)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.background)
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .navigationTitle(Text(LocalizedStringKey(isEditing ? "composer.edit_task" : "composer.new_task")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("composer-done")
                }
            }
        }
        .onAppear {
            titleIsFocused = !isEditing
        }
        .onChange(of: hasDate) { _, hasDate in
            if !hasDate { hasTime = false }
        }
        .alert("composer.new_list", isPresented: $showsListCreator) {
            TextField("composer.list_emoji", text: $newListEmoji)
            TextField("composer.list_name", text: $newListTitle)
            Button("action.cancel", role: .cancel) {
                resetListCreator()
            }
            Button("action.create") {
                createCustomList()
            }
            .disabled(!canCreateList)
        } message: {
            Text("composer.new_list_help")
        }
        .sensoryFeedback(AppHaptics.selection, trigger: assignee)
        .sensoryFeedback(AppHaptics.add, trigger: saveFeedbackTrigger)
        .accessibilityIdentifier("task-composer")
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("composer.title_label")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)

            TextField("composer.title_placeholder", text: $title, axis: .vertical)
                .font(AppTypography.body)
                .lineLimit(1...3)
                .submitLabel(.done)
                .focused($titleIsFocused)
                .onSubmit(save)
                .accessibilityIdentifier("task-title")
        }
        .appCard()
    }

    private var assigneeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("composer.assignee")
                .font(AppTypography.sectionTitle)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.small) {
                    assigneeButtons
                }
            } else {
                HStack(spacing: AppSpacing.small) {
                    assigneeButtons
                }
            }
        }
    }

    @ViewBuilder
    private var assigneeButtons: some View {
        ForEach(MemberStyle.allCases) { style in
            Button {
                assignee = style
            } label: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        HStack(spacing: AppSpacing.small) {
                            Image(systemName: style.iconName)
                            Text(style.composerLabelKey)
                            Spacer(minLength: 0)
                        }
                    } else {
                        VStack(spacing: AppSpacing.xSmall) {
                            Image(systemName: style.iconName)
                            Text(style.composerLabelKey)
                                .lineLimit(1)
                        }
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(assignee == style ? .white : style.color)
                .padding(.horizontal, AppSpacing.small)
                .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 52 : 64)
                .background(
                    assignee == style ? style.color : style.color.opacity(0.11),
                    in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(style.composerLabelKey)
            .accessibilityAddTraits(assignee == style ? .isSelected : [])
            .accessibilityIdentifier("assignee-\(style.rawValue)")
        }
    }

    private var scheduleSection: some View {
        VStack(spacing: AppSpacing.medium) {
            Toggle(isOn: $hasDate) {
                Label("composer.date", systemImage: "calendar")
                    .foregroundStyle(AppColors.primaryText)
            }
            .tint(AppColors.accent)

            if hasDate {
                DatePicker(
                    "composer.date_value",
                    selection: $dueDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)

                Divider()

                Toggle(isOn: $hasTime) {
                    Label("composer.time", systemImage: "clock")
                        .foregroundStyle(AppColors.primaryText)
                }
                .tint(AppColors.accent)

                if hasTime {
                    DatePicker(
                        "composer.time_value",
                        selection: $dueTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.compact)
                }
            }
        }
        .font(AppTypography.body)
        .appCard()
    }

    private var emojiListSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("composer.emoji_list")
                .font(AppTypography.sectionTitle)

            Menu {
                Button("composer.none", systemImage: "xmark") {
                    selectedListID = nil
                }

                if !store.emojiLists.isEmpty {
                    Divider()
                    ForEach(store.emojiLists) { list in
                        Button("\(list.emoji) \(list.title)") {
                            selectedListID = list.id
                        }
                    }
                }

                Divider()
                Section("composer.suggestions") {
                    ForEach(EmojiListPreset.allCases) { preset in
                        Button("\(preset.emoji) \(preset.title)") {
                            selectPreset(preset)
                        }
                    }
                }

                Button("composer.create_list", systemImage: "plus") {
                    showsListCreator = true
                }
            } label: {
                HStack(spacing: AppSpacing.medium) {
                    Image(systemName: "face.smiling")
                        .frame(width: 28)

                    Text(selectedListLabel)
                        .foregroundStyle(AppColors.primaryText)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColors.tertiaryText)
                }
                .font(AppTypography.body)
                .frame(minHeight: 48)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .appCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("composer.notes")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)

            TextField("composer.notes_placeholder", text: $notes, axis: .vertical)
                .font(AppTypography.body)
                .lineLimit(2...5)
        }
        .appCard()
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(LocalizedStringKey(isEditing ? "composer.save" : "composer.add"))
                .font(AppTypography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(.white)
                .background(canSave ? AppColors.accent : AppColors.tertiaryText, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.small)
        .background(AppColors.background.opacity(0.97))
        .accessibilityIdentifier("composer-add")
    }

    private var isEditing: Bool {
        taskID != nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canCreateList: Bool {
        EmojiList.isValidEmoji(newListEmoji)
            && !newListTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var selectedListLabel: String {
        guard let list = store.emojiList(id: selectedListID) else {
            return String(localized: "composer.none")
        }
        return "\(list.emoji) \(list.title)"
    }

    private func save() {
        guard canSave else { return }
        let assignment = assignee.assignment(identity: store.identity)
        let timeComponents = hasDate && hasTime
            ? Calendar.current.dateComponents([.hour, .minute], from: dueTime)
            : nil
        let draft = TaskDraft(
            title: title,
            notes: notes,
            assigneeKind: assignment.kind,
            assigneeUserID: assignment.userID,
            dueDate: hasDate ? dueDate : nil,
            dueTime: timeComponents,
            listID: selectedListID
        )

        let didSave: Bool
        if let taskID {
            didSave = store.update(id: taskID, with: draft)
        } else {
            didSave = store.create(draft)
        }

        if didSave {
            saveFeedbackTrigger += 1
            dismiss()
        }
    }

    private func selectPreset(_ preset: EmojiListPreset) {
        if let existing = store.emojiLists.first(where: { $0.emoji == preset.emoji }) {
            selectedListID = existing.id
            return
        }

        selectedListID = store.createEmojiList(emoji: preset.emoji, title: preset.title)?.id
    }

    private func createCustomList() {
        guard canCreateList else { return }
        selectedListID = store.createEmojiList(
            emoji: newListEmoji,
            title: newListTitle
        )?.id
        resetListCreator()
    }

    private func resetListCreator() {
        newListEmoji = ""
        newListTitle = ""
    }
}

private enum EmojiListPreset: String, CaseIterable, Identifiable {
    case shopping
    case home
    case plans

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .shopping: "🛒"
        case .home: "🏠"
        case .plans: "✨"
        }
    }

    var title: String {
        switch self {
        case .shopping: String(localized: "list.preset.shopping")
        case .home: String(localized: "list.preset.home")
        case .plans: String(localized: "list.preset.plans")
        }
    }
}

#Preview("Composer") {
    let environment = AppEnvironment.preview()
    TaskComposerView(store: environment.taskStore, taskID: nil)
        .modelContainer(environment.modelContainer)
}
