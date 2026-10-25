import SwiftUI

/// One set of text styles for every screen, so titles look the same everywhere.
///
/// - `pageTitle`: the big title at the top of a page (Gatherings, Chats, Profile, Registration...)
/// - `pageSubtitle`: the grey line under it
/// - `sectionTitle`: a heading inside a page ("Explore more", "Your children")
/// - `cardTitle`: a heading inside a card
/// - `detailTitle`: the name on a detail page (an event, a chat)
/// - `rowTitle` / `rowDetail`: the two lines of an information row
/// - `bodyText` / `caption`: paragraphs and small notes
extension View {
    func detailTitle() -> some View {
        scaledFont(28, weight: .heavy, maxScale: 1.15)
            .tracking(-0.8)
            .foregroundStyle(Theme.ink)
            .accessibilityAddTraits(.isHeader)
    }

    func rowTitle() -> some View {
        scaledFont(16, weight: .medium, maxScale: 1.25)
            .foregroundStyle(Theme.ink)
    }

    func rowDetail() -> some View {
        scaledFont(14, maxScale: 1.25)
            .foregroundStyle(Theme.secondary)
    }

    func bodyText() -> some View {
        scaledFont(15, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
    }

    func caption() -> some View {
        scaledFont(13, maxScale: 1.25)
            .foregroundStyle(Theme.secondary)
    }

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
