import SwiftUI

// MARK: - Card

/// A rounded, padded container that fills the available width; the basic building block for grouped content.
struct Card<Content: View>: View {
    var color: Color = Theme.surface
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(Theme.Spacing.m).frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: .rect(cornerRadius: Theme.Radius.card))
    }
}

// MARK: - Chip

/// A small pill with an optional leading symbol that shows a checkmark when `selected`.
struct Chip: View {
    let title: String
    var systemImage: String? = nil
    var selected = false
    var body: some View {
        HStack(spacing: 6) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            if selected { Image(systemName: "checkmark") }
        }
        .font(.subheadline).padding(.horizontal, 14).padding(.vertical, 10)
        .background(selected ? Theme.pink : Theme.field, in: Capsule())
    }
}

// MARK: - Eyebrow

/// A tiny upper-case label that sits above a title.
struct Eyebrow: View {
    let text: String
    init(_ t: String) { text = t }
    var body: some View { Text(text.uppercased()).font(.caption2).tracking(0.8).foregroundStyle(Theme.secondary) }
}

// MARK: - ScreenHeader

/// A large page title with an optional grey subtitle.
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            if let subtitle { Text(subtitle).foregroundStyle(Theme.secondary) }
        }
    }
}

// MARK: - Mascot

/// The Learnook mascot at a fixed square size.
struct Mascot: View {
    var size: CGFloat = 80
    var body: some View {
        HomeMascotView().frame(width: size, height: size)
    }
}

// MARK: - AvatarView

/// A circle showing a person's initials; the initials scale with `size`.
struct AvatarView: View {
    let initials: String
    var color: Color = Theme.lavender
    var size: CGFloat = 48
    var body: some View {
        Text(initials).font(.system(size: size * 0.36, weight: .semibold))
            .frame(width: size, height: size).background(color, in: Circle())
    }
}

// MARK: - SetupHeader

/// The title and subtitle at the top of a child-setup step.
struct SetupHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold()).foregroundStyle(Theme.obsidian)
            if let subtitle {
                Text(subtitle).foregroundStyle(Theme.systemGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
