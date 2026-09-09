import SwiftUI

struct ArchiveView: View {
    let store: TaskStore

    @State private var searchText = ""

    var body: some View {
        List {
            if filteredTasks.isEmpty {
                Label("archive.empty_description", systemImage: "archivebox")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                    .listRowBackground(AppColors.canvas)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(filteredTasks) { task in
                    archiveRow(task)
                }
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
        .scrollContentBackground(.hidden)
        .background(AppColors.canvas)
        .navigationTitle(Text("archive.title"))
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("list.search")
        )
        .toolbarBackground(AppColors.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .accessibilityIdentifier("archive-screen")
    }

    private var filteredTasks: [TaskItem] {
        store.completedTasks.filter { $0.matches(searchText) }
    }

    private func archiveRow(_ task: TaskItem) -> some View {
        TaskCard(
            task: task,
            identity: store.identity,
            emojiList: store.emojiList(id: task.listID),
            onToggle: { store.toggleCompletion(for: task) },
            context: .archive,
            onEdit: nil,
            onDelete: { store.moveToTrash(task) }
        )
        .listRowInsets(
            EdgeInsets(
                top: AppSpacing.small,
                leading: AppSpacing.screenMargin,
                bottom: AppSpacing.small,
                trailing: AppSpacing.screenMargin
            )
        )
        .listRowBackground(AppColors.surface)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                store.toggleCompletion(for: task)
            } label: {
                Label("task.mark_incomplete", systemImage: "arrow.uturn.backward")
            }
            .tint(AppColors.success)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.moveToTrash(task)
            } label: {
                Label("task.delete", systemImage: "trash")
            }
        }
    }
}

#Preview("Archive — Populated") {
    let environment = AppEnvironment.preview(populated: true)
    NavigationStack {
        ArchiveView(store: environment.taskStore)
    }
    .modelContainer(environment.modelContainer)
}
