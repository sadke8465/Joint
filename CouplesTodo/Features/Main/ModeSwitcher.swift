import SwiftUI

struct ModeSwitcher: View {
    @Binding var selection: MainMode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            ForEach(MainMode.allCases) { mode in
                Button {
                    withAnimation(AppMotion.selection(reduceMotion: reduceMotion)) {
                        selection = mode
                    }
                } label: {
                    modeLabel(for: mode)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .foregroundStyle(
                            selection == mode ? AppColors.primaryText : AppColors.secondaryText
                        )
                        .background {
                            if selection == mode {
                                Capsule()
                                    .fill(AppColors.surface)
                                    .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(mode.titleKey)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
                .accessibilityIdentifier("mode-\(mode.rawValue)")
            }
        }
        .padding(AppSpacing.xSmall)
        .background(AppColors.controlBackground, in: Capsule())
    }

    @ViewBuilder
    private func modeLabel(for mode: MainMode) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            Image(systemName: mode.iconName)
                .font(.body.weight(.semibold))
        } else {
            Label(mode.titleKey, systemImage: mode.iconName)
                .font(AppTypography.caption)
                .lineLimit(1)
        }
    }
}
