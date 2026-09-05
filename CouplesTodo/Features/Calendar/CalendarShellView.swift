import SwiftUI

struct CalendarShellView: View {
    let store: TaskStore
    let onEdit: (TaskItem) -> Void

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.locale) private var locale

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xLarge) {
                calendarCard
                agenda
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.bottom, AppSpacing.xxLarge)
        }
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
            .font(AppTypography.caption)
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
        }
        .foregroundStyle(AppColors.primaryText)
        .appCard()
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
            .font(AppTypography.sectionTitle)
            .foregroundStyle(AppColors.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)

            if selectedTasks.isEmpty {
                ContentUnavailableView(
                    "calendar.no_tasks",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("calendar.no_tasks_description")
                )
                .frame(maxWidth: .infinity)
                .appCard()
            } else {
                ForEach(selectedTasks) { task in
                    taskCard(task)
                }
            }
        }
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

    private func hasTasks(on date: Date) -> Bool {
        store.activeTasks.contains { task in
            task.dueDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        }
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
            Button {
                selectedDate = date
            } label: {
                VStack(spacing: 3) {
                    Text(date, format: .dateTime.day())
                        .font(AppTypography.metadata.weight(calendar.isDateInToday(date) ? .bold : .regular))

                    Circle()
                        .fill(hasTasks(on: date) ? AppColors.accent : .clear)
                        .frame(width: 4, height: 4)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .foregroundStyle(isSelected ? .white : AppColors.primaryText)
                .background(
                    isSelected ? AppColors.accent : .clear,
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(date, format: .dateTime.month(.wide).day()))
            .accessibilityValue(hasTasks(on: date) ? Text("calendar.has_tasks") : Text("calendar.no_tasks_value"))
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
            onToggle: { store.toggleCompletion(for: task) },
            onEdit: { onEdit(task) },
            onDelete: { store.moveToTrash(task) },
            onReschedule: { store.reschedule(task, to: $0) }
        )
    }
}
