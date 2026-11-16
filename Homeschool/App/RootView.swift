import SwiftUI

/// Switches between the app's stages (sign in, onboarding, child setup, main tabs) from `AppState`, and reports whether the window is landscape.
struct RootView: View {
    @Environment(AppState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isLandscape = false

    var body: some View {
        ZStack {
            // Full window, so its shape tells portrait from landscape.
            Theme.background
                .ignoresSafeArea()
                .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: { isLandscape = $0 }

            stageView
                .padding(.horizontal, sizeClass == .regular ? 24 : 0)
                .adaptiveColumn(maxWidth: 880)
        }
        .environment(\.uiScale, sizeClass == .regular ? 1.18 : 1)
        .environment(\.isLandscape, isLandscape)
    }

    @ViewBuilder private var stageView: some View {
        switch state.stage {
        case .onboarding:
            OnboardingView {
                state.advance(to: .login)
            }
        case .login:
            LoginView { returning in
                state.finishLogin(returning: returning)
            }
        case .setup:
            ChildSetupFlowView()
        case .main:
            MainTabView()
        }
    }
}
