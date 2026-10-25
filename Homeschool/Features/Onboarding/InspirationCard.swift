import SwiftUI

/// Page 3 card: the inspiration text sits straight on the lavender card.
struct InspirationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A LITTLE INSPIRATION")
                .scaledFont(12, weight: .medium, maxScale: 1.15)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color(hex: 0xFFC8C9), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text("Saturday,\noutside.")
                .scaledFont(40, weight: .heavy, maxScale: 1.15)
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
