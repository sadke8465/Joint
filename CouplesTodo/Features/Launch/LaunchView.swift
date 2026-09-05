import SwiftUI

struct LaunchView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(AppInfo.displayName)
                .font(.title2.weight(.semibold))
                .accessibilityIdentifier("launch-title")
        }
        .padding()
    }
}

#Preview {
    LaunchView()
}
