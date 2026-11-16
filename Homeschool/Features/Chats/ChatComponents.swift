import SwiftUI
import LocalAuthentication

// MARK: - ChatAvatar

struct ChatAvatar: View {
    let thread: ChatThread
    var size: CGFloat = 56

    var body: some View {
        Text(thread.initials)
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(thread.avatarColor))
            .accessibilityHidden(true)
    }
}

// MARK: - ReadTicks

/// One tick when sent, two when delivered, two in the accent colour once read.
struct ReadTicks: View {
    let status: MessageStatus

    var body: some View {
        HStack(spacing: -6) {
            Image(systemName: "checkmark")
            if status != .sent { Image(systemName: "checkmark") }
        }
        .scaledFont(11, weight: .bold)
        .foregroundStyle(status == .read ? Theme.tabSelected : Theme.secondary)
        .accessibilityLabel(status == .sent ? "Sent" : (status == .delivered ? "Delivered" : "Read"))
    }
}

// MARK: - ChatToastView

/// Dark bar like "List was created", with an optional action.
struct ChatToastView: View {
    let toast: ChatToast
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(toast.message)
                .scaledFont(15, maxScale: 1.3)
                .foregroundStyle(Color.white)
            Spacer(minLength: 8)
            if let title = toast.actionTitle {
                Button(action: onAction) {
                    Text(title)
                        .scaledFont(15, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.buttonText)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(Theme.buttonFill, in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}
