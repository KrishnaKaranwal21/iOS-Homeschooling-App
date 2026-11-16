import SwiftUI

// MARK: - ProfileHeroChip

struct ProfileHeroChip: Identifiable {
    let id = UUID()
    let symbol: String
    let text: String
}

// MARK: - ProfileHero

/// The big lavender card at the top of a profile: avatar, name, a line of detail, small facts, and the mascot.
struct ProfileHero: View {
    let initial: String
    /// Name of a photo in the asset catalog. Without it the initial is shown.
    var photoName: String? = nil
    let title: String
    let subtitle: String
    var chips: [ProfileHeroChip] = []
    /// A round button in the corner, such as "Edit".
    var actionSymbol: String? = nil
    var actionLabel = ""
    var action: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                avatar
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .scaledFont(26, weight: .heavy, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    if !subtitle.isEmpty {
                        // One line: a long email shrinks a little or is cut in the middle, never wrapped.
                        Text(subtitle)
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 0)
            }

            if !chips.isEmpty || actionSymbol != nil {
                FlowLayout(spacing: 8) {
                    ForEach(chips) { chip in
                        HStack(spacing: 6) {
                            Image(systemName: chip.symbol)
                            Text(chip.text)
                        }
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.chipFill))
                    }
                    if let actionSymbol {
                        Button(action: action) {
                            HStack(spacing: 6) {
                                Image(systemName: actionSymbol)
                                Text(actionLabel)
                            }
                            .scaledFont(13, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Theme.buttonFill))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 80)   // room for the mascot
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
        .background(Theme.surface, in: .rect(cornerRadius: 28))
        .overlay(alignment: .bottomTrailing) {
            HomeMascotView()
                .frame(width: 76)
                .padding(.trailing, 14)
                .accessibilityHidden(true)
        }
        .clipShape(.rect(cornerRadius: 28))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 28)
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Theme.pink)
            Text(initial)
                .scaledFont(36, weight: .bold)
                .foregroundStyle(Theme.ink)
            if let photoName {
                Image(photoName).resizable().scaledToFill()
            }
        }
        .frame(width: 84, height: 84)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

// MARK: - ProfileCard

/// A white rounded card with an optional icon and heading.
struct ProfileCard<Content: View>: View {
    var symbol: String? = nil
    var title: String? = nil
    var subtitle: String? = nil
    var background: Color = Theme.surface
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title {
                HStack(spacing: 12) {
                    if let symbol {
                        Image(systemName: symbol)
                            .scaledFont(15, weight: .semibold)
                            .foregroundStyle(Theme.gatherAccent)
                            .frame(width: 34, height: 34)
                            .background(Theme.lilac, in: .rect(cornerRadius: 11))
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .scaledFont(19, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        if let subtitle {
                            Text(subtitle)
                                .scaledFont(13, maxScale: 1.3)
                                .foregroundStyle(Theme.gatherText)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .rect(cornerRadius: 26))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
    }
}

// MARK: - ProfileInfoRow

/// One line inside a card: icon, title, value, and a chevron when it can be tapped.
struct ProfileInfoRow: View {
    let symbol: String
    let title: String
    let value: String
    var showsChevron = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .scaledFont(14, weight: .semibold)
                .foregroundStyle(Theme.gatherAccent)
                .frame(width: 32, height: 32)
                .background(Theme.lilac, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(title)
                .scaledFont(16, maxScale: 1.25)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 8)
            Text(value)
                .scaledFont(15, maxScale: 1.25)
                .foregroundStyle(Theme.gatherText)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
            if showsChevron {
                Image(systemName: "chevron.right").accessibilityHidden(true)
                    .scaledFont(12, weight: .semibold)
                    .foregroundStyle(Theme.dotInactive)
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - SelectableChip

/// A pill that can be switched on and off (interests, what to connect for, distances).
struct SelectableChip: View {
    let title: String
    let isOn: Bool
    var symbol: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isOn {
                    Image(systemName: "checkmark").scaledFont(11, weight: .bold)
                } else if let symbol {
                    Image(systemName: symbol).scaledFont(12)
                }
                Text(title)
            }
            .scaledFont(15, weight: isOn ? .semibold : .regular, maxScale: 1.25)
            .foregroundStyle(isOn ? Theme.ink : Theme.gatherText)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(isOn ? Theme.lavender : Theme.chipFill))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - InfoChip

/// A chip that only shows something (not tappable).
struct InfoChip: View {
    let title: String
    var tint: Color = Theme.lavender
    var isCompact = false
    /// A small icon in front of the title, for example to mark what you have in common.
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
            }
            Text(title)
        }
        .scaledFont(isCompact ? 13 : 15, weight: .medium, maxScale: 1.25)
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, isCompact ? 11 : 14)
        .padding(.vertical, isCompact ? 6 : 9)
        .background(Capsule().fill(tint))
    }
}

// MARK: - ProfileStatsCard

/// A row of numbers, such as children, registrations and saved events.
struct ProfileStatsCard: View {
    struct Item { let value: String; let label: String }
    let items: [Item]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    Text(item.value)
                        .scaledFont(24, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                    Text(item.label)
                        .scaledFont(12, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                if index < items.count - 1 {
                    Rectangle().fill(Theme.ink.opacity(0.06)).frame(width: 1, height: 36)
                }
            }
        }
        .padding(.vertical, 16)
        .background(Theme.surface, in: .rect(cornerRadius: 26))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - ProfileDivider

struct ProfileDivider: View {
    var body: some View {
        Rectangle().fill(Theme.ink.opacity(0.06)).frame(height: 1)
    }
}

// MARK: - AdaptiveColumn

/// On a wide screen (iPad, or a large iPhone turned sideways) the app stays in a centred column,
/// so cards and text keep a comfortable width instead of stretching across the whole display.
/// On a compact width nothing changes.
struct AdaptiveColumn: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: sizeClass == .regular ? maxWidth : .infinity)
            .frame(maxWidth: .infinity)
            .background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - View extensions

extension View {
    func adaptiveColumn(maxWidth: CGFloat = 880) -> some View {
        modifier(AdaptiveColumn(maxWidth: maxWidth))
    }
}
