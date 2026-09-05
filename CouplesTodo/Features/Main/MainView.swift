import SwiftUI
import SwiftData

struct MainView: View {
    let store: TaskStore

    @State private var router = AppRouter()
    @State private var selectedMode = MainMode.defaultMode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var router = router

        NavigationStack {
            VStack(spacing: 0) {
                MainHeader(
                    selectedMode: $selectedMode,
                    openTaskCount: store.activeTasks.count
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
            .overlay(alignment: .bottom) {
                undoBanner
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.bottom, 78)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $router.presentedSheet) { destination in
            sheet(for: destination)
        }
        .environment(router)
        .task {
            store.loadIfNeeded()
        }
        .alert("error.title", isPresented: errorIsPresented) {
            Button("action.ok") {
                store.errorMessage = nil
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .accessibilityIdentifier("main-shell")
    }

    @ViewBuilder
    private var content: some View {
        switch selectedMode {
        case .week:
            WeekShellView(store: store, onEdit: editTask)
        case .list:
            ListShellView(store: store, onEdit: editTask)
        case .calendar:
            CalendarShellView(store: store, onEdit: editTask)
        }
    }

    private var addTaskButton: some View {
        Button {
            router.presentedSheet = .taskComposer(taskID: nil)
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
    private var undoBanner: some View {
        if store.recentlyDeletedTaskID != nil {
            HStack(spacing: AppSpacing.medium) {
                Text("trash.moved_message")
                    .font(AppTypography.metadata)
                    .foregroundStyle(.white)

                Spacer(minLength: 0)

                Button("action.undo") {
                    withAnimation(AppMotion.content(reduceMotion: reduceMotion)) {
                        store.undoLastDelete()
                    }
                }
                .font(AppTypography.metadata.weight(.bold))
                .foregroundStyle(AppColors.accentSoft)
            }
            .padding(.horizontal, AppSpacing.large)
            .frame(minHeight: 48)
            .background(AppColors.primaryText, in: Capsule())
            .shadow(color: Color.black.opacity(0.16), radius: 10, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func sheet(for destination: SheetDestination) -> some View {
        switch destination {
        case .taskComposer(let taskID):
            TaskComposerView(store: store, taskID: taskID)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        case .settings:
            SettingsShellView(store: store)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )
    }

    private func editTask(_ task: TaskItem) {
        router.presentedSheet = .taskComposer(taskID: task.id)
    }
}

#Preview("English") {
    let environment = AppEnvironment.preview()
    MainView(store: environment.taskStore)
        .modelContainer(environment.modelContainer)
        .environment(\.locale, Locale(identifier: "en_US"))
        .environment(\.layoutDirection, .leftToRight)
}

#Preview("Hebrew RTL") {
    let environment = AppEnvironment.preview()
    MainView(store: environment.taskStore)
        .modelContainer(environment.modelContainer)
        .environment(\.locale, Locale(identifier: "he_IL"))
        .environment(\.layoutDirection, .rightToLeft)
}
