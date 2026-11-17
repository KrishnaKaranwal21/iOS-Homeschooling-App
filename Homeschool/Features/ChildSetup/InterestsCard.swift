import SwiftUI

// MARK: - Interest

/// An interest a child can have, with its SF Symbol.
struct Interest: Identifiable {
    let name: String
    let symbol: String
    var id: String { name }
}

// MARK: - InterestsCard

/// The interests chooser: a few main interests plus a "more" list.
struct InterestsCard: View {
    @Binding var interests: Set<String>
    @Binding var showMore: Bool

    private let main = [
        Interest(name: "Coding", symbol: "chevron.left.forwardslash.chevron.right"),
        Interest(name: "Animals", symbol: "pawprint"),
        Interest(name: "Art", symbol: "paintpalette"),
        Interest(name: "Music", symbol: "music.note")
    ]
    private let extra = [
        Interest(name: "Space", symbol: "moon.stars"),
        Interest(name: "Nature", symbol: "leaf"),
        Interest(name: "Sports", symbol: "figure.run"),
        Interest(name: "Reading", symbol: "book")
    ]

    private var visible: [Interest] { showMore ? main + extra : main }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PICK WHAT FEELS LIKE THEM")
                .font(.caption2)
                .tracking(0.8)
                .foregroundStyle(Theme.systemGray)
                .frame(maxWidth: .infinity)
            FlowLayout(spacing: 10) {
                ForEach(visible) { item in
                    Button { toggle(item.name) } label: {
                        OutlinedChip(title: item.name, systemImage: item.symbol,
                                     selected: interests.contains(item.name))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(interests.contains(item.name) ? .isSelected : [])
                }
                Button { withAnimation { showMore.toggle() } } label: {
                    OutlinedChip(title: showMore ? "Less" : "More")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .insetCard()
    }

    private func toggle(_ name: String) {
        if interests.contains(name) { interests.remove(name) } else { interests.insert(name) }
    }
}

// MARK: - OutlinedChip

/// An outlined pill used for selectable interests.
struct OutlinedChip: View {
    let title: String
    var systemImage: String? = nil
    var selected = false

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage { Image(systemName: systemImage) }
            Text(title)
            if selected { Image(systemName: "checkmark").font(.footnote.bold()) }
        }
        .foregroundStyle(Theme.obsidian)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(selected ? Theme.pink : Theme.surface, in: .rect(cornerRadius: 20))
        .roundedStroke(selected ? Color(hex: 0xEFB4B4) : Theme.cardBorder, cornerRadius: 20, lineWidth: 1)
    }
}
