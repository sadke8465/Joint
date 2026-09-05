import SwiftUI

private enum AssignmentFilter: String, CaseIterable, Identifiable {
    case all
    case mine
    case partner
    case together

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "filter.all"
        case .mine: "filter.mine"
        case .partner: "filter.partner"
        case .together: "filter.together"
        }
    }
}

private enum DateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case thisWeek
    case overdue

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .all: "filter.any_date"
        case .today: "filter.today"
        case .thisWeek: "filter.this_week"
        case .overdue: "filter.overdue"
        }
    }

    var iconName: String {
        switch self {
        case .all: "calendar"
        case .today: "sun.max"
        case .thisWeek: "calendar.badge.clock"
        case .overdue: "exclamationmark.calendar"
        }
    }
}

struct ListShellView: View {
    let store: TaskStore
    let onEdit: (TaskItem) -> Void

    @State private var assignmentFilter: AssignmentFilter = .all
    @State private var dateFilter: DateFilter = .all
    @State private var selectedListID: UUID?
    @State private var searchText = ""
    @State private var showsCompleted = false

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                filterBar
                taskSection(title: "list.dated", tasks: datedTasks)
                taskSection(title: "list.someday", tasks: somedayTasks)
                completedTasks
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .scrollIndicators(.hidden)
        .searchable(text: $searchText, prompt: Text("list.search"))
        .accessibilityIdentifier("list-screen")
    }

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppSpacing.small) {
                ForEach(AssignmentFilter.allCases) { filter in
                    filterButton(
                        title: filter.titleKey,
                        isSelected: assignmentFilter == filter
                    ) {
                        assignmentFilter = filter
                    }
                    .accessibilityIdentifier("filter-\(filter.rawValue)")
                }

                Menu {
                    Picker("list.date_filter", selection: $dateFilter) {
                        ForEach(DateFilter.allCases) { filter in
                            Label(filter.titleKey, systemImage: filter.iconName)
                                .tag(filter)
                        }
                    }
                } label: {
                    Label(dateFilter.titleKey, systemImage: dateFilter.iconName)
                        .font(AppTypography.caption)
                        .foregroundStyle(dateFilter == .all ? AppColors.secondaryText : .white)
                        .padding(.horizontal, AppSpacing.medium)
                        .frame(minHeight: 36)
                        .background(dateFilter == .all ? AppColors.surface : AppColors.accent, in: Capsule())
                }

                ForEach(store.emojiLists) { list in
                    Button {
                        selectedListID = selectedListID == list.id ? nil : list.id
                    } label: {
                        Text("\(list.emoji) \(list.title)")
                            .font(AppTypography.caption)
                            .foregroundStyle(selectedListID == list.id ? .white : AppColors.secondaryText)
                            .padding(.horizontal, AppSpacing.medium)
                            .frame(minHeight: 36)
                            .background(selectedListID == list.id ? AppColors.accent : AppColors.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedListID == list.id ? .isSelected : [])
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel(Text("list.filters"))
    }

    private var completedTasks: some View {
        DisclosureGroup(isExpanded: $showsCompleted) {
            if filteredCompletedTasks.isEmpty {
                Text("archive.empty")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, AppSpacing.small)
            } else {
                ForEach(filteredCompletedTasks.prefix(5)) { task in
                    taskCard(task)
                        .padding(.top, AppSpacing.small)
                }
            }
        } label: {
            Text("list.recently_completed")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.secondaryText)
        }
        .tint(AppColors.secondaryText)
        .appCard()
    }

    private var filteredTasks: [TaskItem] {
        store.activeTasks.filter(matchesAllFilters)
    }

    private var filteredCompletedTasks: [TaskItem] {
        store.completedTasks.filter { task in
            matchesAssignment(task)
                && matchesList(task)
                && task.matches(searchText)
        }
    }

    private var datedTasks: [TaskItem] {
        filteredTasks.filter { $0.dueDate != nil }
    }

    private var somedayTasks: [TaskItem] {
        filteredTasks.filter { $0.dueDate == nil }
    }

    private func matchesAllFilters(_ task: TaskItem) -> Bool {
        matchesAssignment(task)
            && matchesDate(task)
            && matchesList(task)
            && task.matches(searchText)
    }

    private func matchesAssignment(_ task: TaskItem) -> Bool {
        switch assignmentFilter {
        case .all:
            return true
        case .mine:
            return task.assigneeKind == .person && task.assigneeUserID == store.identity.currentUserID
        case .partner:
            return task.assigneeKind == .person && task.assigneeUserID == store.identity.partnerUserID
        case .together:
            return task.assigneeKind == .together
        }
    }

    private func matchesDate(_ task: TaskItem) -> Bool {
        switch dateFilter {
        case .all:
            return true
        case .today:
            return task.dueDate.map(calendar.isDateInToday) ?? false
        case .thisWeek:
            guard let dueDate = task.dueDate,
                  let interval = calendar.dateInterval(of: .weekOfYear, for: .now) else {
                return false
            }
            return interval.contains(dueDate)
        case .overdue:
            guard let dueDate = task.dueDate else { return false }
            return dueDate < calendar.startOfDay(for: .now)
        }
    }

    private func matchesList(_ task: TaskItem) -> Bool {
        selectedListID == nil || task.listID == selectedListID
    }

    private func taskSection(title: LocalizedStringKey, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.primaryText)

            if tasks.isEmpty {
                Text("list.no_matches")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCard()
            } else {
                ForEach(tasks) { task in
                    taskCard(task)
                }
            }
        }
    }

    private func filterButton(
        title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(isSelected ? .white : AppColors.secondaryText)
                .padding(.horizontal, AppSpacing.medium)
                .frame(minHeight: 36)
                .background(isSelected ? AppColors.accent : AppColors.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func taskCard(_ task: TaskItem) -> some View {
        TaskCard(
            task: task,
            identity: store.identity,
            emojiList: store.emojiList(id: task.listID),
            onToggle: { store.toggleCompletion(for: task) },
            onEdit: { onEdit(task) },
            onDelete: { store.moveToTrash(task) }
        )
    }
}
