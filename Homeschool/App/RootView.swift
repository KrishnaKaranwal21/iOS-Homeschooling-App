import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        switch state.stage {
        case .onboarding:
            OnboardingView {
                state.advance(to: .login)
            }
        case .login:
            LoginView {
                state.advance(to: .setup)
            }
        case .setup:
            ChildSetupFlowView()
        case .main:
            MainTabView()
        }
    }
}
