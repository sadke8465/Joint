import SwiftUI

struct SettingsShellView: View {
    let store: TaskStore

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("settings.our_space") {
                    Label("fixture.couple_name", systemImage: "person.2.fill")
                    Label("settings.two_members", systemImage: "checkmark.seal.fill")
                }

                Section("settings.tasks") {
                    NavigationLink {
                        ArchiveView(store: store)
                    } label: {
                        Label("archive.title", systemImage: "archivebox")
                    }

                    NavigationLink {
                        TrashView(store: store)
                    } label: {
                        Label("trash.title", systemImage: "trash")
                    }

                    NavigationLink {
                        EmojiListsView(store: store)
                    } label: {
                        Label("lists.title", systemImage: "face.smiling")
                    }
                }

                Section("settings.preferences") {
                    Label("settings.language", systemImage: "globe")
                    Label("settings.notifications", systemImage: "bell")
                    Label("settings.calendar", systemImage: "calendar")
                }

                Section {
                    Text("settings.local_note")
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .navigationTitle(Text("main.settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("composer.done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settings-done")
                }
            }
        }
        .accessibilityIdentifier("settings-shell")
    }
}
