import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    private let pages = OnboardingPage.all
    var onFinish: () -> Void = {}

    private var isLast: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip", action: onFinish)
                        .scaledFont(17)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 10)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                PageDots(count: pages.count, current: currentPage)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                PrimaryButton(title: isLast ? "Get started" : "Next") {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut) { currentPage += 1 }
                    }
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
