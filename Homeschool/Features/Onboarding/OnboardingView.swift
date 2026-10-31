import SwiftUI

struct OnboardingView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }

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

                // Paging carousel: each page is exactly as wide as the screen. The scroll view itself
                // takes all the height between the Skip button and the dots, and the page fills it.
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            OnboardingPageView(page: page)
                                .containerRelativeFrame(.horizontal)
                                // Phone: the page starts at the top. Wide screens: it sits in the middle.
                                .frame(maxHeight: .infinity, alignment: isWide ? .center : .top)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
                .scrollPosition(id: $scrolledPage)
                .frame(maxHeight: .infinity)

                PageDots(count: pages.count, current: currentPage, centered: isWide)
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
                .frame(maxWidth: isWide ? 400 : .infinity)
                .padding(.horizontal, 24)
                .padding(.bottom, isWide ? 28 : 16)
            }
        }
    }
}

struct PageDots: View {
    let count: Int
    let current: Int
    /// Centred on wide screens. On iPhone the dots stay on the left, as designed.
    var centered = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? Theme.ink : Theme.dotInactive)
                    .frame(width: i == current ? 22 : 7, height: 7)
                    .animation(.easeInOut(duration: 0.25), value: current)
            }
            if !centered { Spacer() }
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .padding(.horizontal, 28)
    }
}

#Preview {
    OnboardingView()
}
