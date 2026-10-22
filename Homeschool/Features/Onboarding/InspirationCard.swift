import SwiftUI

struct InspirationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("GOOD COMPANY. NEW POSSIBILITIES.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 6)

            VStack(alignment: .leading, spacing: 0) {
                Text("A LITTLE INSPIRATION")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Theme.lime, in: RoundedRectangle(cornerRadius: 8))

                Text("Saturday,\noutside.")
                    .font(.system(size: 46, weight: .bold))
                    .tracking(-1.5)
                    .lineSpacing(-4)
                    .foregroundStyle(Theme.ink)
                    .padding(.top, 18)

                Text("Nature walks. Making things.\nLearning with other families.")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 14)

                Rectangle()
                    .fill(Theme.dotInactive)
                    .frame(height: 1)
                    .padding(.top, 16)

                HStack {
                    Text("DISCOVER  /  JOIN  /  HOST")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 18, weight: .regular))
                }
                .foregroundStyle(Theme.ink)
                .padding(.top, 14)
            }
            .padding(20)
            .background(.white, in: RoundedRectangle(cornerRadius: 28))
            .padding(.top, 20)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
}
