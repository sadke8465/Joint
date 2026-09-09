import SwiftUI

struct ModeSwitcher: View {
    @Binding var selection: MainMode

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            ForEach(MainMode.allCases) { mode in
                Button {
                    withAnimation(AppMotion.selection(reduceMotion: reduceMotion)) {
                        selection = mode
                    }
                } label: {
                    Image(systemName: mode.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .foregroundStyle(
                            selection == mode ? AppColors.primaryText : AppColors.tertiaryText
                        )
                        .background {
                            if selection == mode {
                                RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                                    .fill(AppColors.surface)
                                    .shadow(color: .black.opacity(0.06), radius: 5, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(mode.titleKey)
                .accessibilityAddTraits(selection == mode ? .isSelected : [])
                .accessibilityIdentifier("mode-\(mode.rawValue)")
            }
        }
        .padding(AppSpacing.xSmall)
        .background(AppColors.groupedBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
    }
}
