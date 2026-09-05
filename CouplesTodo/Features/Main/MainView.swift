import SwiftUI

struct MainView: View {
    @State private var router = AppRouter()
    @State private var selectedMode = MainMode.defaultMode
    @State private var completedTaskIDs = Set(MockContent.completedTasks.map(\.id))

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var router = router

        NavigationStack {
            VStack(spacing: 0) {
                MainHeader(
                    selectedMode: $selectedMode,
                    openTaskCount: openTaskCount
                )
                .padding(.horizontal, AppSpacing.large)
                .padding(.top, AppSpacing.small)
                .padding(.bottom, AppSpacing.large)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
            .background(AppColors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                addTaskButton
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $router.presentedSheet) { destination in
            sheet(for: destination)
        }
        .environment(router)
        .accessibilityIdentifier("main-shell")
    }

    @ViewBuilder
    private var content: some View {
        switch selectedMode {
        case .week:
            WeekShellView(
                completedTaskIDs: completedTaskIDs,
                onToggle: toggleCompletion
            )
        case .list:
            ListShellView(
                completedTaskIDs: completedTaskIDs,
                onToggle: toggleCompletion
            )
        case .calendar:
            CalendarShellView(
                completedTaskIDs: completedTaskIDs,
                onToggle: toggleCompletion
            )
        }
    }

    private var addTaskButton: some View {
        Button {
            router.presentedSheet = .taskComposer
        } label: {
            Label("task.add", systemImage: "plus")
                .font(AppTypography.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .foregroundStyle(.white)
                .background(AppColors.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.large)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.small)
        .background(AppColors.background.opacity(0.96))
        .accessibilityIdentifier("add-task")
    }

    @ViewBuilder
    private func sheet(for destination: SheetDestination) -> some View {
        switch destination {
        case .taskComposer:
            TaskComposerView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        case .settings:
            SettingsShellView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var openTaskCount: Int {
        MockContent.activeTasks.filter { !completedTaskIDs.contains($0.id) }.count
    }

    private func toggleCompletion(_ task: MockTask) {
        withAnimation(AppMotion.content(reduceMotion: reduceMotion)) {
            if completedTaskIDs.contains(task.id) {
                completedTaskIDs.remove(task.id)
            } else {
                completedTaskIDs.insert(task.id)
            }
        }
    }
}

#Preview("English") {
    MainView()
        .environment(\.locale, Locale(identifier: "en_US"))
        .environment(\.layoutDirection, .leftToRight)
}

#Preview("Hebrew RTL") {
    MainView()
        .environment(\.locale, Locale(identifier: "he_IL"))
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Accessibility text") {
    MainView()
        .environment(\.dynamicTypeSize, .accessibility3)
}
