import SwiftUI

struct EmojiListsView: View {
    let store: TaskStore

    @State private var showsListCreator = false
    @State private var newListEmoji = ""
    @State private var newListTitle = ""

    var body: some View {
        List {
            if store.emojiLists.isEmpty {
                Label("lists.empty_description", systemImage: "face.smiling")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                    .listRowBackground(AppColors.canvas)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(store.emojiLists) { list in
                    listRow(list)
                }

                Text("lists.create_hint")
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.secondaryText)
                    .listRowBackground(AppColors.canvas)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppColors.canvas)
        .navigationTitle(Text("lists.title"))
        .toolbarBackground(AppColors.canvas, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showsListCreator = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("composer.new_list"))
                .accessibilityIdentifier("lists-add")
            }
        }
        .alert("composer.new_list", isPresented: $showsListCreator) {
            TextField("composer.list_emoji", text: $newListEmoji)
            TextField("composer.list_name", text: $newListTitle)
            Button("action.cancel", role: .cancel) {
                resetListCreator()
            }
            Button("action.create") {
                createList()
            }
            .disabled(!canCreateList)
        } message: {
            Text("composer.new_list_help")
        }
        .accessibilityIdentifier("emoji-lists-screen")
    }

    private func listRow(_ list: EmojiList) -> some View {
        HStack(spacing: AppSpacing.large) {
            Text(list.emoji)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(AppColors.amber.opacity(0.18), in: Circle())

            Text(list.title)
                .font(AppTypography.taskTitle)
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("task.delete", systemImage: "trash", role: .destructive) {
                store.removeEmojiList(list)
            }
            .labelStyle(.iconOnly)
            .font(.body.weight(.semibold))
            .foregroundStyle(AppColors.danger)
            .frame(width: 44, height: 44)
            .accessibilityLabel(Text("task.delete"))
        }
        .padding(.vertical, AppSpacing.xSmall)
        .listRowInsets(
            EdgeInsets(
                top: AppSpacing.small,
                leading: AppSpacing.screenMargin,
                bottom: AppSpacing.small,
                trailing: AppSpacing.screenMargin
            )
        )
        .listRowBackground(AppColors.surface)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.removeEmojiList(list)
            } label: {
                Label("task.delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var canCreateList: Bool {
        EmojiList.isValidEmoji(newListEmoji)
            && !newListTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createList() {
        guard canCreateList else { return }
        _ = store.createEmojiList(emoji: newListEmoji, title: newListTitle)
        resetListCreator()
    }

    private func resetListCreator() {
        newListEmoji = ""
        newListTitle = ""
    }
}

#Preview("Emoji Lists — Populated") {
    let environment = AppEnvironment.preview(populated: true)
    NavigationStack {
        EmojiListsView(store: environment.taskStore)
    }
    .modelContainer(environment.modelContainer)
}
