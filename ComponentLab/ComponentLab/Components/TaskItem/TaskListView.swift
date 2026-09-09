import SwiftUI

struct TaskListView: View {
    let items: [TaskItemContent]
    let onToggleCompletion: (TaskItemContent.ID) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(items) { item in
                TaskItemView(item: item) {
                    onToggleCompletion(item.id)
                }
            }
        }
    }
}
