import SwiftUI

struct TrashView: View {
    let store: TaskStore

    @State private var pendingPermanentDelete: TaskItem?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                if store.trashedTasks.isEmpty {
                    ContentUnavailableView(
                        "trash.empty",
                        systemImage: "trash",
                        description: Text("trash.empty_description")
                    )
                    .appCard()
                } else {
                    ForEach(store.trashedTasks) { task in
                        trashRow(task)
                    }
                }
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.background)
        .navigationTitle(Text("trash.title"))
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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(task.title)
                .font(AppTypography.taskTitle)
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let deletedAt = task.deletedAt {
                Label {
                    Text(deletedAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                } icon: {
                    Image(systemName: "clock")
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)
            }

            HStack(spacing: AppSpacing.small) {
                Button("trash.restore", systemImage: "arrow.uturn.backward") {
                    store.restoreFromTrash(task)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.accent)

                Button("trash.delete_forever", systemImage: "trash", role: .destructive) {
                    pendingPermanentDelete = task
                }
                .buttonStyle(.bordered)
            }
            .font(AppTypography.caption)
        }
        .appCard()
    }
}
