import SwiftUI

struct ArchiveView: View {
    let store: TaskStore

    @State private var searchText = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.medium) {
                if filteredTasks.isEmpty {
                    ContentUnavailableView(
                        "archive.empty",
                        systemImage: "archivebox",
                        description: Text("archive.empty_description")
                    )
                    .appCard()
                } else {
                    ForEach(filteredTasks) { task in
                        TaskCard(
                            task: task,
                            identity: store.identity,
                            emojiList: store.emojiList(id: task.listID),
                            onToggle: { store.toggleCompletion(for: task) },
                            onEdit: nil,
                            onDelete: { store.moveToTrash(task) }
                        )
                    }
                }
            }
            .padding(AppSpacing.large)
        }
        .background(AppColors.background)
        .navigationTitle(Text("archive.title"))
        .searchable(text: $searchText, prompt: Text("list.search"))
    }

    private var filteredTasks: [TaskItem] {
        store.completedTasks.filter { $0.matches(searchText) }
    }
}
