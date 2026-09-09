import Observation
import SwiftUI

@MainActor
@Observable
final class ListViewState {
    var primaryFilter: TaskFilter = .all
    var dateFilter: DateFilter = .all
    var searchText = ""
    var showsSearch = false
    var showsSomeday = true
    var showsCompleted = false
    var expandedTaskID: UUID?
}

struct ListFilterToolbar: View {
    let store: TaskStore
    let state: ListViewState
    let onAdd: (TaskCreationDefaults) -> Void

    var body: some View {
        @Bindable var state = state

        VStack(spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.small) {
                ScrollView(.horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        filterButton(.all, title: "filter.all")
                        filterButton(.assignee(.together), title: "filter.together")
                        filterButton(.assignee(.me), title: "filter.mine")
                        filterButton(.assignee(.partner), title: "filter.partner")

                        ForEach(store.emojiLists) { list in
                            filterButton(
                                .emojiList(list.id),
                                title: LocalizedStringKey("\(list.emoji) \(list.title)")
                            )
                        }
                    }
                    .padding(.vertical, 1)
                }
                .scrollIndicators(.hidden)

                Menu {
                    Button {
                        state.showsSearch.toggle()
                    } label: {
                        Label("list.search", systemImage: "magnifyingglass")
                    }

                    Picker("list.date_filter", selection: $state.dateFilter) {
                        ForEach(DateFilter.allCases) { filter in
                            Label(filter.titleKey, systemImage: filter.iconName)
                                .tag(filter)
                        }
                    }
                } label: {
                    Image(
                        systemName: state.dateFilter == .all
                            ? "line.3.horizontal.decrease"
                            : "line.3.horizontal.decrease.circle.fill"
                    )
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(AppColors.groupedBackground, in: Circle())
                }
                .foregroundStyle(
                    state.dateFilter == .all ? AppColors.secondaryText : AppColors.accent
                )
                .accessibilityLabel(Text("list.filters"))
                .accessibilityIdentifier("advanced-filters")

                Button {
                    onAdd(state.primaryFilter.creationDefaults)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(AppCircularButtonStyle(size: 44))
                .accessibilityLabel(Text("task.add"))
                .accessibilityIdentifier("add-task")
            }

            if state.showsSearch {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.tertiaryText)

                    TextField("list.search", text: $state.searchText)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .accessibilityIdentifier("task-search")

                    Button {
                        state.searchText = ""
                        state.showsSearch = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .frame(width: 44, height: 44)
                    }
                    .foregroundStyle(AppColors.tertiaryText)
                    .accessibilityLabel(Text("action.cancel"))
                }
                .font(AppTypography.body)
                .padding(.leading, AppSpacing.medium)
                .background(AppColors.surface, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(AppColors.border.opacity(0.72), lineWidth: 1)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.vertical, AppSpacing.small)
        .background(AppColors.canvas)
    }

    private func filterButton(_ filter: TaskFilter, title: LocalizedStringKey) -> some View {
        Button {
            state.primaryFilter = filter
        } label: {
            Text(title)
        }
        .buttonStyle(
            AppPillButtonStyle(
                isSelected: state.primaryFilter == filter,
                tint: filterTint(filter)
            )
        )
        .accessibilityAddTraits(state.primaryFilter == filter ? .isSelected : [])
        .accessibilityIdentifier("filter-\(filter.id)")
    }

    private func filterTint(_ filter: TaskFilter) -> Color {
        switch filter {
        case .all: AppColors.primaryText
        case .assignee(let style): style.color
        case .emojiList: AppColors.violet
        }
    }
}

struct ListShellView: View {
    let store: TaskStore
    let state: ListViewState
    let onEdit: (TaskItem) -> Void

    private var calendar: Calendar { .current }

    var body: some View {
        @Bindable var state = state

        List {
            if filteredTasks.isEmpty && filteredCompletedTasks.isEmpty {
                noResultsRow
            } else {
                ForEach(datedTasks) { task in
                    taskRow(task)
                }

                if !somedayTasks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $state.showsSomeday) {
                            ForEach(somedayTasks) { task in
                                taskRow(task)
                            }
                        } label: {
                            sectionLabel("list.someday", count: somedayTasks.count)
                        }
                        .tint(AppColors.secondaryText)
                        .listRowBackground(AppColors.canvas)
                        .listRowSeparator(.hidden)
                    }
                }

                if !filteredCompletedTasks.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $state.showsCompleted) {
                            ForEach(filteredCompletedTasks) { task in
                                taskRow(task)
                            }
                        } label: {
                            sectionLabel("list.recently_completed", count: filteredCompletedTasks.count)
                        }
                        .tint(AppColors.secondaryText)
                        .listRowBackground(AppColors.canvas)
                        .listRowSeparator(.hidden)
                    }
                }
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
        .scrollContentBackground(.hidden)
        .background(AppColors.canvas)
        .accessibilityIdentifier("list-screen")
    }

    private var noResultsRow: some View {
        AppEmptyState(
            title: "list.no_matches",
            systemImage: "line.3.horizontal.decrease.circle",
            description: "week.no_tasks_description",
            tint: AppColors.violet,
            iconForeground: AppColors.primaryText
        )
        .listRowInsets(
            EdgeInsets(
                top: AppSpacing.large,
                leading: AppSpacing.screenMargin,
                bottom: AppSpacing.large,
                trailing: AppSpacing.screenMargin
            )
        )
        .listRowBackground(AppColors.canvas)
        .listRowSeparator(.hidden)
    }

    private func sectionLabel(_ title: LocalizedStringKey, count: Int) -> some View {
        HStack(spacing: AppSpacing.small) {
            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)

            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
                .lineLimit(1)

            Text("\(count)")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.tertiaryText)

            Rectangle()
                .fill(AppColors.border)
                .frame(height: 1)
        }
        .padding(.vertical, AppSpacing.medium)
    }

    private var filteredTasks: [TaskItem] {
        store.activeTasks.filter(matchesAllFilters)
    }

    private var filteredCompletedTasks: [TaskItem] {
        store.completedTasks.filter(matchesAllFilters)
    }

    private var datedTasks: [TaskItem] {
        filteredTasks.filter { $0.dueDate != nil }
    }

    private var somedayTasks: [TaskItem] {
        filteredTasks.filter { $0.dueDate == nil }
    }

    private func matchesAllFilters(_ task: TaskItem) -> Bool {
        state.primaryFilter.matches(task, identity: store.identity)
            && matchesDate(task)
            && task.matches(state.searchText)
    }

    private func matchesDate(_ task: TaskItem) -> Bool {
        switch state.dateFilter {
        case .all:
            true
        case .today:
            task.dueDate.map(calendar.isDateInToday) ?? false
        case .thisWeek:
            if let dueDate = task.dueDate,
               let interval = calendar.dateInterval(of: .weekOfYear, for: .now) {
                interval.contains(dueDate)
            } else {
                false
            }
        case .overdue:
            task.isOverdue()
        }
    }

    private func taskRow(_ task: TaskItem) -> some View {
        TaskCard(
            task: task,
            identity: store.identity,
            emojiList: store.emojiList(id: task.listID),
            emojiLists: store.emojiLists,
            onToggle: { store.toggleCompletion(for: task) },
            context: .tasks,
            isExpanded: Binding(
                get: { state.expandedTaskID == task.id },
                set: { isExpanded in
                    state.expandedTaskID = isExpanded ? task.id : nil
                }
            ),
            onUpdate: { draft in
                _ = store.update(id: task.id, with: draft)
            },
            onEdit: { onEdit(task) },
            onDelete: { store.moveToTrash(task) },
            onReschedule: { store.reschedule(task, to: $0) }
        )
        .listRowInsets(
            EdgeInsets(
                top: AppSpacing.small,
                leading: AppSpacing.screenMargin,
                bottom: AppSpacing.small,
                trailing: AppSpacing.screenMargin
            )
        )
        .listRowBackground(AppColors.canvas)
        .listRowSeparator(.hidden)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                store.toggleCompletion(for: task)
            } label: {
                Label(
                    LocalizedStringKey(
                        task.isCompleted ? "task.mark_incomplete" : "task.mark_complete"
                    ),
                    systemImage: task.isCompleted ? "arrow.uturn.backward" : "checkmark"
                )
            }
            .tint(AppColors.success)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.moveToTrash(task)
            } label: {
                Label("task.delete", systemImage: "trash")
            }
        }
    }
}

#Preview("List — Populated") {
    let environment = AppEnvironment.preview(populated: true)
    VStack(spacing: 0) {
        ListFilterToolbar(store: environment.taskStore, state: ListViewState(), onAdd: { _ in })
        ListShellView(store: environment.taskStore, state: ListViewState(), onEdit: { _ in })
    }
    .modelContainer(environment.modelContainer)
}
