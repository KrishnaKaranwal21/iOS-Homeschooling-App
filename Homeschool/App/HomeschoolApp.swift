import SwiftUI

@main
struct HomeschoolApp: App {
    @State private var state = AppState()
    var body: some Scene {
        WindowGroup {
            RootView().environment(state).tint(Theme.ink)
        }
    }
}
