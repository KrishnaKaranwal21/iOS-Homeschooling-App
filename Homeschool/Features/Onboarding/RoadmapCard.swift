import SwiftUI

struct RoadmapCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THE NEXT CHAPTER")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.ink)
                .padding(.top, 4)

            Text("One interest.\nSo many directions.")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 28)

            HStack(spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SPACE")
                            .font(.system(size: 26, weight: .medium))
                        Text("Their current obsession")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.ink, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text("STARTING POINT")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                    Text("Level A")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 28)

            ConnectorShape()
                .stroke(Theme.ink.opacity(0.7), lineWidth: 1.5)
                .frame(height: 22)
                .padding(.horizontal, 20)

            HStack {
                Text("Maths").padding(.leading, 6)
                Text("Science").padding(.leading, 28)
                Spacer()
                Circle()
                    .fill(Theme.lime)
                    .frame(width: 34, height: 34)
                    .overlay(Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink))
            }
            .font(.system(size: 18))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Theme.barDark, in: RoundedRectangle(cornerRadius: 14))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}

/// Elbow connector: down from the "SPACE" card, across, down to the bar.
private struct ConnectorShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let startX: CGFloat = 0
        let endX = rect.width - 30
        let midY = rect.midY + 2
        p.move(to: CGPoint(x: startX, y: 0))
        p.addLine(to: CGPoint(x: startX, y: midY))
        p.addLine(to: CGPoint(x: endX, y: midY))
        p.addLine(to: CGPoint(x: endX, y: rect.maxY))
        return p
    }
}
