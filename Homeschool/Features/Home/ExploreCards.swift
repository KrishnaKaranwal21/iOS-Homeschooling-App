import SwiftUI

// MARK: - ExploreLayout

/// Where everything sits on one explore card, measured from the design.
/// All numbers are in design pixels on a card that is 2435 wide and 1259 tall, and are scaled to the real card width.
struct ExploreLayout {
    var fill: Color
    var bordered: Bool
    var eyebrowColor: Color
    var bodyColor: Color
    /// Left edge and top of the capital letters, for the small heading.
    var eyebrow: CGPoint
    var title: CGPoint
    var titlePitch: CGFloat
    var body: CGPoint
    var bodyPitch: CGFloat
    var pill: CGRect
    var art: CGRect
    var chip: CGRect? = nil
}

// MARK: - ExploreCard

struct ExploreCard: Identifiable {
    enum Action { case findPeople, previewIdea, exploreWorkshops, viewProgress }

    let id: String
    let eyebrow: String
    var chipText: String? = nil
    let titleLines: [String]
    let bodyLines: [String]
    let button: String
    let art: String
    let action: Action
    let layout: ExploreLayout

    private static let lavender = Color(hex: 0xE7E5FD)
    private static let lavenderDeep = Color(hex: 0xE5E3FD)
    private static let grey = Color(hex: 0xF1F2F6)
    private static let slate = Color(hex: 0x747A96)
    private static let mutedLavender = Color(hex: 0x8585A3)

    static let all: [ExploreCard] = [
        ExploreCard(
            id: "people", eyebrow: "NEW TO HOMESCHOOLING?",
            titleLines: ["Start alongside someone."],
            bodyLines: ["Meet parents starting out, like you", "or connect with experienced ones."],
            button: "Find my people", art: "ExploreArtPeople", action: .findPeople,
            layout: ExploreLayout(
                fill: lavender, bordered: false, eyebrowColor: slate, bodyColor: slate,
                eyebrow: CGPoint(x: 128, y: 134), title: CGPoint(x: 127, y: 277), titlePitch: 150,
                body: CGPoint(x: 127, y: 522), bodyPitch: 96,
                pill: CGRect(x: 151, y: 883, width: 940, height: 200),
                art: CGRect(x: 1440, y: 250, width: 960, height: 850))),

        ExploreCard(
            id: "idea", eyebrow: "CREATE WITH PURPOSE", chipText: "Art + Maths",
            titleLines: ["Turn a word problem into a", "comic."],
            bodyLines: ["A playful idea to try when you’re ready."],
            button: "Preview Idea", art: "ExploreArtIdea", action: .previewIdea,
            layout: ExploreLayout(
                fill: grey, bordered: true, eyebrowColor: slate, bodyColor: slate,
                eyebrow: CGPoint(x: 107, y: 122), title: CGPoint(x: 106, y: 417), titlePitch: 150,
                body: CGPoint(x: 105, y: 722), bodyPitch: 96,
                pill: CGRect(x: 103, y: 953, width: 940, height: 200),
                art: CGRect(x: 1650, y: 330, width: 750, height: 630),
                chip: CGRect(x: 103, y: 228, width: 546, height: 143))),

        ExploreCard(
            id: "workshops", eyebrow: "FOLLOW THEIR CURIOSITY",
            titleLines: ["Little interests.", "Big discoveries."],
            bodyLines: ["Hands-on workshops for your", "child’s curious side."],
            button: "Explore Workshops", art: "ExploreArtWorkshop", action: .exploreWorkshops,
            layout: ExploreLayout(
                fill: lavenderDeep, bordered: false, eyebrowColor: mutedLavender, bodyColor: mutedLavender,
                eyebrow: CGPoint(x: 144, y: 108), title: CGPoint(x: 147, y: 253), titlePitch: 123,
                body: CGPoint(x: 127, y: 597), bodyPitch: 85,
                pill: CGRect(x: 131, y: 869, width: 1037, height: 204),
                art: CGRect(x: 1380, y: 250, width: 1020, height: 940))),

        ExploreCard(
            id: "progress", eyebrow: "EVERY LITTLE STEP COUNTS",
            titleLines: ["Little steps.", "A growing story."],
            bodyLines: ["Completed activities, learning time", "and little wins, all in one place."],
            button: "View Progress", art: "ExploreArtProgress", action: .viewProgress,
            layout: ExploreLayout(
                fill: grey, bordered: true, eyebrowColor: slate, bodyColor: slate,
                eyebrow: CGPoint(x: 100, y: 122), title: CGPoint(x: 103, y: 308), titlePitch: 150,
                body: CGPoint(x: 100, y: 685), bodyPitch: 96,
                pill: CGRect(x: 97, y: 972, width: 940, height: 200),
                art: CGRect(x: 1540, y: 190, width: 860, height: 960)))
    ]
}

// MARK: - ExploreCardView

/// Draws one explore card at the same proportions as the design, at any width.
struct ExploreCardView: View {
    let card: ExploreCard
    let onTap: () -> Void

    private var artwork: String { card.art }

    private let designWidth: CGFloat = 2435
    private let designHeight: CGFloat = 1259

    /// Text sizes from the design, in design pixels.
    private let eyebrowSize: CGFloat = 62
    private let titleSize: CGFloat = 125
    private let bodySize: CGFloat = 85
    private let buttonSize: CGFloat = 88
    private let chipSize: CGFloat = 66

    private let ink = Color(hex: 0x111215)
    private let pillColor = Color(hex: 0x1A1E1B)
    private let border = Color(hex: 0xD5D2E0)
    private let fold = Color(hex: 0xEFDDDF)
    private let chipPurple = Color(hex: 0x8572BE)

    var body: some View {
        Color.clear
            .aspectRatio(designWidth / designHeight, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                    // Built at design size, then scaled to the card's real width below.
                    let s: CGFloat = 1
                    let layout = card.layout
                    let shape: RoundedRectangle = .rect(cornerRadius: 135 * s)

                    ZStack(alignment: .topLeading) {
                        shape.fill(layout.fill)

                        if layout.bordered {
                            // A folded pink corner, like a paper tab.
                            Path { path in
                                path.move(to: CGPoint(x: 2320 * s, y: 0))
                                path.addLine(to: CGPoint(x: 2340 * s, y: 99 * s))
                                path.addLine(to: CGPoint(x: designWidth * s, y: 117 * s))
                                path.addLine(to: CGPoint(x: designWidth * s, y: 0))
                                path.closeSubpath()
                            }
                            .fill(fold)
                            .accessibilityHidden(true)
                        }

                        Image(artwork)
                            .resizable()
                            .scaledToFit()
                            .frame(width: layout.art.width * s, height: layout.art.height * s)
                            .offset(x: layout.art.minX * s, y: layout.art.minY * s)
                            .accessibilityHidden(true)

                        text(card.eyebrow, size: eyebrowSize, weight: .medium, color: layout.eyebrowColor,
                             at: layout.eyebrow, scale: s)

                        if let chip = layout.chip, let chipText = card.chipText {
                            chipView(chipText, rect: chip, scale: s)
                        }

                        ForEach(Array(card.titleLines.enumerated()), id: \.offset) { index, line in
                            text(line, size: titleSize, weight: .bold, color: ink,
                                 at: CGPoint(x: layout.title.x, y: layout.title.y + CGFloat(index) * layout.titlePitch),
                                 scale: s)
                        }

                        ForEach(Array(card.bodyLines.enumerated()), id: \.offset) { index, line in
                            text(line, size: bodySize, weight: .regular, color: layout.bodyColor,
                                 at: CGPoint(x: layout.body.x, y: layout.body.y + CGFloat(index) * layout.bodyPitch),
                                 scale: s)
                        }

                        pillButton(layout.pill, scale: s)

                        if layout.bordered {
                            shape.strokeBorder(border, lineWidth: 7 * s)
                        }
                    }
                    .frame(width: designWidth, height: designHeight, alignment: .topLeading)
                    .clipShape(shape)
            }
            .visualEffect { content, proxy in
                content.scaleEffect(proxy.size.width / designWidth, anchor: .topLeading)
            }
    }

    /// One line of text. `at.y` is the top of the capital letters, so the line sits where the design puts it.
    /// Lines keep their full size and are never shortened, so every line of a title matches.
    private func text(_ string: String, size: CGFloat, weight: Font.Weight, color: Color,
                      at point: CGPoint, scale s: CGFloat) -> some View {
        Text(string)
            .font(.system(size: size * s, weight: weight))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            // The font's line box starts about a quarter of its size above the capital letters.
            .offset(x: point.x * s, y: (point.y - 0.248 * size) * s)
    }

    /// The pill grows with its text, so the whole label always shows.
    private func chipView(_ string: String, rect: CGRect, scale s: CGFloat) -> some View {
        HStack(spacing: 18 * s) {
            Image(systemName: "paintpalette")
                .font(.system(size: 92 * s))
            Text(string)
                .font(.system(size: chipSize * s))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(chipPurple)
        .padding(.leading, 42 * s)
        .padding(.trailing, 60 * s)
        .frame(height: rect.height * s)
        .background(Capsule().fill(Theme.surface))
        .fixedSize()
        .offset(x: rect.minX * s, y: rect.minY * s)
    }

    private func pillButton(_ rect: CGRect, scale s: CGFloat) -> some View {
        Button(action: onTap) {
            ZStack {
                Capsule().fill(pillColor)
                Text(card.button)
                    .font(.system(size: buttonSize * s, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24 * s)
            }
            .frame(width: rect.width * s, height: rect.height * s)
            // The pill is a little under 30 points tall, so the tap area is made larger around it.
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: rect.minX * s - 8, y: rect.minY * s - 8)
    }
}

// MARK: - IdeaPreviewSheet

struct IdeaPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        "Pick one word problem from this week’s algebra practice.",
        "Draw it as three comic panels: who is in it, what happens, and the question.",
        "Solve it in the last panel and let your child read it aloud."
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Art + Maths", systemImage: "paintpalette")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.field))

                    Text("Turn a word problem into a comic.")
                        .pageTitle()

                    Image("HomeArtComic")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 170)
                        .accessibilityHidden(true)

                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .scaledFont(14, weight: .bold, maxScale: 1.2)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Theme.lavender))
                            Text(step).scaledFont(16, maxScale: 1.3)
                        }
                    }

                    Button("Got it") { dismiss() }
                        .buttonStyle(.primaryHomeschool)
                        .padding(.top, 8)
                }
                .foregroundStyle(Theme.ink)
                .padding(24)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}
