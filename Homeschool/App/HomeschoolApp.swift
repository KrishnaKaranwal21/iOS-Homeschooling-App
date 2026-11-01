import SwiftUI

@main
struct HomeschoolApp: App {
    @State private var state = AppState()
    @AppStorage(AppAppearance.storageKey) private var appearance = AppAppearance.system.rawValue
    var body: some Scene {
        WindowGroup {
            RootView().environment(state).tint(Theme.ink)
                .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
        }
    }
}
