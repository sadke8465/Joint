import SwiftUI

struct EmojiListsView: View {
    let store: TaskStore

    var body: some View {
        List {
            if store.emojiLists.isEmpty {
                ContentUnavailableView(
                    "lists.empty",
                    systemImage: "face.smiling",
                    description: Text("lists.empty_description")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(store.emojiLists) { list in
                    HStack(spacing: AppSpacing.medium) {
                        Text(list.emoji)
                            .font(.title2)

                        Text(list.title)
                            .font(AppTypography.body)

                        Spacer()

                        Button("task.delete", systemImage: "trash", role: .destructive) {
                            store.removeEmojiList(list)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            Section {
                Text("lists.create_hint")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
        .navigationTitle(Text("lists.title"))
    }
}
