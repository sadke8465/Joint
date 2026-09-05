import SwiftUI

struct CalendarShellView: View {
    let completedTaskIDs: Set<String>
    let onToggle: (MockTask) -> Void

    @State private var selectedDay = 6

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let days: [Int?] = [nil, nil, 1, 2, 3, 4, 5] + Array(6...30)
    private let taskDays: Set<Int> = [6, 7, 12, 21]

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
        .accessibilityIdentifier("calendar-screen")
    }

    private var calendarCard: some View {
        VStack(spacing: AppSpacing.medium) {
            HStack {
                Button(action: {}) {
                    Image(systemName: "chevron.backward")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("calendar.previous_month"))

                Text("fixture.month")
                    .font(AppTypography.sectionTitle)
                    .frame(maxWidth: .infinity)

                Button(action: {}) {
                    Image(systemName: "chevron.forward")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("calendar.next_month"))
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.small) {
                ForEach(weekdayKeys, id: \.self) { key in
                    Text(LocalizedStringKey(key))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    calendarDay(day)
                }
            }

            Button("calendar.today") {
                selectedDay = 6
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
            Text(selectedDay == 6 ? "date.today" : "calendar.selected_day")
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
                    TaskCard(
                        task: task,
                        isCompleted: completedTaskIDs.contains(task.id),
                        onToggle: { onToggle(task) }
                    )
                }
            }
        }
    }

    private var selectedTasks: [MockTask] {
        switch selectedDay {
        case 6: [MockContent.package, MockContent.venue, MockContent.wine]
        case 7: [MockContent.flowers]
        default: []
        }
    }

    private var weekdayKeys: [String] {
        [
            "calendar.weekday.sun",
            "calendar.weekday.mon",
            "calendar.weekday.tue",
            "calendar.weekday.wed",
            "calendar.weekday.thu",
            "calendar.weekday.fri",
            "calendar.weekday.sat"
        ]
    }

    @ViewBuilder
    private func calendarDay(_ day: Int?) -> some View {
        if let day {
            Button {
                selectedDay = day
            } label: {
                VStack(spacing: 3) {
                    Text(day, format: .number)
                        .font(AppTypography.metadata.weight(day == 6 ? .bold : .regular))

                    Circle()
                        .fill(taskDays.contains(day) ? AppColors.accent : .clear)
                        .frame(width: 4, height: 4)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 42)
                .foregroundStyle(selectedDay == day ? .white : AppColors.primaryText)
                .background(
                    selectedDay == day ? AppColors.accent : .clear,
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(day)"))
            .accessibilityValue(taskDays.contains(day) ? Text("calendar.has_tasks") : Text("calendar.no_tasks_value"))
            .accessibilityAddTraits(selectedDay == day ? .isSelected : [])
            .accessibilityIdentifier("calendar-day-\(day)")
        } else {
            Color.clear
                .frame(minHeight: 42)
                .accessibilityHidden(true)
        }
    }
}
