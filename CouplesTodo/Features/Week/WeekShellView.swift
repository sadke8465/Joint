import SwiftUI

struct WeekShellView: View {
    let store: TaskStore
    let onEdit: (TaskItem) -> Void

    @State private var weekStart = Self.startOfCurrentWeek
    @State private var showsCompleted = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    private var calendar: Calendar { .current }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xLarge) {
                weekNavigator

                if !overdueTasks.isEmpty {
                    taskSection(
                        title: "filter.overdue",
                        icon: "exclamationmark.calendar",
                        tasks: overdueTasks,
                        tint: .red
                    )
                }

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
                    taskSection(
                        title: "list.someday",
                        icon: "calendar.badge.minus",
                        tasks: somedayTasks
                    )
                }

                completedSection
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .scrollIndicators(.hidden)
        .simultaneousGesture(horizontalSwipe)
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
                    .contentTransition(.numericText())
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
            task.dueDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        }

        return VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(alignment: .firstTextBaseline) {
                dayTitle(day)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(calendar.isDateInToday(day) ? AppColors.accent : AppColors.primaryText)

                Spacer()

                Text(day, format: .dateTime.month(.abbreviated).day())
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            ForEach(taskGroups(for: tasks)) { group in
                taskGroup(group)
            }
        }
        .padding(calendar.isDateInToday(day) ? AppSpacing.medium : 0)
        .background(
            calendar.isDateInToday(day) ? AppColors.accentSoft.opacity(0.55) : .clear,
            in: RoundedRectangle(cornerRadius: AppRadius.sheetSection, style: .continuous)
        )
    }

    private func taskGroup(_ group: WeekTaskGroup) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                Circle()
                    .fill(group.style.color)
                    .frame(width: 7, height: 7)
                    .padding(.top, 6)
                    .accessibilityHidden(true)

                Text(
                    TaskSentenceFormatter(locale: locale).sentence(
                        for: group.tasks,
                        assignee: group.style
                    )
                )
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.xSmall)

            ForEach(group.tasks) { task in
                taskCard(task)
            }
        }
    }

    private func taskSection(
        title: LocalizedStringKey,
        icon: String,
        tasks: [TaskItem],
        tint: Color = AppColors.primaryText
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Label(title, systemImage: icon)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(tint)

            ForEach(tasks) { task in
                taskCard(task)
            }
        }
    }

    private var completedSection: some View {
        DisclosureGroup(isExpanded: $showsCompleted) {
            if completedThisWeek.isEmpty {
                Text("week.done_empty")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.top, AppSpacing.small)
            } else {
                ForEach(completedThisWeek) { task in
                    taskCard(task)
                        .padding(.top, AppSpacing.small)
                }
            }
        } label: {
            Label {
                Text("week.done")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .font(AppTypography.sectionTitle)
            .foregroundStyle(AppColors.secondaryText)
        }
        .tint(AppColors.secondaryText)
        .appCard()
    }

    private var datedTasks: [TaskItem] {
        guard let weekEnd else { return [] }
        return store.activeTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= weekStart && dueDate < weekEnd
        }
    }

    private var overdueTasks: [TaskItem] {
        guard isCurrentWeek else { return [] }
        return store.activeTasks.filter { task in
            task.isOverdue() && (task.dueDate ?? .distantFuture) < weekStart
        }
    }

    private var somedayTasks: [TaskItem] {
        guard isCurrentWeek else { return [] }
        return store.activeTasks.filter { $0.dueDate == nil }
    }

    private var completedThisWeek: [TaskItem] {
        guard let weekEnd else { return [] }
        return store.completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= weekStart && completedAt < weekEnd
        }
    }

    private var weekEnd: Date? {
        calendar.date(byAdding: .day, value: 7, to: weekStart)
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

    private var horizontalSwipe: some Gesture {
        DragGesture(minimumDistance: 36)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.25 else {
                    return
                }
                moveWeek(by: value.translation.width < 0 ? 1 : -1)
            }
    }

    private func moveWeek(by offset: Int) {
        withAnimation(AppMotion.content(reduceMotion: reduceMotion)) {
            weekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: weekStart) ?? weekStart
            showsCompleted = false
        }
    }

    private func taskGroups(for tasks: [TaskItem]) -> [WeekTaskGroup] {
        MemberStyle.allCases.compactMap { style in
            let matchingTasks = tasks.filter {
                MemberStyle(task: $0, identity: store.identity) == style
            }
            return matchingTasks.isEmpty ? nil : WeekTaskGroup(style: style, tasks: matchingTasks)
        }
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
            onDelete: { store.moveToTrash(task) },
            onReschedule: { store.reschedule(task, to: $0) }
        )
    }

    private static var startOfCurrentWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start
            ?? Calendar.current.startOfDay(for: .now)
    }
}

private struct WeekTaskGroup: Identifiable {
    let style: MemberStyle
    let tasks: [TaskItem]

    var id: String { style.id }
}
