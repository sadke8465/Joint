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
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.vertical, AppSpacing.xLarge)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.canvas)
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .navigationTitle(Text(LocalizedStringKey(isEditing ? "composer.edit_task" : "composer.new_task")))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("composer.done") {
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
                .font(AppTypography.dateHero)
                .lineLimit(1...3)
                .frame(minHeight: 64, alignment: .topLeading)
                .submitLabel(.done)
                .focused($titleIsFocused)
                .onSubmit(submitFromKeyboard)
                .accessibilityIdentifier("task-title")
        }
        .padding(.bottom, AppSpacing.medium)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
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
                                .font(.title3.weight(.bold))
                            Text(style.composerLabelKey)
                                .lineLimit(1)
                        }
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(assignee == style ? style.selectedForeground : style.labelColor)
                .padding(.horizontal, AppSpacing.small)
                .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 52 : 64)
                .background(
                    assignee == style ? style.color : style.color.opacity(0.11),
                    in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
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
        .appCard(.plain)
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
        .appCard(.soft)
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
        .appCard(.soft)
    }

    private var saveButton: some View {
        Button(action: saveAndClose) {
            Text(LocalizedStringKey(isEditing ? "composer.save" : "composer.add"))
        }
        .buttonStyle(AppPrimaryButtonStyle())
        .disabled(!canSave)
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.medium)
        .background(AppColors.canvas.shadow(.drop(color: .black.opacity(0.06), radius: 8, y: -2)))
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

    private func makeDraft() -> TaskDraft {
        let assignment = assignee.assignment(identity: store.identity)
        let timeComponents = hasDate && hasTime
            ? Calendar.current.dateComponents([.hour, .minute], from: dueTime)
            : nil
        return TaskDraft(
            title: title,
            notes: notes,
            assigneeKind: assignment.kind,
            assigneeUserID: assignment.userID,
            dueDate: hasDate ? dueDate : nil,
            dueTime: timeComponents,
            listID: selectedListID
        )
    }

    private func saveAndClose() {
        guard canSave else { return }
        let didSave = persistCurrentDraft()

        if didSave {
            saveFeedbackTrigger += 1
            dismiss()
        }
    }

    private func submitFromKeyboard() {
        guard canSave else { return }
        if isEditing {
            saveAndClose()
            return
        }

        guard persistCurrentDraft() else { return }
        saveFeedbackTrigger += 1
        resetForRapidEntry()
    }

    private func persistCurrentDraft() -> Bool {
        let draft = makeDraft()

        if let taskID {
            return store.update(id: taskID, with: draft)
        } else {
            return store.create(draft)
        }
    }

    private func resetForRapidEntry() {
        title = ""
        notes = ""
        assignee = .together
        hasDate = false
        hasTime = false
        selectedListID = nil
        dueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        dueTime = .now
        titleIsFocused = true
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

struct QuickAddTaskView: View {
    let store: TaskStore
    let defaults: TaskCreationDefaults

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var notes = ""
    @State private var assignee: MemberStyle
    @State private var hasDate = false
    @State private var dueDate = Date.now
    @State private var hasTime = false
    @State private var dueTime = Date.now
    @State private var selectedListID: UUID?
    @State private var showsNotes = false
    @State private var showsDetails = false
    @State private var saveFeedbackTrigger = 0
    @FocusState private var titleIsFocused: Bool

    init(store: TaskStore, defaults: TaskCreationDefaults) {
        self.store = store
        self.defaults = defaults
        _assignee = State(initialValue: defaults.assignee)
        _selectedListID = State(initialValue: defaults.listID)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                TextField("composer.title_placeholder", text: $title)
                    .font(AppTypography.dateHero)
                    .lineLimit(1)
                    .submitLabel(.done)
                    .focused($titleIsFocused)
                    .onSubmit(saveAndReset)
                    .accessibilityIdentifier("task-title")

                if showsNotes {
                    TextField("composer.notes_placeholder", text: $notes, axis: .vertical)
                        .font(AppTypography.body)
                        .lineLimit(1...4)
                        .padding(AppSpacing.medium)
                        .background(
                            AppColors.groupedBackground.opacity(0.68),
                            in: RoundedRectangle(cornerRadius: AppRadius.control)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                quickControls

                Button {
                    showsDetails = true
                } label: {
                    Label("task.edit", systemImage: "slider.horizontal.3")
                        .font(AppTypography.caption)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.secondaryText)
                .accessibilityIdentifier("quick-add-more-details")

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.large)
            .background(AppColors.surface)
            .navigationTitle(Text("composer.new_task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") { dismiss() }
                        .accessibilityIdentifier("composer-done")
                }
            }
            .navigationDestination(isPresented: $showsDetails) {
                QuickAddDetailsView(
                    store: store,
                    assignee: $assignee,
                    hasDate: $hasDate,
                    dueDate: $dueDate,
                    hasTime: $hasTime,
                    dueTime: $dueTime,
                    selectedListID: $selectedListID,
                    notes: $notes
                )
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: saveAndClose) {
                    Label("composer.add", systemImage: "arrow.up")
                }
                .buttonStyle(AppPrimaryButtonStyle(tint: assignee.color))
                .disabled(!canSave)
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.vertical, AppSpacing.medium)
                .background(AppColors.surface.opacity(0.98))
                .accessibilityIdentifier("composer-add")
            }
        }
        .onAppear { titleIsFocused = true }
        .onChange(of: hasDate) { _, hasDate in
            if !hasDate { hasTime = false }
        }
        .sensoryFeedback(AppHaptics.selection, trigger: assignee)
        .sensoryFeedback(AppHaptics.add, trigger: saveFeedbackTrigger)
        .accessibilityIdentifier("quick-add-sheet")
    }

    private var quickControls: some View {
        HStack(spacing: AppSpacing.small) {
            Menu {
                ForEach(MemberStyle.allCases) { style in
                    Button {
                        assignee = style
                    } label: {
                        Label(style.composerLabelKey, systemImage: style.iconName)
                    }
                }
            } label: {
                Label(assignee.composerLabelKey, systemImage: assignee.iconName)
                    .font(AppTypography.caption)
                    .foregroundStyle(assignee.labelColor)
                    .padding(.horizontal, AppSpacing.medium)
                    .frame(minHeight: 44)
                    .background(assignee.color.opacity(0.14), in: Capsule())
            }
            .accessibilityIdentifier("quick-add-assignee")

            if hasDate {
                DatePicker(
                    "composer.date_value",
                    selection: $dueDate,
                    displayedComponents: .date
                )
                .labelsHidden()
                .frame(minHeight: 44)
            } else {
                Button {
                    hasDate = true
                    dueDate = Calendar.current.startOfDay(for: .now)
                } label: {
                    Image(systemName: "calendar")
                        .frame(width: 44, height: 44)
                }
                .foregroundStyle(AppColors.secondaryText)
                .accessibilityLabel(Text("composer.date"))
            }

            Menu {
                Button("composer.none", systemImage: "xmark") {
                    selectedListID = nil
                }
                ForEach(store.emojiLists) { list in
                    Button("\(list.emoji) \(list.title)") {
                        selectedListID = list.id
                    }
                }
            } label: {
                Group {
                    if let selectedList {
                        Text(selectedList.emoji)
                            .font(.title3)
                    } else {
                        Image(systemName: "face.smiling")
                    }
                }
                .frame(width: 44, height: 44)
            }
            .foregroundStyle(AppColors.secondaryText)
            .accessibilityLabel(Text("composer.emoji_list"))

            Button {
                withAnimation(AppMotion.content(reduceMotion: false)) {
                    showsNotes.toggle()
                }
            } label: {
                Image(systemName: "text.alignleft")
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(showsNotes ? AppColors.accent : AppColors.secondaryText)
            .accessibilityLabel(Text("composer.notes"))
        }
    }

    private var selectedList: EmojiList? {
        store.emojiList(id: selectedListID)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func makeDraft() -> TaskDraft {
        let assignment = assignee.assignment(identity: store.identity)
        let timeComponents = hasDate && hasTime
            ? Calendar.current.dateComponents([.hour, .minute], from: dueTime)
            : nil
        return TaskDraft(
            title: title,
            notes: notes,
            assigneeKind: assignment.kind,
            assigneeUserID: assignment.userID,
            dueDate: hasDate ? dueDate : nil,
            dueTime: timeComponents,
            listID: selectedListID
        )
    }

    private func saveAndClose() {
        guard canSave, store.create(makeDraft()) else { return }
        saveFeedbackTrigger += 1
        dismiss()
    }

    private func saveAndReset() {
        guard canSave, store.create(makeDraft()) else { return }
        saveFeedbackTrigger += 1
        title = ""
        notes = ""
        assignee = defaults.assignee
        hasDate = false
        hasTime = false
        dueDate = .now
        dueTime = .now
        selectedListID = defaults.listID
        showsNotes = false
        titleIsFocused = true
    }
}

private struct QuickAddDetailsView: View {
    let store: TaskStore
    @Binding var assignee: MemberStyle
    @Binding var hasDate: Bool
    @Binding var dueDate: Date
    @Binding var hasTime: Bool
    @Binding var dueTime: Date
    @Binding var selectedListID: UUID?
    @Binding var notes: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text("composer.assignee")
                        .font(AppTypography.sectionTitle)

                    HStack(spacing: AppSpacing.small) {
                        ForEach(MemberStyle.allCases) { style in
                            Button {
                                assignee = style
                            } label: {
                                VStack(spacing: AppSpacing.xSmall) {
                                    Image(systemName: style.iconName)
                                    Text(style.composerLabelKey)
                                        .lineLimit(1)
                                }
                                .font(AppTypography.caption)
                                .foregroundStyle(
                                    assignee == style ? style.selectedForeground : style.labelColor
                                )
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(
                                    assignee == style ? style.color : style.color.opacity(0.11),
                                    in: RoundedRectangle(cornerRadius: AppRadius.card)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(spacing: AppSpacing.medium) {
                    Toggle("composer.date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("composer.date_value", selection: $dueDate, displayedComponents: .date)
                        Toggle("composer.time", isOn: $hasTime)
                        if hasTime {
                            DatePicker("composer.time_value", selection: $dueTime, displayedComponents: .hourAndMinute)
                        }
                    }
                }
                .tint(AppColors.accent)
                .appCard(.plain)

                Menu {
                    Button("composer.none", systemImage: "xmark") { selectedListID = nil }
                    ForEach(store.emojiLists) { list in
                        Button("\(list.emoji) \(list.title)") { selectedListID = list.id }
                    }
                } label: {
                    HStack {
                        Label("composer.emoji_list", systemImage: "face.smiling")
                        Spacer()
                        Text(selectedListLabel)
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .frame(minHeight: 52)
                }
                .buttonStyle(.plain)
                .appCard(.soft)

                TextField("composer.notes_placeholder", text: $notes, axis: .vertical)
                    .lineLimit(2...6)
                    .appCard(.soft)
            }
            .padding(AppSpacing.screenMargin)
        }
        .background(AppColors.canvas)
        .navigationTitle(Text("task.edit"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedListLabel: String {
        guard let list = store.emojiList(id: selectedListID) else {
            return String(localized: "composer.none")
        }
        return "\(list.emoji) \(list.title)"
    }
}

#Preview("Quick add") {
    let environment = AppEnvironment.preview(populated: true)
    QuickAddTaskView(store: environment.taskStore, defaults: TaskCreationDefaults())
        .modelContainer(environment.modelContainer)
}
