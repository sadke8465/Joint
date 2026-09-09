import SwiftUI

struct MainHeader: View {
    let openTaskCount: Int

    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    title
                    controls
                }
            } else {
                HStack(alignment: .center, spacing: AppSpacing.medium) {
                    title
                    controls
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenMargin)
        .padding(.top, AppSpacing.medium)
        .padding(.bottom, AppSpacing.small)
        .background(AppColors.canvas)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("fixture.couple_name")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(openTasksText)
                .font(AppTypography.metadata)
                .foregroundStyle(AppColors.secondaryText)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var controls: some View {
        @Bindable var router = router

        return HStack(spacing: AppSpacing.small) {
            ModeSwitcher(selection: $router.selectedMode)

            Button {
                router.presentedSheet = .more
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(AppColors.surface, in: Circle())
                    .overlay {
                        Circle().stroke(AppColors.border.opacity(0.72), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColors.primaryText)
            .accessibilityLabel(Text("main.more"))
            .accessibilityIdentifier("profile-settings")
        }
    }

    private var openTasksText: String {
        let format = String(localized: "main.open_tasks_format", locale: locale)
        return String.localizedStringWithFormat(format, openTaskCount)
    }
}
