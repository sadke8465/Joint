import SwiftUI

struct TaskItemDemo: View {
    @State private var items = TaskItemSamples.figmaFrame

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                componentSection("Task Item") {
                    TaskItemView(item: items[0]) {
                        toggleCompletion(for: items[0].id)
                    }
                }

                componentSection("Task Item in a List") {
                    TaskListView(items: items, onToggleCompletion: toggleCompletion)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Item")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func componentSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private func toggleCompletion(for id: TaskItemContent.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
    }
}

enum TaskItemSamples {
    static let figmaFrame: [TaskItemContent] = [
        TaskItemContent(
            id: "today-joint",
            title: "Do the dishes",
            dueText: "Today",
            assignee: "Joint",
            assigneeIndicators: [.pink, .cyan],
            isCompleted: false
        ),
        TaskItemContent(
            id: "tomorrow-noam",
            title: "Do the dishes",
            dueText: "Tomorrow",
            assignee: "Noam",
            assigneeIndicators: [.cyan],
            isCompleted: false
        ),
        TaskItemContent(
            id: "three-days-omer",
            title: "Do the dishes",
            dueText: "In 3 Days",
            assignee: "Omer",
            assigneeIndicators: [.pink],
            isCompleted: false
        ),
        TaskItemContent(
            id: "dated-omer",
            title: "Do the dishes",
            dueText: "12.03.2026",
            assignee: "Omer",
            assigneeIndicators: [.pink],
            isCompleted: false
        ),
        TaskItemContent(
            id: "completed-omer",
            title: "Do the dishes",
            dueText: "12.03.2026",
            assignee: "Omer",
            assigneeIndicators: [.pink],
            isCompleted: true
        )
    ]

    static let longContent = TaskItemContent(
        id: "long-content",
        title: "Plan the shared grocery list for the weekend dinner with friends",
        dueText: "Next Saturday after the morning market",
        assignee: "Noam and Omer",
        assigneeIndicators: [.pink, .cyan],
        isCompleted: false
    )
}
