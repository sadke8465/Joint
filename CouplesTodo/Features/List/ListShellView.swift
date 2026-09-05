import SwiftUI

private enum TaskFilter: String, CaseIterable, Identifiable {
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

struct ListShellView: View {
    let completedTaskIDs: Set<String>
    let onToggle: (MockTask) -> Void

    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    @State private var showsCompleted = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                filterBar
                datedTasks
                somedayTasks
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
                ForEach(TaskFilter.allCases) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.titleKey)
                            .font(AppTypography.caption)
                            .foregroundStyle(
                                selectedFilter == filter ? .white : AppColors.secondaryText
                            )
                            .padding(.horizontal, AppSpacing.medium)
                            .frame(minHeight: 36)
                            .background(
                                selectedFilter == filter ? AppColors.accent : AppColors.surface,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                    .accessibilityIdentifier("filter-\(filter.rawValue)")
                }

                filterChip("filter.today", icon: "sun.max")
                filterChip("filter.this_week", icon: "calendar.badge.clock")
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .accessibilityLabel(Text("list.filters"))
    }

    private var datedTasks: some View {
        taskSection(title: "list.dated", tasks: filteredTasks.filter { $0.id != "getaway" })
    }

    private var somedayTasks: some View {
        taskSection(title: "list.someday", tasks: filteredTasks.filter { $0.id == "getaway" })
    }

    private var completedTasks: some View {
        DisclosureGroup(isExpanded: $showsCompleted) {
            ForEach(MockContent.completedTasks) { task in
                TaskCard(task: task, isCompleted: true) {
                    onToggle(task)
                }
                .padding(.top, AppSpacing.small)
            }
        } label: {
            Text("list.recently_completed")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.secondaryText)
        }
        .tint(AppColors.secondaryText)
        .appCard()
    }

    private var filteredTasks: [MockTask] {
        MockContent.activeTasks.filter { task in
            let matchesFilter: Bool = switch selectedFilter {
            case .all: true
            case .mine: task.assignee == .me
            case .partner: task.assignee == .partner
            case .together: task.assignee == .together
            }

            let matchesSearch = searchText.isEmpty
                || task.fallbackTitle.localizedCaseInsensitiveContains(searchText)

            return matchesFilter && matchesSearch
        }
    }

    private func taskSection(title: LocalizedStringKey, tasks: [MockTask]) -> some View {
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
                    TaskCard(
                        task: task,
                        isCompleted: completedTaskIDs.contains(task.id),
                        onToggle: { onToggle(task) }
                    )
                }
            }
        }
    }

    private func filterChip(_ title: LocalizedStringKey, icon: String) -> some View {
        Button(action: {}) {
            Label(title, systemImage: icon)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
                .padding(.horizontal, AppSpacing.medium)
                .frame(minHeight: 36)
                .background(AppColors.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
