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
        .foregroundStyle(style.color)
        .padding(.horizontal, compact ? 7 : 10)
        .padding(.vertical, compact ? 4 : 6)
        .background(style.color.opacity(0.11), in: Capsule())
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
