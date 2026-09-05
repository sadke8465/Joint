import SwiftUI

struct MainHeader: View {
    @Binding var selectedMode: MainMode
    let openTaskCount: Int

    @Environment(AppRouter.self) private var router
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("fixture.couple_name")
                        .font(AppTypography.screenTitle)
                        .foregroundStyle(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(openTasksText)
                        .font(AppTypography.metadata)
                        .foregroundStyle(AppColors.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    router.presentedSheet = .settings
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 25, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(AppColors.surface, in: Circle())
                        .overlay {
                            Circle().stroke(AppColors.divider, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.primaryText)
                .accessibilityLabel(Text("main.settings"))
                .accessibilityIdentifier("profile-settings")
            }

            ModeSwitcher(selection: $selectedMode)
        }
    }

    private var openTasksText: String {
        let format = String(localized: "main.open_tasks_format", locale: locale)
        return String.localizedStringWithFormat(format, openTaskCount)
    }
}
