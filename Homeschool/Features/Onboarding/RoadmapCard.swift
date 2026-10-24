import SwiftUI

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
            GeometryReader { geo in
                diagram
                    .scaleEffect(min(1, geo.size.width / diagramWidth), anchor: .topLeading)
            }
            .frame(height: diagramHeight)
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
        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
