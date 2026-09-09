import SwiftUI

struct SettingsShellView: View {
    let store: TaskStore

    @Environment(\.dismiss) private var dismiss
    @State private var path: [MoreRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    coupleRow
                        .listRowBackground(AppColors.surface)
                }

                Section("settings.tasks") {
                    NavigationLink(value: MoreRoute.archive) {
                        settingsRow(
                            title: "archive.title",
                            icon: "archivebox.fill",
                            tint: AppColors.violet
                        )
                    }
                    .accessibilityIdentifier("tasks-archive")

                    NavigationLink(value: MoreRoute.emojiLists) {
                        settingsRow(
                            title: "lists.title",
                            icon: "face.smiling.fill",
                            tint: AppColors.amber
                        )
                    }
                    .accessibilityIdentifier("tasks-lists")

                    NavigationLink(value: MoreRoute.trash) {
                        settingsRow(
                            title: "trash.title",
                            icon: "trash.fill",
                            tint: AppColors.coral
                        )
                    }
                    .accessibilityIdentifier("settings-trash")
                }

                Section {
                    Text("settings.local_note")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.secondaryText)
                        .padding(.vertical, AppSpacing.small)
                        .listRowBackground(AppColors.groupedBackground.opacity(0.65))
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.canvas)
            .navigationTitle(Text("main.more"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColors.canvas, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("composer.done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settings-done")
                }
            }
            .navigationDestination(for: MoreRoute.self) { route in
                switch route {
                case .archive:
                    ArchiveView(store: store)
                case .emojiLists:
                    EmojiListsView(store: store)
                case .trash:
                    TrashView(store: store)
                }
            }
        }
        .preferredColorScheme(.light)
        .accessibilityIdentifier("settings-shell")
    }

    private var coupleRow: some View {
        HStack(spacing: AppSpacing.large) {
            AppIconBadge(
                systemName: "person.2.fill",
                tint: AppColors.violet,
                size: 54
            )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("fixture.couple_name")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.primaryText)

                Label("settings.two_members", systemImage: "checkmark.seal.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.violet)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, AppSpacing.small)
        .accessibilityElement(children: .combine)
    }

    private func settingsRow(
        title: LocalizedStringKey,
        icon: String,
        tint: Color
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)

            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.primaryText)
        }
        .frame(minHeight: 44)
    }
}

#Preview("Settings") {
    let environment = AppEnvironment.preview(populated: true)
    SettingsShellView(store: environment.taskStore)
        .modelContainer(environment.modelContainer)
}
