import SwiftUI

struct ComponentCatalogView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Motion") {
                    NavigationLink {
                        ClaudeSuggestionLab()
                    } label: {
                        Label("Claude's Suggestion", systemImage: "sparkles")
                    }

                    NavigationLink {
                        FilterLab()
                    } label: {
                        Label("Filtering", systemImage: "line.3.horizontal.decrease.circle")
                    }

                    NavigationLink {
                        FinalPlayground()
                    } label: {
                        Label("\"Final-ish\"", systemImage: "checkmark.seal")
                    }

                    NavigationLink {
                        TaskCompletionLab()
                    } label: {
                        Label("Completion Motion", systemImage: "waveform.path")
                    }

                    NavigationLink {
                        MoveDownLab()
                    } label: {
                        Label("Move Down", systemImage: "arrow.down.to.line")
                    }
                }

                Section("Components") {
                    NavigationLink {
                        TaskItemDemo()
                    } label: {
                        Label("Task Item", systemImage: "checkmark.circle")
                    }

                    NavigationLink {
                        DateRulerPickerDemo()
                    } label: {
                        Label("Date Ruler Picker", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("Component Lab")
        }
    }
}

#Preview {
    ComponentCatalogView()
}
