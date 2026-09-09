import SwiftUI

/// Every lab is the same two things: a stage showing the component, and a panel of sliders
/// under it. Fullscreen removes the panel, the navigation bar and the system overlays, so the
/// component is the only thing on screen.
///
/// That is not a convenience — it is the point of a motion lab. Judging a 300ms spring while a
/// row of sliders sits two inches beneath it means you are always half-looking at the sliders,
/// and the thing you are actually trying to see is the smallest object on the screen.
///
/// The stage stays the `VStack`'s first child in both modes on purpose. Swapping between two
/// different hierarchies would hand it a new identity every time you toggled, and the task
/// list would lose `settled`, `moves` and its measured pitch — you would leave fullscreen to a
/// list that had silently reset itself.
struct LabShell<Stage: View, Panel: View>: View {
    @Binding var isFullscreen: Bool
    @ViewBuilder var stage: Stage
    @ViewBuilder var panel: Panel

    var body: some View {
        VStack(spacing: 0) {
            // Its own row rather than an overlay. Floating it over the corner puts it on top
            // of whatever the lab happens to put first — the filter pills, in two of them —
            // and over a control the component owns, where it would swallow the tap.
            if isFullscreen {
                exitButton
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 14)
                    .padding(.top, 2)
            }

            // Centred rather than pinned to the top: with the panel gone the component should
            // sit where the eye already is, not float under a large empty bar.
            stage
                .frame(maxHeight: isFullscreen ? .infinity : nil)

            if !isFullscreen {
                Divider()
                panel
            }
        }
        // Matches the stages' own colour, so this is invisible in windowed mode and only does
        // work in fullscreen, where it carries the ground into the safe areas.
        .background { Color(.systemGroupedBackground).ignoresSafeArea() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    setFullscreen(true)
                } label: {
                    Label("Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                }
            }
        }
        .toolbarVisibility(isFullscreen ? .hidden : .automatic, for: .navigationBar)
        .statusBarHidden(isFullscreen)
        .persistentSystemOverlays(isFullscreen ? .hidden : .automatic)
    }

    /// Deliberately faint and small. It is the only chrome left, and a prominent button in the
    /// corner of an otherwise empty screen is exactly the distraction fullscreen removes.
    private var exitButton: some View {
        Button {
            setFullscreen(false)
        } label: {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(10)
                .background(.regularMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .transition(.opacity)
        .accessibilityLabel("Leave fullscreen")
    }

    /// `withAnimation` rather than `.animation(_:value:)` on the stack: an animation modifier
    /// there would sit above every row and claim any change that happened to land in the same
    /// update as the toggle.
    private func setFullscreen(_ value: Bool) {
        withAnimation(.smooth(duration: 0.3)) { isFullscreen = value }
    }
}
