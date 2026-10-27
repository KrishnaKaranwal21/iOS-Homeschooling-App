import SwiftUI

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
            .background(.white, in: Capsule())
            .padding(.leading, 28)
            .padding(.top, 24)

            Text("“Same here” parents")
                .scaledFont(16, maxScale: 1.15)
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Theme.ink, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 22)
    }
}

private struct SmileyFace: View {
    var body: some View {
        Circle()
            .fill(Theme.ink)
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

private struct SmilePath: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 1.6))
        return p
    }
}
