import SwiftUI

/// Home for a brand-new family: a gentle first week and a swipeable "Explore more" row.
/// Returning logins and restored sessions use ReturningHomeView; changing tabs alone keeps this first-session introduction.
struct FirstHomeView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab

    @State private var showFirstWeek = false
    @State private var showIdea = false
    @State private var showAddChild = false
    @State private var exploreID: ExploreCard.ID? = ExploreCard.all.first?.id

    private let warmText = Color(hex: 0x9C4A4B)
    private static let weekOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var childName: String {
        let name = state.child.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "your child" : name
    }

    private var days: [String] {
        Self.weekOrder.filter { state.child.learningDays.contains($0) }
    }

    private var programme: String {
        let obeLevels = ["Level A", "Level B", "Level C"]
        let program = obeLevels.contains(state.child.level) ? "\(state.child.curriculum) OBE" : state.child.curriculum
        return state.child.level.isEmpty ? program : "\(program) · \(state.child.level)"
    }

    private var dateText: String {
        let now = Date.now
        let day = Calendar.current.component(.day, from: now)
        return "\(now.formatted(.dateTime.weekday(.wide))), \(now.formatted(.dateTime.month(.wide))) \(day)\(Self.ordinalSuffix(day))"
    }

    private static func ordinalSuffix(_ day: Int) -> String {
        switch day {
        case 11, 12, 13: return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }

    // MARK: Body

    /// How much room the page uses. It shows everything on one screen, and only scrolls on a very small phone.
    private enum Density { case regular, compact }

    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }

    var body: some View {
        Group {
            if isWide {
                wideHome
            } else {
                ViewThatFits(in: .vertical) {
                    page(.regular)
                    page(.compact)
                    ScrollView {
                        page(.regular)
                    }
                    .scrollIndicators(.hidden)
                    .scrollTitleBar("Home")
                }
            }
        }
        .background(Theme.background)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showFirstWeek) {
            FirstWeekView()
        }
        .sheet(isPresented: $showIdea) { IdeaPreviewSheet() }
        .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
    }

    // MARK: iPad

    /// A roomy single column: the greeting, the first-week card, then the explore cards two to a row.
    private var wideHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomePageHeader(dateText: dateText, onAddChild: { showAddChild = true })
                firstWeekSection(.regular)
                wideExplore.padding(.top, 28)
            }
            .padding(.horizontal, TabPageLayout.horizontalInset)
            .padding(.top, TabPageLayout.topInset)
            .padding(.bottom, 44)
            .frame(maxWidth: 880, alignment: .topLeading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }

    private var wideExplore: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Explore more")
                .sectionTitle()
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible())], spacing: 18) {
                ForEach(ExploreCard.all) { card in
                    ExploreCardView(card: card) { perform(card.action) }
                }
            }
        }
    }

    private func page(_ density: Density) -> some View {
        let compact = density == .compact
        return VStack(alignment: .leading, spacing: 0) {
            HomePageHeader(dateText: dateText, onAddChild: { showAddChild = true })
            firstWeekSection(density)
            exploreSection(density)
                .padding(.top, compact ? 14 : 18)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, TabPageLayout.horizontalInset)
        .padding(.top, TabPageLayout.topInset)
        .padding(.bottom, compact ? 6 : 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: First week card

    private func firstWeekSection(_ density: Density) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your week")
                .scaledFont(21, weight: .heavy, maxScale: 1.2).tracking(-0.4)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            firstWeekCard(density)
        }
        .padding(.top, isWide ? 42 : 26)
    }

    private func firstWeekCard(_ density: Density) -> some View {
        let compact = density == .compact
        return VStack(alignment: .leading, spacing: isWide ? 16 : (compact ? 6 : 8)) {

            Text(programme)
                .scaledFont(14, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .frame(height: 26)
                .background(Capsule().fill(Theme.surface))

            rhythmRow(compact: compact)

            Button { showFirstWeek = true } label: {
                Text("Preview first week")
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isWide ? 54 : 42)
                    .background(Capsule().fill(Theme.buttonFill))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            Text("Review your week. Adjust anytime.")
                .scaledFont(13, maxScale: 1.3)
                .foregroundStyle(warmText)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, isWide ? 30 : 18)
        .padding(.top, isWide ? 26 : (compact ? 10 : 12))
        .padding(.bottom, isWide ? 26 : (compact ? 10 : 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.pink, in: .rect(cornerRadius: isWide ? 36 : 28))
        .overlay(alignment: .topTrailing) {
            HomeMascotIllustration()
                .frame(width: isWide ? 156 : 128)
                .alignmentGuide(.top) { $0.height * HomeMascotIllustration.cardEdge }
                .offset(x: isWide ? -28 : -6)
        }
    }

    private func rhythmRow(compact: Bool) -> some View {
        let gap: CGFloat = isWide ? 10 : 4
        let inset: CGFloat = isWide ? 30 : 18

        return ScrollView(.horizontal) {
            HStack(spacing: gap) {
                ForEach(Array(days.enumerated()), id: \.element) { index, day in
                    VStack(spacing: 7) {
                        Text(day.uppercased())
                            .scaledFont(17, weight: .heavy, maxScale: 1.15)
                            .foregroundStyle(Theme.ink)
                        Capsule().fill(Color(hex: 0xF0959F)).frame(width: 22, height: 5)
                        Text("\(state.child.hoursPerDay)h")
                            .scaledFont(14, weight: .medium, maxScale: 1.15)
                            .foregroundStyle(Theme.secondary)
                    }
                    .containerRelativeFrame(.horizontal) { width, _ in
                        tileWidth(in: width, gap: gap, inset: inset)
                    }
                    .frame(height: isWide ? 104 : (compact ? 70 : 76))
                    .background(Theme.surface, in: .rect(cornerRadius: 14))
                    .rotationEffect(.degrees([-3, 2, -2, 3][index % 4]))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(day), \(state.child.hoursPerDay) hours")
                }
            }
            .padding(.vertical, 6)
        }
        // The row runs edge to edge inside the pink box and scrolls without leaving it.
        .contentMargins(.horizontal, inset, for: .scrollContent)
            .scrollIndicators(.hidden)
        .padding(.horizontal, -18)
        .frame(height: compact ? 84 : 90)
    }

    /// Tile width for the day row: fills the row when there are few days, a fixed size when many.
    private func tileWidth(in containerWidth: CGFloat, gap: CGFloat, inset: CGFloat) -> CGFloat {
        let count = CGFloat(max(days.count, 1))
        let fitted = (containerWidth - inset * 2 - gap * (count - 1)) / count
        if isWide { return days.count <= 4 ? min(132, fitted) : min(104, fitted) }
        return days.count <= 4 ? min(82, fitted) : 74
    }

    // MARK: Explore more

    private func exploreSection(_ density: Density) -> some View {
        VStack(alignment: .leading, spacing: density == .compact ? 6 : 8) {
            Text("Explore more")
                .sectionTitle()
                .padding(.horizontal, 4)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(ExploreCard.all) { card in
                        ExploreCardView(card: card) { perform(card.action) }
                            .padding(.horizontal, 4)
                            .containerRelativeFrame(.horizontal)
                            .id(card.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $exploreID)
            .scrollIndicators(.hidden)

            pageDots
        }
    }

    private var pageDots: some View {
        let current = ExploreCard.all.firstIndex { $0.id == exploreID } ?? 0
        return HStack(spacing: 8) {
            ForEach(ExploreCard.all.indices, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.ink : Theme.dotInactive)
                    .frame(width: index == current ? 20 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: current)
        .accessibilityHidden(true)
    }

    private func perform(_ action: ExploreCard.Action) {
        switch action {
        case .findPeople:       openTab(.community)
        case .previewIdea:      showIdea = true
        case .exploreWorkshops: openTab(.gather)
        case .viewProgress:     openTab(.progress)
        }
    }
}
