import SwiftUI

struct WeekShellView: View {
    let store: TaskStore
    let onEdit: (TaskItem) -> Void

    @State private var weekStart = Self.startOfCurrentWeek
    @State private var showsCompleted = false

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xLarge) {
                weekNavigator

                if datedTasks.isEmpty {
                    ContentUnavailableView(
                        "week.no_tasks",
                        systemImage: "calendar.badge.checkmark",
                        description: Text("week.no_tasks_description")
                    )
                    .appCard()
                } else {
                    ForEach(daysWithTasks, id: \.self) { day in
                        daySection(day)
                    }
                }

                if !somedayTasks.isEmpty {
                    taskSection(title: "list.someday", tasks: somedayTasks)
                }

                completedSection
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("week-screen")
    }

    private var weekNavigator: some View {
        HStack(spacing: AppSpacing.medium) {
            Button {
                moveWeek(by: -1)
            } label: {
                Image(systemName: "chevron.backward")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("week.previous"))

            VStack(spacing: 2) {
                Text(weekRangeText)
                    .font(AppTypography.sectionTitle)
                if isCurrentWeek {
                    Text("week.current")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.accent)
                }
            }
            .frame(maxWidth: .infinity)

            Button {
                moveWeek(by: 1)
            } label: {
                Image(systemName: "chevron.forward")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("week.next"))
        }
        .foregroundStyle(AppColors.primaryText)
        .accessibilityElement(children: .contain)
    }

    private func daySection(_ day: Date) -> some View {
        let tasks = datedTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: day)
        }

        return VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                dayTitle(day)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(calendar.isDateInToday(day) ? AppColors.accent : AppColors.primaryText)

                Spacer()

                Text(day, format: .dateTime.month(.abbreviated).day())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            ForEach(tasks) { task in
                taskCard(task)
            }
        }
        .padding(calendar.isDateInToday(day) ? AppSpacing.medium : 0)
        .background(
            calendar.isDateInToday(day) ? AppColors.accentSoft.opacity(0.55) : .clear,
            in: RoundedRectangle(cornerRadius: AppRadius.sheetSection, style: .continuous)
        )
    }

    private func taskSection(title: LocalizedStringKey, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.primaryText)

            ForEach(tasks) { task in
                taskCard(task)
            }
        }
    }

    private var completedSection: some View {
        DisclosureGroup(isExpanded: $showsCompleted) {
            if store.completedTasks.isEmpty {
                Text("archive.empty")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, AppSpacing.small)
            } else {
                ForEach(store.completedTasks.prefix(5)) { task in
                    taskCard(task)
                        .padding(.top, AppSpacing.small)
                }
            }
        } label: {
            Label("week.done", systemImage: "checkmark.circle.fill")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.secondaryText)
        }
        .tint(AppColors.secondaryText)
        .appCard()
    }

    private var datedTasks: [TaskItem] {
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        return store.activeTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= weekStart && dueDate < weekEnd
        }
    }

    private var somedayTasks: [TaskItem] {
        guard isCurrentWeek else { return [] }
        return store.activeTasks.filter { $0.dueDate == nil }
    }

    private var daysWithTasks: [Date] {
        (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }
            return datedTasks.contains { task in
                task.dueDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
            } ? day : nil
        }
    }

    private var weekRangeText: String {
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return weekStart.formatted(date: .abbreviated, time: .omitted)
        }
        return "\(weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(weekEnd.formatted(.dateTime.month(.abbreviated).day()))"
    }

    private var isCurrentWeek: Bool {
        calendar.isDate(weekStart, equalTo: .now, toGranularity: .weekOfYear)
    }

    private func moveWeek(by offset: Int) {
        weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart) ?? weekStart
    }

    @ViewBuilder
    private func dayTitle(_ day: Date) -> some View {
        if calendar.isDateInToday(day) {
            Text("date.today")
        } else if calendar.isDateInTomorrow(day) {
            Text("date.tomorrow")
        } else {
            Text(day, format: .dateTime.weekday(.wide))
        }
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

    private static var startOfCurrentWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start
            ?? Calendar.current.startOfDay(for: .now)
    }
}
