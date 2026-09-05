import SwiftUI

struct TaskComposerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var notes = ""
    @State private var assignee = MemberStyle.together
    @State private var hasDate = false
    @State private var hasTime = false
    @State private var emoji: String?
    @State private var addFeedbackTrigger = 0
    @FocusState private var titleIsFocused: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                    titleField
                    assigneeSection
                    detailSection
                    notesSection
                }
                .padding(AppSpacing.large)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppColors.background)
            .safeAreaInset(edge: .bottom) {
                addButton
            }
            .navigationTitle(Text("composer.new_task"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("composer.done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("composer-done")
                }
            }
        }
        .onAppear {
            titleIsFocused = true
        }
        .sensoryFeedback(AppHaptics.selection, trigger: assignee)
        .sensoryFeedback(AppHaptics.add, trigger: addFeedbackTrigger)
        .accessibilityIdentifier("task-composer")
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("composer.title_label")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)

            TextField("composer.title_placeholder", text: $title, axis: .vertical)
                .font(AppTypography.body)
                .lineLimit(1...3)
                .submitLabel(.done)
                .focused($titleIsFocused)
                .onSubmit(addAndContinue)
                .accessibilityIdentifier("task-title")
        }
        .appCard()
    }

    private var assigneeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("composer.assignee")
                .font(AppTypography.sectionTitle)

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.small) {
                    assigneeButtons
                }
            } else {
                HStack(spacing: AppSpacing.small) {
                    assigneeButtons
                }
            }
        }
    }

    @ViewBuilder
    private var assigneeButtons: some View {
        ForEach(MemberStyle.allCases) { style in
            Button {
                assignee = style
            } label: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        HStack(spacing: AppSpacing.small) {
                            Image(systemName: style.iconName)
                            Text(style.composerLabelKey)
                            Spacer(minLength: 0)
                        }
                    } else {
                        VStack(spacing: AppSpacing.xSmall) {
                            Image(systemName: style.iconName)
                            Text(style.composerLabelKey)
                                .lineLimit(1)
                        }
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(assignee == style ? .white : style.color)
                .padding(.horizontal, AppSpacing.small)
                .frame(maxWidth: .infinity, minHeight: dynamicTypeSize.isAccessibilitySize ? 52 : 64)
                .background(
                    assignee == style ? style.color : style.color.opacity(0.11),
                    in: RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(style.composerLabelKey)
            .accessibilityAddTraits(assignee == style ? .isSelected : [])
            .accessibilityIdentifier("assignee-\(style.rawValue)")
        }
    }

    private var detailSection: some View {
        VStack(spacing: 0) {
            detailButton(
                title: "composer.date",
                value: hasDate ? "date.tomorrow" : "composer.none",
                icon: "calendar"
            ) {
                hasDate.toggle()
                if !hasDate { hasTime = false }
            }

            Divider().padding(.leading, 44)

            detailButton(
                title: "composer.time",
                value: hasTime ? "fixture.time.evening" : "composer.none",
                icon: "clock",
                isEnabled: hasDate
            ) {
                hasTime.toggle()
            }

            Divider().padding(.leading, 44)

            detailButton(
                title: "composer.emoji_list",
                value: emoji == nil ? "composer.none" : "composer.shopping",
                icon: emoji ?? "face.smiling",
                usesSystemImage: emoji == nil
            ) {
                emoji = emoji == nil ? "🛒" : nil
            }
        }
        .appCard()
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("composer.notes")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.secondaryText)

            TextField("composer.notes_placeholder", text: $notes, axis: .vertical)
                .font(AppTypography.body)
                .lineLimit(2...5)
        }
        .appCard()
    }

    private var addButton: some View {
        Button {
            guard canAdd else { return }
            addFeedbackTrigger += 1
            dismiss()
        } label: {
            Text("composer.add")
                .font(AppTypography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
                .foregroundStyle(.white)
                .background(canAdd ? AppColors.accent : AppColors.tertiaryText, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canAdd)
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.small)
        .background(AppColors.background.opacity(0.97))
        .accessibilityIdentifier("composer-add")
    }

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func addAndContinue() {
        guard canAdd else { return }
        addFeedbackTrigger += 1
        title = ""
        titleIsFocused = true
    }

    private func detailButton(
        title: LocalizedStringKey,
        value: LocalizedStringKey,
        icon: String,
        usesSystemImage: Bool = true,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Group {
                    if usesSystemImage {
                        Image(systemName: icon)
                    } else {
                        Text(icon)
                    }
                }
                .frame(width: 28)
                .accessibilityHidden(true)

                Text(title)
                    .foregroundStyle(AppColors.primaryText)

                Spacer()

                Text(value)
                    .foregroundStyle(AppColors.secondaryText)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.tertiaryText)
                    .accessibilityHidden(true)
            }
            .font(AppTypography.body)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

#Preview("Composer") {
    TaskComposerView()
}

#Preview("Composer Hebrew") {
    TaskComposerView()
        .environment(\.locale, Locale(identifier: "he_IL"))
        .environment(\.layoutDirection, .rightToLeft)
}
