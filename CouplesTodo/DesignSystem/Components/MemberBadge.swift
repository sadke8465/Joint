import SwiftUI

struct MemberBadge: View {
    let style: MemberStyle
    var compact = false

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Image(systemName: style.iconName)
                .font(.caption2.weight(.bold))
                .accessibilityHidden(true)

            Text(style.labelKey)
                .font(AppTypography.caption)
                .lineLimit(1)
        }
        .foregroundStyle(style.labelColor)
        .padding(.horizontal, compact ? 9 : 12)
        .padding(.vertical, compact ? 5 : 7)
        .background(style.color.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(style.labelKey)
    }
}

#Preview("Member badges") {
    HStack {
        ForEach(MemberStyle.allCases) { style in
            MemberBadge(style: style)
        }
    }
    .padding()
}
