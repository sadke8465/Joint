import SwiftUI

enum AppSurfaceStyle {
    case plain
    case soft
    case elevated
    case tinted(Color)
}

struct AppCardModifier: ViewModifier {
    let style: AppSurfaceStyle
    let padding: CGFloat

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                fillColor,
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .shadow(
                color: isElevated ? Color.black.opacity(0.09) : .clear,
                radius: isElevated ? 20 : 0,
                y: isElevated ? 10 : 0
            )
    }

    private var fillColor: Color {
        switch style {
        case .plain, .elevated:
            AppColors.surface
        case .soft:
            AppColors.groupedBackground
        case .tinted(let color):
            color.opacity(reduceTransparency ? 0.18 : 0.12)
        }
    }

    private var isElevated: Bool {
        if case .elevated = style { return true }
        return false
    }

    private var borderColor: Color {
        switch style {
        case .elevated:
            .clear
        case .plain, .soft:
            AppColors.border.opacity(0.72)
        case .tinted(let color):
            color.opacity(0.16)
        }
    }
}

extension View {
    func appCard(
        _ style: AppSurfaceStyle = .plain,
        padding: CGFloat = AppSpacing.large
    ) -> some View {
        modifier(AppCardModifier(style: style, padding: padding))
    }
}

struct AppIconBadge: View {
    let systemName: String
    var tint = AppColors.playBlue
    var foreground = Color.white
    var size: CGFloat = 48

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(tint, in: Circle())
            .accessibilityHidden(true)
    }
}

struct AppSectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let icon: String?
    @ViewBuilder let trailing: Trailing

    init(
        _ title: LocalizedStringKey,
        icon: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.icon = icon
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.medium) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.playBlue)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.primaryText)

            Spacer(minLength: 0)
            trailing
        }
    }
}

extension AppSectionHeader where Trailing == EmptyView {
    init(_ title: LocalizedStringKey, icon: String? = nil) {
        self.init(title, icon: icon) { EmptyView() }
    }
}

struct AppEmptyState: View {
    let title: LocalizedStringKey
    let systemImage: String
    let description: LocalizedStringKey
    var tint = AppColors.playBlue
    var iconForeground = Color.white

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColors.success.opacity(0.18))
                    .frame(width: 84, height: 62)
                    .offset(y: -12)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.amber.opacity(0.25))
                    .frame(width: 96, height: 68)
                    .offset(y: -5)

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 110, height: 74)

                AppIconBadge(
                    systemName: systemImage,
                    tint: tint,
                    foreground: iconForeground,
                    size: 52
                )
            }
            .frame(height: 90)
            .accessibilityHidden(true)

            VStack(spacing: AppSpacing.small) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.primaryText)

                Text(description)
                    .font(AppTypography.metadata)
                    .foregroundStyle(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .appCard(.soft, padding: AppSpacing.xLarge)
        .accessibilityElement(children: .combine)
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var tint = AppColors.accent

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(.white)
            .background(isEnabled ? tint : AppColors.tertiaryText, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    var tint = AppColors.primaryText

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .frame(minHeight: 52)
            .padding(.horizontal, AppSpacing.xLarge)
            .foregroundStyle(tint)
            .background(AppColors.groupedBackground, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.76 : 1)
    }
}

struct AppPillButtonStyle: ButtonStyle {
    let isSelected: Bool
    var tint = AppColors.accent
    var unselectedForeground = AppColors.secondaryText

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.caption)
            .foregroundStyle(isSelected ? Color.white : unselectedForeground)
            .padding(.horizontal, AppSpacing.large)
            .frame(minHeight: 44)
            .background(isSelected ? tint : AppColors.groupedBackground, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

struct AppCircularButtonStyle: ButtonStyle {
    var tint = AppColors.primaryText
    var foreground = Color.white
    var size: CGFloat = 62

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.4, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(tint, in: Circle())
            .shadow(color: Color.black.opacity(0.16), radius: 14, y: 8)
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}
