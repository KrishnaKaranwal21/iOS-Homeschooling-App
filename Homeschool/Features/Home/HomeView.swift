import SwiftUI

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
