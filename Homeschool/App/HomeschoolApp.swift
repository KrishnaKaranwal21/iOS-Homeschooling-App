import SwiftUI

/// App entry point: owns the single `AppState` and applies the app-wide look.
@main
struct HomeschoolApp: App {
    @State private var state = AppState()

    var body: some Scene {
        WindowGroup {
            RootView().environment(state).tint(Theme.ink)
                .toggleStyle(HomeschoolSwitchStyle())
                // Deliberately light-only for now; see the note on `Theme`.
                .preferredColorScheme(.light)
        }
    }
}
