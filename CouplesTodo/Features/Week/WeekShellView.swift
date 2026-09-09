import SwiftUI

struct WeekShellView: View {
    let store: TaskStore
    let onOpenDay: (Date) -> Void

    @State private var weekStart = Calendar.current.startOfDay(for: .now)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.large) {
                weekHeader

                if daysWithTasks.isEmpty && completedThisWeek.isEmpty {
                    AppEmptyState(
                        title: "week.no_tasks",
                        systemImage: "calendar.badge.checkmark",
                        description: "week.no_tasks_description",
                        tint: AppColors.success,
                        iconForeground: AppColors.primaryText
                    )
                } else {
                    ForEach(daysWithTasks, id: \.self) { day in
                        dayCard(day)
                    }

                    if !completedThisWeek.isEmpty {
                        completedSection
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .background(AppColors.canvas)
        .scrollIndicators(.hidden)
        .simultaneousGesture(horizontalSwipe)
        .task(id: locale.identifier) {
            weekStart = WeekCalendar.startOfWeek(containing: weekStart, locale: locale)
        }
        .accessibilityIdentifier("week-screen")
    }

    private var weekHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("main.mode.week")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.primaryText)

                Text(weekRangeText)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 0)

            Menu {
                Button("week.previous", systemImage: "chevron.backward") {
                    moveWeek(by: -1)
                }
                Button("week.current", systemImage: "calendar") {
                    moveToCurrentWeek()
                }
                Button("week.next", systemImage: "chevron.forward") {
                    moveWeek(by: 1)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(AppColors.secondaryText)
            .accessibilityLabel(Text("main.mode.week"))
            .accessibilityIdentifier("week-range-menu")
        }
    }

    private func dayCard(_ day: Date) -> some View {
        let tasks = tasks(on: day)
        let isToday = calendar.isDateInToday(day)
        let isOverdue = calendar.startOfDay(for: day) < calendar.startOfDay(for: .now)

        return Button {
            onOpenDay(day)
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.small) {
                    Circle()
                        .fill(isOverdue ? AppColors.danger : isToday ? AppColors.primaryText : AppColors.violet)
                        .frame(width: 7, height: 7)

                    dayTitle(day)
                        .font(AppTypography.metadata.weight(.semibold))
                        .foregroundStyle(
                            isOverdue ? AppColors.danger : isToday ? AppColors.primaryText : AppColors.secondaryText
                        )

                    Spacer(minLength: 0)

                    Text(day, format: .dateTime.month(.abbreviated).day())
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                ForEach(taskGroups(for: tasks)) { group in
                    HStack(alignment: .top, spacing: AppSpacing.small) {
                        Circle()
                            .fill(group.style.color)
                            .frame(width: 7, height: 7)
                            .padding(.top, 6)

                        Text(
                            TaskSentenceFormatter(locale: locale).sentence(
                                for: group.tasks,
                                assignee: group.style
                            )
                        )
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard(isOverdue ? .tinted(AppColors.danger) : .plain, padding: AppSpacing.large)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("calendar.selected_day"))
        .accessibilityIdentifier("week-day-\(dayIdentifier(day))")
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                Rectangle().fill(AppColors.border).frame(height: 1)
                Text("week.done")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                Rectangle().fill(AppColors.border).frame(height: 1)
            }

            VStack(spacing: AppSpacing.xSmall) {
                ForEach(completedThisWeek) { task in
                    HStack(spacing: AppSpacing.medium) {
                        TaskCheckbox(
                            isCompleted: true,
                            action: { store.toggleCompletion(for: task) }
                        )

                        Text(task.title)
                            .font(AppTypography.metadata)
                            .foregroundStyle(AppColors.tertiaryText)
                            .strikethrough()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .appCard(.soft, padding: AppSpacing.medium)
        }
    }

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar
    }

    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    private var weekTasks: [TaskItem] {
        store.activeTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= weekStart && dueDate < weekEnd
        }
    }

    private var daysWithTasks: [Date] {
        (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }
            return tasks(on: day).isEmpty ? nil : day
        }
    }

    private var completedThisWeek: [TaskItem] {
        store.completedTasks.filter { task in
            guard let completedAt = task.completedAt else { return false }
            return completedAt >= weekStart && completedAt < weekEnd
        }
    }

    private func tasks(on day: Date) -> [TaskItem] {
        weekTasks.filter { task in
            task.dueDate.map { calendar.isDate($0, inSameDayAs: day) } ?? false
        }
    }

    private func taskGroups(for tasks: [TaskItem]) -> [WeekTaskGroup] {
        MemberStyle.allCases.compactMap { style in
            let matching = tasks.filter {
                MemberStyle(task: $0, identity: store.identity) == style
            }
            return matching.isEmpty ? nil : WeekTaskGroup(style: style, tasks: matching)
        }
    }

    private var weekRangeText: String {
        let end = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(weekStart.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
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
        }
    }

    private func moveToCurrentWeek() {
        withAnimation(AppMotion.content(reduceMotion: reduceMotion)) {
            weekStart = WeekCalendar.startOfWeek(containing: .now, locale: locale)
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

    private func dayIdentifier(_ day: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

}

struct WeekCalendar {
    static func startOfWeek(
        containing date: Date,
        locale: Locale,
        calendar baseCalendar: Calendar = .current
    ) -> Date {
        var calendar = baseCalendar
        calendar.locale = locale
        return calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
    }
}

private struct WeekTaskGroup: Identifiable {
    let style: MemberStyle
    let tasks: [TaskItem]

    var id: String { style.id }
}

struct DayTasksSheet: View {
    let store: TaskStore
    let date: Date

    @Environment(\.dismiss) private var dismiss
    @State private var expandedTaskID: UUID?
    @State private var editingTask: EditableTask?

    private var tasks: [TaskItem] {
        let calendar = Calendar.current
        return store.tasks
            .filter { task in
                guard !task.isDeleted, let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: date)
            }
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted
                }
                return (lhs.dueDate ?? .distantFuture) < (rhs.dueDate ?? .distantFuture)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    if tasks.isEmpty {
                        AppEmptyState(
                            title: "calendar.no_tasks",
                            systemImage: "calendar.badge.checkmark",
                            description: "calendar.no_tasks_description"
                        )
                    } else {
                        ForEach(tasks) { task in
                            TaskCard(
                                task: task,
                                identity: store.identity,
                                emojiList: store.emojiList(id: task.listID),
                                emojiLists: store.emojiLists,
                                onToggle: { store.toggleCompletion(for: task) },
                                context: .agenda,
                                isExpanded: Binding(
                                    get: { expandedTaskID == task.id },
                                    set: { expandedTaskID = $0 ? task.id : nil }
                                ),
                                onUpdate: { draft in
                                    _ = store.update(id: task.id, with: draft)
                                },
                                onEdit: { editingTask = EditableTask(id: task.id) },
                                onDelete: { store.moveToTrash(task) },
                                onReschedule: { store.reschedule(task, to: $0) }
                            )
                        }
                    }
                }
                .padding(AppSpacing.screenMargin)
            }
            .background(AppColors.canvas)
            .navigationTitle(Text(date, format: .dateTime.weekday(.wide).month(.wide).day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("composer.done") { dismiss() }
                }
            }
        }
        .sheet(item: $editingTask) { selection in
            TaskComposerView(store: store, taskID: selection.id)
                .presentationDetents([.large])
        }
        .accessibilityIdentifier("day-details-sheet")
    }
}

private struct EditableTask: Identifiable {
    let id: UUID
}

#Preview("Week — Populated") {
    let environment = AppEnvironment.preview(populated: true)
    WeekShellView(store: environment.taskStore, onOpenDay: { _ in })
        .modelContainer(environment.modelContainer)
}
