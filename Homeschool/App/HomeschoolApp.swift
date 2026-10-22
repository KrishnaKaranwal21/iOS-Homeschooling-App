import SwiftUI

@main
struct HomeschoolApp: App {
    @StateObject private var state = AppState()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(state).tint(Theme.ink)
        }
    }
}
