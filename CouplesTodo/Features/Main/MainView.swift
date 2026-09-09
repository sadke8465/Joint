import SwiftData
import SwiftUI

struct MainView: View {
    let store: TaskStore

    @State private var router = AppRouter()
    @State private var listState = ListViewState()

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        @Bindable var router = router

        VStack(spacing: 0) {
            MainHeader(openTaskCount: store.activeTasks.count)

            if router.selectedMode == .list {
                ListFilterToolbar(
                    store: store,
                    state: listState,
                    onAdd: { defaults in
                        router.presentedSheet = .quickAdd(defaults)
                    }
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
                .overlay(AppColors.border.opacity(0.65))

            TabView(selection: $router.selectedMode) {
                ListShellView(store: store, state: listState, onEdit: editTask)
                    .tag(MainMode.list)

                WeekShellView(
                    store: store,
                    onOpenDay: { date in
                        router.presentedSheet = .dayDetails(date)
                    }
                )
                .tag(MainMode.week)

                CalendarShellView(store: store, onEdit: editTask)
                    .tag(MainMode.calendar)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(
                reduceMotion ? nil : AppMotion.selection(reduceMotion: false),
                value: router.selectedMode
            )
        }
        .background(AppColors.canvas.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            undoBanner
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.bottom, AppSpacing.large)
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
        .preferredColorScheme(.light)
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
                .foregroundStyle(Color.white)
            }
            .padding(.horizontal, AppSpacing.large)
            .frame(minHeight: 52)
            .background(AppColors.primaryText, in: Capsule())
            .shadow(color: Color.black.opacity(0.16), radius: 14, y: 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func sheet(for destination: SheetDestination) -> some View {
        switch destination {
        case .quickAdd(let defaults):
            QuickAddTaskView(store: store, defaults: defaults)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.sheet)
        case .taskEditor(let taskID):
            TaskComposerView(store: store, taskID: taskID)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.sheet)
        case .dayDetails(let date):
            DayTasksSheet(store: store, date: date)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.sheet)
        case .more:
            SettingsShellView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(AppRadius.sheet)
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )
    }

    private func editTask(_ task: TaskItem) {
        router.presentedSheet = .taskEditor(taskID: task.id)
    }
}

#Preview("English") {
    let environment = AppEnvironment.preview(populated: true)
    MainView(store: environment.taskStore)
        .modelContainer(environment.modelContainer)
        .environment(\.locale, Locale(identifier: "en_US"))
        .environment(\.layoutDirection, .leftToRight)
}

#Preview("Hebrew RTL") {
    let environment = AppEnvironment.preview(populated: true)
    MainView(store: environment.taskStore)
        .modelContainer(environment.modelContainer)
        .environment(\.locale, Locale(identifier: "he_IL"))
        .environment(\.layoutDirection, .rightToLeft)
}
