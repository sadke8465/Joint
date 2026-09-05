import SwiftUI

struct SettingsShellView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("settings.our_space") {
                    Label("fixture.couple_name", systemImage: "person.2.fill")
                    Label("settings.two_members", systemImage: "checkmark.seal.fill")
                }

                Section("settings.preferences") {
                    Label("settings.language", systemImage: "globe")
                    Label("settings.notifications", systemImage: "bell")
                    Label("settings.calendar", systemImage: "calendar")
                }

                Section {
                    Text("settings.phase_note")
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
