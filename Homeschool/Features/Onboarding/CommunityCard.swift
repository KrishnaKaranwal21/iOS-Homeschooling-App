import SwiftUI

struct CommunityCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FIND YOUR COMMON GROUND")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.ink)

            Text("A little less solo.")
                .font(.system(size: 28, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 22)

            HStack {
                SmileyFace()
                Spacer()
                Circle().fill(Color(hex: 0xFFC8C9))
                    .frame(width: 58, height: 58)
                    .overlay(Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.ink))
                Spacer()
                Circle().fill(Theme.coral)
                    .frame(width: 58, height: 58)
                    .overlay(Image(systemName: "heart")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.ink))
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)

            HStack(spacing: 10) {
                Image(systemName: "leaf")
                    .font(.system(size: 15))
                Text("Nature-walk people")
                    .font(.system(size: 16))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.white, in: Capsule())
            .padding(.leading, 28)
            .padding(.top, 24)

            Text("“Same here” parents")
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(Theme.ink, in: Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}

private struct SmileyFace: View {
    var body: some View {
        Circle()
            .fill(Theme.ink)
            .frame(width: 58, height: 58)
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
