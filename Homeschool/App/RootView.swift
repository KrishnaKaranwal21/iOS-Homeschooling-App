import SwiftUI

struct RootView: View {
    @EnvironmentObject var state: AppState

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
