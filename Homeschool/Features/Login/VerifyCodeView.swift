import SwiftUI

/// Second step of login: shows the email the code was sent to and takes the 6-digit code.
struct VerifyCodeView: View {
    /// Temporary key accepted for every account until real email codes exist.
    static let demoCode = "000000"
    private static let length = 6
    private static let resendSeconds = 30

    let email: String
    var onBack: () -> Void = {}
    var onVerified: () -> Void = {}

    @State private var code = ""
    @State private var showError = false
    @State private var shakes: CGFloat = 0
    @State private var errorCount = 0
    @State private var verified = false
    @State private var secondsLeft = VerifyCodeView.resendSeconds
    @State private var resendToken = 0
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                Button(action: onBack) {
                    Label("Back", systemImage: "chevron.left")
                }
                .foregroundStyle(Theme.ink)

                VStack(alignment: .leading, spacing: 18) {
                    Circle()
                        .fill(Color(hex: 0xFFC8C9))
                        .frame(width: 56, height: 56)
                        .overlay(Image(systemName: "envelope")
                            .scaledFont(24)
                            .foregroundStyle(Theme.ink))
                        .accessibilityHidden(true)

                    AuthTitle(
                        title: "Check your\nemail.",
                        subtitle: Text("We sent a 6-digit code to \(Text(email).fontWeight(.semibold).foregroundStyle(Theme.ink)).")
                    )
                }

                codeBoxes

                if showError {
                    Label("That code isn’t right. Try again.", systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.red)
                        .transition(.opacity)
                }

                resendRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { focused = true }
        .task(id: resendToken) {
            secondsLeft = Self.resendSeconds
            while secondsLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                secondsLeft -= 1
            }
        }
        .sensoryFeedback(.error, trigger: errorCount)
        .sensoryFeedback(.success, trigger: verified)
        .animation(.snappy, value: showError)
    }

    // MARK: Code boxes

    private var codeBoxes: some View {
        ZStack {
            HStack(spacing: 10) {
                ForEach(0..<Self.length, id: \.self) { index in
                    box(at: index)
                }
            }
            .modifier(ShakeEffect(travel: shakes))

            // Real input: invisible, drives the boxes above and supports the iOS email-code autofill.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .opacity(0.02)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: code) { _, newValue in handleChange(newValue) }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Verification code")
        .accessibilityValue(code.isEmpty ? "Empty" : code)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { focused = true }
    }

    private func box(at index: Int) -> some View {
        let characters = Array(code)
        let digit = index < characters.count ? String(characters[index]) : ""
        let isActive = focused && index == min(characters.count, Self.length - 1)

        return Text(digit)
            .scaledFont(26, weight: .semibold)
            .monospacedDigit()
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(Color.white, in: .rect(cornerRadius: 16))
            .roundedStroke(borderColor(active: isActive, filled: !digit.isEmpty), cornerRadius: 16, lineWidth: isActive || showError ? 1.5 : 1)
    }

    private func borderColor(active: Bool, filled: Bool) -> Color {
        if showError { return Color.red.opacity(0.7) }
        if active { return Theme.ink }
        return filled ? Color(hex: 0xEFB4B4) : Theme.cardBorder
    }

    // MARK: Resend

    private var resendRow: some View {
        HStack(spacing: 4) {
            Text("Didn’t get it?").foregroundStyle(Theme.muted)
            if secondsLeft > 0 {
                Text("Resend in 0:\(secondsLeft.formatted(.number.precision(.integerLength(2...))))")
                    .monospacedDigit()
                    .foregroundStyle(Theme.muted)
            } else {
                Button("Resend code", action: resend).fontWeight(.semibold)
            }
        }
        .font(.subheadline)
    }

    // MARK: Logic

    private func handleChange(_ newValue: String) {
        let digits = String(newValue.filter(\.isNumber).prefix(Self.length))
        if digits != newValue { code = digits; return }
        if !digits.isEmpty { showError = false }
        if digits.count == Self.length { verify() }
    }

    private func verify() {
        // Replace with a server check once real codes are emailed.
        guard code == Self.demoCode else {
            showError = true
            errorCount += 1
            withAnimation(.linear(duration: 0.4)) { shakes += 1 }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                code = ""
                focused = true
            }
            return
        }
        focused = false
        verified = true
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            onVerified()
        }
    }

    private func resend() {
        code = ""
        showError = false
        resendToken += 1
        focused = true
    }
}

/// Horizontal wobble used when the code is wrong.
private struct ShakeEffect: GeometryEffect {
    var travel: CGFloat
    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(travel * .pi * 4), y: 0))
    }
}

#Preview {
    VerifyCodeView(email: "maya@gmail.com")
}
