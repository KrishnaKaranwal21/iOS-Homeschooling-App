import SwiftUI

/// One entry point for everyone: Apple, Google, or an emailed one-time code.
/// - Apple / Google: sign in directly and take the name from the provider.
/// - Email code: a known email signs in, an unknown email gets an account automatically.
struct LoginView: View {
    private enum Route { case entry, verify }

    var onSuccess: () -> Void = {}

    @State private var route: Route = .entry
    @State private var email = ""
    @State private var attempted = false
    @State private var loadingProvider: SocialProvider?
    @State private var socialError: String?
    @FocusState private var emailFocused: Bool

    private var cleanEmail: String { email.trimmingCharacters(in: .whitespaces) }
    private var emailIsValid: Bool { AuthValidation.isValidEmail(cleanEmail) }
    private var emailError: String? {
        guard attempted, !emailIsValid else { return nil }
        return cleanEmail.isEmpty ? "Enter your email" : "Enter a valid email address"
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            switch route {
            case .entry:
                entry
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .verify:
                VerifyCodeView(email: cleanEmail,
                               onBack: { go(.entry) },
                               onVerified: {
                                   // Known email signs in; unknown email is created here.
                                   AccountStore.signInOrCreate(email: cleanEmail, name: nil)
                                   onSuccess()
                               })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .foregroundStyle(Theme.ink)
    }

    /// Height of everything on this screen except the illustration (titles, buttons, email block).
    private let fixedContentHeight: CGFloat = 525

    /// The illustration takes whatever room is left, so the page fits without scrolling.
    private func illustrationHeight(in available: CGFloat) -> CGFloat {
        min(max(available - fixedContentHeight, 120), 320)
    }

    private var entry: some View {
        GeometryReader { geo in
            entryContent(illustrationHeight: illustrationHeight(in: geo.size.height))
        }
        .onSubmit(sendCode)
    }

    private func entryContent(illustrationHeight: CGFloat) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Image("LoginIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: illustrationHeight)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Come on in.")
                        .scaledFont(40, weight: .heavy)
                        .tracking(-1.6)
                        .foregroundStyle(Theme.ink)
                    Text("Your family’s learning starts here.")
                        .scaledFont(17)
                        .foregroundStyle(Theme.muted)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 4)

                VStack(spacing: 14) {
                    SocialButton(kind: .apple, title: "Continue with Apple",
                                 isLoading: loadingProvider == .apple) { signIn(with: .apple) }
                    SocialButton(kind: .google, title: "Continue with Google",
                                 isLoading: loadingProvider == .google) { signIn(with: .google) }

                    if let socialError {
                        Label(socialError, systemImage: "exclamationmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .disabled(loadingProvider != nil)
                .padding(.horizontal, 20)
                .padding(.top, 20)

                OrDivider(text: "or continue with email")
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Email address")
                        .scaledFont(16)
                        .foregroundStyle(Theme.muted)

                    AuthField(icon: "envelope", error: emailError) {
                        TextField("you@example.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.send)
                            .focused($emailFocused)
                    }

                    if emailError == nil {
                        Text("We’ll email you a one-time code.")
                            .font(.footnote)
                            .foregroundStyle(Theme.muted)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                // Scrolls with the page instead of being pinned to the bottom.
                sendSection
                    .padding(.horizontal, 20)
                    .padding(.top, 22)
                    .padding(.bottom, 16)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        // Only scrolls when it has to (small phones, or the keyboard is open).
        .scrollBounceBehavior(.basedOnSize)
    }

    private var sendSection: some View {
        VStack(spacing: 14) {
            PrimaryButton(title: "Send code", action: sendCode)

            Text("By continuing, you agree to our [Terms of Service](https://example.com/terms) and [Privacy Policy](https://example.com/privacy).")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .tint(Color(hex: 0x6B5BE2))
        }
    }

    // MARK: Actions

    private func go(_ next: Route) {
        emailFocused = false
        withAnimation(.snappy) { route = next }
    }

    private func sendCode() {
        attempted = true
        guard emailIsValid else { return }
        go(.verify)
    }

    private func signIn(with provider: SocialProvider) {
        guard loadingProvider == nil else { return }
        loadingProvider = provider
        socialError = nil
        emailFocused = false
        Task {
            do {
                let profile = try await SocialAuth.signIn(with: provider)
                AccountStore.signInOrCreate(email: profile.email, name: profile.name)
                loadingProvider = nil
                onSuccess()
            } catch {
                loadingProvider = nil
                socialError = "Couldn’t continue with \(provider.title). Please try again."
            }
        }
    }
}

#Preview {
    LoginView()
}
