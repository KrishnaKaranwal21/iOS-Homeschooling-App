import SwiftUI

/// One set of text styles for every screen, so titles look the same everywhere.
///
/// - `pageTitle`: the big title at the top of a page (Gatherings, Chats, Profile, Registration...)
/// - `pageSubtitle`: the grey line under it
/// - `sectionTitle`: a heading inside a page ("Explore more", "Your children")
/// - `cardTitle`: a heading inside a card
extension View {
    func pageTitle() -> some View {
        scaledFont(32, weight: .heavy, maxScale: 1.15)
            .tracking(-1)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    func pageSubtitle() -> some View {
        scaledFont(16, maxScale: 1.3)
            .foregroundStyle(Theme.secondary)
    }

    func sectionTitle() -> some View {
        scaledFont(22, weight: .heavy, maxScale: 1.2)
            .tracking(-0.5)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    func cardTitle() -> some View {
        scaledFont(18, weight: .heavy, maxScale: 1.15)
            .tracking(-0.3)
            .foregroundStyle(Theme.ink)
    }
}
