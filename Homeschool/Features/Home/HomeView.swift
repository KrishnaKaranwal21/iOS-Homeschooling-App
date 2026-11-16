import SwiftUI

/// The Home tab: the first-visit welcome for new accounts, or the daily view for returning ones.
struct HomeView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        if state.isReturningSession {
            ReturningHomeView(child: state.child)
                .id(state.child.id)
        } else {
            FirstHomeView()
        }
    }
}

#Preview("Home") {
    HomeView()
        .environment(AppState())
}
