import SwiftUI

struct WeekShellView: View {
    let completedTaskIDs: Set<String>
    let onToggle: (MockTask) -> Void

    @State private var showsCompleted = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.xLarge) {
                weekNavigator

                ForEach(MockContent.weekDays) { day in
                    daySection(day)
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
            Button(action: {}) {
                Image(systemName: "chevron.backward")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("week.previous"))

            VStack(spacing: 2) {
                Text("fixture.week_range")
                    .font(AppTypography.sectionTitle)
                Text("week.current")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.accent)
            }
            .frame(maxWidth: .infinity)

            Button(action: {}) {
                Image(systemName: "chevron.forward")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("week.next"))
        }
        .foregroundStyle(AppColors.primaryText)
        .accessibilityElement(children: .contain)
    }

    private func daySection(_ day: MockDay) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey(day.titleKey))
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(day.id == "today" ? AppColors.accent : AppColors.primaryText)

                Spacer()

                Text(LocalizedStringKey(day.dateKey))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }

            ForEach(day.tasks) { task in
                TaskCard(
                    task: task,
                    isCompleted: completedTaskIDs.contains(task.id),
                    onToggle: { onToggle(task) }
                )
            }
        }
        .padding(day.id == "today" ? AppSpacing.medium : 0)
        .background(
            day.id == "today" ? AppColors.accentSoft.opacity(0.55) : .clear,
            in: RoundedRectangle(cornerRadius: AppRadius.sheetSection, style: .continuous)
        )
    }

    private var completedSection: some View {
        DisclosureGroup(isExpanded: $showsCompleted) {
            ForEach(MockContent.completedTasks) { task in
                TaskCard(task: task, isCompleted: true) {
                    onToggle(task)
                }
                .padding(.top, AppSpacing.small)
            }
        } label: {
            Label("week.done", systemImage: "checkmark.circle.fill")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.secondaryText)
        }
        .tint(AppColors.secondaryText)
        .appCard()
    }
}
