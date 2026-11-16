import SwiftUI

/// The parents the person has connected with.
struct MyConnectionsView: View {
    @Environment(AppState.self) private var state

    private var connectedParents: [Parent] {
        MockData.parents.filter {
            state.connectedParents.contains($0.id)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if connectedParents.isEmpty {
                    ContentUnavailableView(
                        "No Connections Yet",
                        systemImage: "person.2",
                        description: Text(
                            "Your connected families will appear here."
                        )
                    )
                } else {
                    ForEach(connectedParents) { parent in
                        ParentCard(parent: parent)
                    }
                }
            }
            .padding(.horizontal, TabPageLayout.horizontalInset)
            .padding(.vertical, 16)
        }
        .background(Theme.background)
        .navigationTitle("My connections")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("My connections") {
    MyConnectionsView()
        .environment(AppState())
}
