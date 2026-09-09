import SwiftUI

struct CalendarShellView: View {
    let store: TaskStore
    let onEdit: (TaskItem) -> Void

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var expandedTaskID: UUID?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                calendarCard
                assigneeLegend
                agenda
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.small)
            .padding(.bottom, AppSpacing.xxLarge)
        }
        .background(AppColors.canvas)
        .scrollIndicators(.hidden)
        .simultaneousGesture(horizontalSwipe)
        .accessibilityIdentifier("calendar-screen")
    }

    private var calendarCard: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack {
                Button {
                    moveMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.backward")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("calendar.previous_month"))

                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(AppTypography.sectionTitle)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())

                Button {
                    moveMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.forward")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("calendar.next_month"))
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    calendarDay(date)
                }
            }

            Button("calendar.today") {
                withAnimation(AppMotion.content(reduceMotion: reduceMotion)) {
                    displayedMonth = calendar.dateInterval(of: .month, for: .now)?.start ?? .now
                    selectedDate = calendar.startOfDay(for: .now)
                }
            }
            .buttonStyle(AppPillButtonStyle(isSelected: false, tint: AppColors.accent))
        }
        .foregroundStyle(AppColors.primaryText)
        .padding(AppSpacing.large)
        .background(
            AppColors.surface,
            in: RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.hero, style: .continuous)
                .strokeBorder(AppColors.border.opacity(0.76), lineWidth: 1)
        }
    }

    private var agenda: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Group {
                if calendar.isDateInToday(selectedDate) {
                    Text("date.today")
                } else {
                    Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                }
            }
            .font(AppTypography.dateHero)
            .foregroundStyle(AppColors.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)

            if selectedTasks.isEmpty {
                Label("calendar.no_tasks_description", systemImage: "calendar.badge.checkmark")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
                    .padding(.horizontal, AppSpacing.large)
                    .background(
                        AppColors.groupedBackground.opacity(0.68),
                        in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                    )
            } else {
                ForEach(selectedTasks) { task in
                    taskCard(task)
                }
            }
        }
    }

    private var assigneeLegend: some View {
        HStack(spacing: AppSpacing.large) {
            ForEach(MemberStyle.allCases) { style in
                HStack(spacing: AppSpacing.xSmall) {
                    Circle()
                        .fill(style.color)
                        .frame(width: 7, height: 7)

                    Text(style.labelKey)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("calendar-legend")
    }

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar
    }

    private var monthDays: [Date?] {
        guard let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: displayedMonth).weekday else {
            return []
        }

        let leadingCount = (firstWeekday - calendar.firstWeekday + 7) % 7
        let leading = Array<Date?>(repeating: nil, count: leadingCount)
        let days = dayRange.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: displayedMonth)
        }
        return leading + days.map(Optional.some)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var selectedTasks: [TaskItem] {
        store.activeTasks.filter { task in
            task.dueDate.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false
        }
    }

    private func memberStyles(on date: Date) -> [MemberStyle] {
        let styles = store.activeTasks.compactMap { task -> MemberStyle? in
            guard task.dueDate.map({ calendar.isDate($0, inSameDayAs: date) }) == true else {
                return nil
            }
            return MemberStyle(task: task, identity: store.identity)
        }
        return MemberStyle.allCases.filter { styles.contains($0) }
    }

    private func moveMonth(by offset: Int) {
        guard let month = calendar.date(byAdding: .month, value: offset, to: displayedMonth) else {
            return
        }
        withAnimation(AppMotion.content(reduceMotion: reduceMotion)) {
            displayedMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
            selectedDate = displayedMonth
        }
    }

    private var horizontalSwipe: some Gesture {
        DragGesture(minimumDistance: 36)
            .onEnded { value in
                guard abs(value.translation.width) > abs(value.translation.height) * 1.25 else {
                    return
                }
                moveMonth(by: value.translation.width < 0 ? 1 : -1)
            }
    }

    @ViewBuilder
    private func calendarDay(_ date: Date?) -> some View {
        if let date {
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let styles = memberStyles(on: date)
            Button {
                selectedDate = date
                expandedTaskID = nil
            } label: {
                VStack(spacing: 3) {
                    Text(date, format: .dateTime.day())
                        .font(AppTypography.metadata.weight(calendar.isDateInToday(date) ? .bold : .regular))

                    HStack(spacing: 2) {
                        ForEach(styles) { style in
                            Circle()
                                .fill(isSelected ? Color.white.opacity(0.82) : style.color)
                                .frame(width: 5, height: 5)
                        }
                    }
                    .frame(height: 5)
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .foregroundStyle(isSelected ? .white : AppColors.primaryText)
                .background(
                    isSelected ? AppColors.accent : .clear,
                    in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(date, format: .dateTime.month(.wide).day()))
            .accessibilityValue(styles.isEmpty ? Text("calendar.no_tasks_value") : Text("calendar.has_tasks"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityIdentifier("calendar-day-\(calendar.component(.day, from: date))")
        } else {
            Color.clear
                .frame(minHeight: 42)
                .accessibilityHidden(true)
        }
    }

    private func taskCard(_ task: TaskItem) -> some View {
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
            onEdit: { onEdit(task) },
            onDelete: { store.moveToTrash(task) },
            onReschedule: { store.reschedule(task, to: $0) }
        )
    }
}

#Preview("Calendar — Populated") {
    let environment = AppEnvironment.preview(populated: true)
    NavigationStack {
        CalendarShellView(store: environment.taskStore, onEdit: { _ in })
    }
    .modelContainer(environment.modelContainer)
}
