import SwiftUI

struct OnboardingView: View {
    @State private var scrolledPage: Int? = 0
    private let pages = OnboardingPage.all
    var onFinish: () -> Void = {}

    private var currentPage: Int { scrolledPage ?? 0 }
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

                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(page: page)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollPosition(id: $scrolledPage)

                PageDots(count: pages.count, current: currentPage)
                    .padding(.top, 8)
                    .padding(.bottom, 28)

                Button(isLast ? "Get started" : "Next") {
                    if isLast {
                        onFinish()
                    } else {
                        withAnimation(.easeInOut) { scrolledPage = currentPage + 1 }
                    }
                }
                .buttonStyle(.primaryHomeschool)
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
