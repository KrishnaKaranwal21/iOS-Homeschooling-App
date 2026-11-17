import SwiftUI

/// A card over the whole app, like "Learning, wrapped up", for news the person should not miss.
struct AppPopupView: View {
    let popup: AppPopup
    let onDismiss: () -> Void
    let onOpen: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
                .accessibilityHidden(true)

            VStack(spacing: 16) {
                Text(popup.title)
                    .scaledFont(30, weight: .bold, maxScale: 1.15)
                    .tracking(-0.8)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                HomeMascotView()
                    .frame(height: 120)
                    .accessibilityHidden(true)

                VStack(spacing: 4) {
                    Text(popup.headline)
                        .scaledFont(17, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                    Text(popup.detail)
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(Theme.lavender.opacity(0.55), in: .rect(cornerRadius: 20))

                Text(popup.message)
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .multilineTextAlignment(.center)

                Button(popup.buttonTitle, action: onOpen)
                    .buttonStyle(.primaryHomeschool)

                Button("Not now", action: onDismiss)
                    .scaledFont(15, weight: .medium, maxScale: 1.25)
                    .foregroundStyle(Theme.gatherText)
                    .frame(minHeight: 36)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(Theme.surface, in: .rect(cornerRadius: 40))
            .shadow(color: .black.opacity(0.18), radius: 24, y: 10)
            .padding(.horizontal, 28)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
        }
    }
}
