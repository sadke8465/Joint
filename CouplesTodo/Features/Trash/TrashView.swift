import SwiftUI

struct TrashView: View {
    let store: TaskStore

    @State private var pendingPermanentDelete: TaskItem?

    var body: some View {
        List {
            Section {
                Text("trash.empty_description")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.vertical, AppSpacing.small)
                    .listRowBackground(AppColors.groupedBackground.opacity(0.64))
            }

            if store.trashedTasks.isEmpty {
                Label("trash.empty", systemImage: "trash")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                    .listRowBackground(AppColors.canvas)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(store.trashedTasks) { task in
                    trashRow(task)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.canvas)
        .navigationTitle(Text("trash.title"))
        .toolbarBackground(AppColors.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("trash-screen")
        .alert(
            "trash.delete_forever_title",
            isPresented: deleteConfirmationIsPresented,
            presenting: pendingPermanentDelete
        ) { task in
            Button("action.cancel", role: .cancel) {}
            Button("trash.delete_forever", role: .destructive) {
                store.deletePermanently(task)
            }
        } message: { task in
            Text("\(String(localized: "trash.delete_forever_message")) \(task.title)")
        }
    }

    private var deleteConfirmationIsPresented: Binding<Bool> {
        Binding(
            get: { pendingPermanentDelete != nil },
            set: { if !$0 { pendingPermanentDelete = nil } }
        )
    }

    private func trashRow(_ task: TaskItem) -> some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(task.title)
                    .font(AppTypography.taskTitle)
                    .foregroundStyle(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if let deletedAt = task.deletedAt {
                    Label {
                        Text(
                            deletedAt,
                            format: .dateTime.month(.abbreviated).day().hour().minute()
                        )
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("trash.restore") {
                store.restoreFromTrash(task)
            }
            .font(AppTypography.caption)
            .buttonStyle(.bordered)
            .tint(AppColors.accent)
            .frame(minHeight: 44)

            Menu {
                Button("trash.delete_forever", systemImage: "trash", role: .destructive) {
                    pendingPermanentDelete = task
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
            }
            .foregroundStyle(AppColors.secondaryText)
            .accessibilityLabel(Text("task.actions"))
        }
        .padding(.vertical, AppSpacing.xSmall)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                store.restoreFromTrash(task)
            } label: {
                Label("trash.restore", systemImage: "arrow.uturn.backward")
            }
            .tint(AppColors.success)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingPermanentDelete = task
            } label: {
                Label("trash.delete_forever", systemImage: "trash")
            }
        }
    }
}

#Preview("Trash — Populated") {
    let environment = AppEnvironment.preview(populated: true)
    NavigationStack {
        TrashView(store: environment.taskStore)
    }
    .modelContainer(environment.modelContainer)
}
