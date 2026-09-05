import SwiftUI

struct AppCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.large)
            .background(
                reduceTransparency ? AppColors.surface : AppColors.surface.opacity(0.96),
                in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.divider, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.035), radius: 10, y: 4)
    }
}

extension View {
    func appCard() -> some View {
        modifier(AppCardModifier())
    }
}
