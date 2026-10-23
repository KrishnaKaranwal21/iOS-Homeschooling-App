import SwiftUI

enum AuthValidation {
    static func isValidEmail(_ value: String) -> Bool {
        guard !value.contains(" ") else { return false }
        let parts = value.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty else { return false }
        let domain = parts[1]
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }
}

/// White rounded field row with a leading icon and an inline error underneath.
struct AuthField<Content: View>: View {
    let icon: String
    var error: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .frame(width: 24)
                    .foregroundStyle(Theme.systemGray)
                content
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 54)
            .insetCard()
            .overlay {
                if error != nil {
                    RoundedRectangle(cornerRadius: Theme.insetRadius, style: .continuous)
                        .stroke(Color.red.opacity(0.7), lineWidth: 1)
                }
            }

            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Full-width white rounded button: provider logo, then the title, centred together.
struct SocialButton: View {
    enum Kind { case google, apple }

    let kind: Kind
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Group {
                    if isLoading {
                        ProgressView()
                    } else {
                        logo
                    }
                }
                .frame(width: 26, height: 26)

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.lavender.opacity(0.7), lineWidth: 1))
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var logo: some View {
        switch kind {
        case .apple:
            Image(systemName: "apple.logo")
                .font(.system(size: 22))
                .foregroundStyle(Theme.ink)
        case .google:
            GoogleG()
        }
    }
}

/// Four-colour "G" drawn with shapes. Swap for the official Google logo asset before release.
private struct GoogleG: View {
    private let blue   = Color(hex: 0x4285F4)
    private let green  = Color(hex: 0x34A853)
    private let yellow = Color(hex: 0xFBBC05)
    private let red    = Color(hex: 0xEA4335)

    var body: some View {
        ZStack {
            arc(0.00, 0.125, blue)
            arc(0.125, 0.40, green)
            arc(0.40, 0.58, yellow)
            arc(0.58, 0.875, red)
            Rectangle()
                .fill(blue)
                .frame(width: 12, height: 4.5)
                .offset(x: 6)
        }
        .frame(width: 24, height: 24)
    }

    private func arc(_ from: CGFloat, _ to: CGFloat, _ color: Color) -> some View {
        Circle()
            .trim(from: from, to: to)
            .stroke(color, style: StrokeStyle(lineWidth: 4.5, lineCap: .butt))
            .padding(2.25)
    }
}

struct OrDivider: View {
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Rectangle().fill(Theme.lavender.opacity(0.6)).frame(height: 1)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(Theme.muted)
                .fixedSize()
            Rectangle().fill(Theme.lavender.opacity(0.6)).frame(height: 1)
        }
    }
}
