import SwiftUI

#Preview("Task Item", traits: .sizeThatFitsLayout) {
    TaskItemPreview()
        .frame(width: 346)
        .padding()
}

#Preview("Task List · Figma Frame", traits: .sizeThatFitsLayout) {
    TaskListPreview()
        .frame(width: 346)
        .padding()
}

#Preview("Responsive · Dynamic Text", traits: .sizeThatFitsLayout) {
    LongTaskItemPreview()
        .frame(width: 280)
        .padding()
        .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Interactive Demo") {
    NavigationStack {
        TaskItemDemo()
    }
}

private struct TaskItemPreview: View {
    @State private var item = TaskItemSamples.figmaFrame[0]

    var body: some View {
        TaskItemView(item: item) {
            item.isCompleted.toggle()
        }
    }
}

private struct TaskListPreview: View {
    @State private var items = TaskItemSamples.figmaFrame

    var body: some View {
        TaskListView(items: items) { id in
            guard let index = items.firstIndex(where: { $0.id == id }) else { return }
            items[index].isCompleted.toggle()
        }
    }
}

private struct LongTaskItemPreview: View {
    @State private var item = TaskItemSamples.longContent

    var body: some View {
        TaskItemView(item: item) {
            item.isCompleted.toggle()
        }
    }
}
