import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    private let pages = OnboardingPage.all
    var onFinish: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, 16)

                PageDots(count: pages.count, current: currentPage)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                Button(action: onFinish) {
                    HStack {
                        Text("Get started")
                            .font(.system(size: 20, weight: .medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .regular))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 64)
                    .background(Theme.ink, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
}

struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Theme.ink : Theme.dotInactive)
                    .frame(width: i == current ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.25), value: current)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

#Preview {
    OnboardingView()
}
