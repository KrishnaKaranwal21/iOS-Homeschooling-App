import SwiftUI

// MARK: - CommunityCard

struct CommunityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A little less solo.")
                .scaledFont(28, weight: .bold, maxScale: 1.15)
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)

            HStack {
                SmileyFace()
                Spacer()
                Circle().fill(Color(hex: 0xFFC8C9))
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: "bubble.left.and.bubble.right")
                        .scaledFont(24, maxScale: 1.15)
                        .foregroundStyle(Theme.ink))
                Spacer()
                Circle().fill(Theme.coral)
                    .frame(width: 54, height: 54)
                    .overlay(Image(systemName: "heart")
                        .scaledFont(22, maxScale: 1.15)
                        .foregroundStyle(Theme.ink))
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)

            HStack(spacing: 10) {
                Image(systemName: "leaf")
                    .scaledFont(15, maxScale: 1.15)
                Text("Nature-walk people")
                    .scaledFont(16, maxScale: 1.15)
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Theme.surface, in: Capsule())
            .padding(.leading, 28)
            .padding(.top, 24)

            Text("“Same here” parents")
                .scaledFont(16, maxScale: 1.15)
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Theme.buttonFill, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 22)
    }
}

// MARK: - SmileyFace

struct SmileyFace: View {
    var body: some View {
        Circle()
            .fill(Theme.buttonFill)
            .frame(width: 54, height: 54)
            .overlay(
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Circle().fill(.white).frame(width: 11, height: 11)
                        Circle().fill(.white).frame(width: 11, height: 11)
                    }
                    SmilePath()
                        .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 24, height: 8)
                }
                .offset(y: -1)
            )
    }
}

// MARK: - SmilePath

struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return p
    }
}

// MARK: - InspirationCard

/// Page 3 card: the inspiration text sits straight on the lavender card.
struct InspirationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A LITTLE INSPIRATION")
                .scaledFont(12, weight: .medium, maxScale: 1.15)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(hex: 0xFFC8C9), in: .rect(cornerRadius: 8))

            Text("Saturday,\noutside.")
                .scaledFont(40, weight: .bold, maxScale: 1.15)
                .tracking(-1.4)
                .lineSpacing(-6)
                .foregroundStyle(Theme.ink)
                .padding(.top, 14)

            Text("Nature walks. Making things.\nLearning with other families.")
                .scaledFont(16, maxScale: 1.15)
                .foregroundStyle(Theme.ink)
                .padding(.top, 10)

            Spacer(minLength: 12)

            Rectangle()
                .fill(Theme.ink.opacity(0.5))
                .frame(height: 1)

            HStack {
                Text("DISCOVER  /  JOIN  /  HOST")
                    .scaledFont(13, weight: .medium, maxScale: 1.15)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .scaledFont(18, maxScale: 1.15)
            }
            .foregroundStyle(Theme.ink)
            .padding(.top, 14)
        }
        .padding(.horizontal, 26)
        .padding(.top, 24)
        .padding(.bottom, 22)
    }
}

// MARK: - RoadmapCard

/// Page 1 card: "One interest. So many directions." with the interest and starting point
/// joined by a bracket to a pink arrow.
struct RoadmapCard: View {
    private let diagramWidth: CGFloat = 285
    private let diagramHeight: CGFloat = 142

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("One interest.\nSo many directions.")
                .scaledFont(28, weight: .bold, maxScale: 1.15)
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)

            Spacer(minLength: 16)

            // Shrinks a little on narrow phones instead of overflowing the card.
            Color.clear
                .frame(height: diagramHeight)
                .overlay(alignment: .topLeading) { diagram }
                .visualEffect { content, proxy in
                    content.scaleEffect(min(1, proxy.size.width / diagramWidth), anchor: .topLeading)
                }
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 22)
    }

    private var diagram: some View {
        ZStack(alignment: .topLeading) {
            // Bracket: black chip and white chip meet on the right, then run to the arrow.
            Path { p in
                p.move(to: CGPoint(x: 192, y: 32))
                p.addLine(to: CGPoint(x: 232, y: 32))
                p.addLine(to: CGPoint(x: 232, y: 110))
                p.addLine(to: CGPoint(x: 114, y: 110))
                p.move(to: CGPoint(x: 232, y: 71))
                p.addLine(to: CGPoint(x: 254, y: 71))
            }
            .stroke(Theme.ink.opacity(0.7), lineWidth: 1.5)

            interestChip
                .frame(width: 192, height: 64)

            startChip
                .frame(width: 114, height: 64)
                .offset(y: 78)

            Circle()
                .fill(Color(hex: 0xFFC8C9))
                .frame(width: 32, height: 32)
                .overlay(Image(systemName: "arrow.right")
                    .scaledFont(13, weight: .semibold, maxScale: 1.15)
                    .foregroundStyle(Theme.ink))
                .offset(x: 253, y: 55)
        }
        .frame(width: diagramWidth, height: diagramHeight, alignment: .topLeading)
    }

    private var interestChip: some View {
        HStack(spacing: 10) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .scaledFont(17, maxScale: 1.15)
            VStack(alignment: .leading, spacing: 2) {
                Text("Their current obsession")
                    .scaledFont(10, maxScale: 1.15)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("CODING")
                    .scaledFont(22, weight: .medium, maxScale: 1.15)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.buttonFill, in: .rect(cornerRadius: 12))
    }

    private var startChip: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("STARTING POINT")
                .scaledFont(9, maxScale: 1.15)
                .foregroundStyle(Theme.muted)
            Text("Grade 10")
                .scaledFont(22, maxScale: 1.15)
                .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.surface, in: .rect(cornerRadius: 12))
    }
}
