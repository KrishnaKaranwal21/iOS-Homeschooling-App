import SwiftUI

/// Home for a brand-new family: a gentle first week and a swipeable "Explore more" row.
/// It disappears once the family has visited another tab and come back.
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
                }
            }
        }
        .background(Theme.background)
        .toolbarVisibility(isWide ? .visible : .hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFirstWeek) {
            FirstWeekSheet(days: days, hours: state.child.hoursPerDay, tasks: state.tasks)
        }
        .sheet(isPresented: $showIdea) { IdeaPreviewSheet() }
        .fullScreenCover(isPresented: $showAddChild) { AddChildFlow() }
    }

    // MARK: iPad

    /// A roomy single column: the greeting, the first-week card, then the explore cards two to a row.
    private var wideHome: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                topRow
                headline
                firstWeekCard(.regular)
                wideExplore
            }
            .padding(.horizontal, 36)
            .padding(.top, 16)
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
            topRow
            headline
                .padding(.top, compact ? 6 : 8)
            firstWeekCard(density)
                .padding(.top, compact ? 12 : 16)
            exploreSection(density)
                .padding(.top, compact ? 14 : 18)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, compact ? 6 : 10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: Top row and headline

    private var topRow: some View {
        HStack(spacing: 10) {
            Text(dateText)
                .scaledFont(15, maxScale: 1.3)
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 8)

            ChildSwitcherMenu(onAddChild: { showAddChild = true }) {
                HStack(spacing: 7) {
                    AvatarView(initials: String(state.child.displayName.prefix(1)).uppercased(),
                               color: Theme.lavender, size: isWide ? 32 : 26)
                    Text(state.child.displayName)
                        .scaledFont(15, weight: .medium, maxScale: 1.3)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(Theme.ink)
                .padding(.leading, 5)
                .padding(.trailing, 14)
                .frame(height: isWide ? 46 : 36)
                .background(Capsule().fill(Color(hex: 0xEFEDFB)))
            }

            NavigationLink {
                ProfileView()
            } label: {
                Image(systemName: "person")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .frame(width: isWide ? 46 : 36, height: isWide ? 46 : 36)
                    .background(Circle().fill(Color(hex: 0xEFEDFB)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .frame(minHeight: isWide ? 46 : 36)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 4) {
            if isWide {
                Text("A little plan.\nA lighter start.")
                    .scaledFont(40, weight: .heavy, maxScale: 1.15)
                    .tracking(-1.3)
                    .foregroundStyle(Theme.ink)
                    .lineSpacing(-4)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("A little plan.\nA lighter start.")
                    .pageTitle()
                    .lineSpacing(-3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text("Let’s shape \(childName)’s first week.")
                .pageSubtitle()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: First week card

    private func firstWeekCard(_ density: Density) -> some View {
        let compact = density == .compact
        return VStack(alignment: .leading, spacing: isWide ? 16 : (compact ? 6 : 8)) {
            Text("YOUR FIRST WEEK")
                .scaledFont(11, weight: .medium, maxScale: 1.2)
                .tracking(0.5)
                .foregroundStyle(warmText)

            Text(programme)
                .scaledFont(14, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12)
                .frame(height: 26)
                .background(Capsule().fill(Color.white))

            Text("Your chosen rhythm")
                .scaledFont(21, weight: .heavy, maxScale: 1.2)
                .tracking(-0.4)
                .foregroundStyle(Theme.ink)
                .padding(.top, 2)

            rhythmRow(compact: compact)

            Button { showFirstWeek = true } label: {
                Text("Preview first week")
                    .scaledFont(16, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isWide ? 54 : 42)
                    .background(Capsule().fill(Theme.ink))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            Text("Make changes before saving.")
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
            if !isWide {
                Image("HomeMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 138)
                    .offset(x: 3, y: -66)
                    .accessibilityHidden(true)
            }
        }
        // iPad: the mascot sits behind the card and peeks over its top edge, so no cut edge shows.
        .background(alignment: .topTrailing) {
            if isWide {
                Image("HomeMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 176)
                    .offset(x: -28, y: -108)
                    .accessibilityHidden(true)
            }
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
                    .background(Color.white, in: .rect(cornerRadius: 14))
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

// MARK: - Explore cards

/// Where everything sits on one explore card, measured from the design.
/// All numbers are in design pixels on a card that is 2435 wide and 1259 tall, and are scaled to the real card width.
struct ExploreLayout {
    var fill: Color
    var bordered: Bool
    var eyebrowColor: Color
    var bodyColor: Color
    /// Left edge and top of the capital letters, for the small heading.
    var eyebrow: CGPoint
    var title: CGPoint
    var titlePitch: CGFloat
    var body: CGPoint
    var bodyPitch: CGFloat
    var pill: CGRect
    var art: CGRect
    var chip: CGRect? = nil
}

struct ExploreCard: Identifiable {
    enum Action { case findPeople, previewIdea, exploreWorkshops, viewProgress }

    let id: String
    let eyebrow: String
    var chipText: String? = nil
    let titleLines: [String]
    let bodyLines: [String]
    let button: String
    let art: String
    let action: Action
    let layout: ExploreLayout

    private static let lavender = Color(red: 231 / 255, green: 229 / 255, blue: 253 / 255)
    private static let lavenderDeep = Color(red: 229 / 255, green: 227 / 255, blue: 253 / 255)
    private static let grey = Color(red: 241 / 255, green: 242 / 255, blue: 246 / 255)
    private static let slate = Color(red: 116 / 255, green: 122 / 255, blue: 150 / 255)
    private static let mutedLavender = Color(red: 133 / 255, green: 133 / 255, blue: 163 / 255)

    static let all: [ExploreCard] = [
        ExploreCard(
            id: "people", eyebrow: "NEW TO HOMESCHOOLING?",
            titleLines: ["Start alongside someone."],
            bodyLines: ["Meet parents starting out, like you", "or connect with experienced ones."],
            button: "Find my people", art: "ExploreArtPeople", action: .findPeople,
            layout: ExploreLayout(
                fill: lavender, bordered: false, eyebrowColor: slate, bodyColor: slate,
                eyebrow: CGPoint(x: 128, y: 134), title: CGPoint(x: 127, y: 277), titlePitch: 150,
                body: CGPoint(x: 127, y: 522), bodyPitch: 96,
                pill: CGRect(x: 151, y: 883, width: 940, height: 200),
                art: CGRect(x: 1440, y: 250, width: 960, height: 850))),

        ExploreCard(
            id: "idea", eyebrow: "CREATE WITH PURPOSE", chipText: "Art + Maths",
            titleLines: ["Turn a word problem into a", "comic."],
            bodyLines: ["A playful idea to try when you’re ready."],
            button: "Preview Idea", art: "ExploreArtIdea", action: .previewIdea,
            layout: ExploreLayout(
                fill: grey, bordered: true, eyebrowColor: slate, bodyColor: slate,
                eyebrow: CGPoint(x: 107, y: 122), title: CGPoint(x: 106, y: 417), titlePitch: 150,
                body: CGPoint(x: 105, y: 722), bodyPitch: 96,
                pill: CGRect(x: 103, y: 953, width: 940, height: 200),
                art: CGRect(x: 1650, y: 330, width: 750, height: 630),
                chip: CGRect(x: 103, y: 228, width: 546, height: 143))),

        ExploreCard(
            id: "workshops", eyebrow: "FOLLOW THEIR CURIOSITY",
            titleLines: ["Little interests.", "Big discoveries."],
            bodyLines: ["Hands-on workshops for your", "child’s curious side."],
            button: "Explore Workshops", art: "ExploreArtWorkshop", action: .exploreWorkshops,
            layout: ExploreLayout(
                fill: lavenderDeep, bordered: false, eyebrowColor: mutedLavender, bodyColor: mutedLavender,
                eyebrow: CGPoint(x: 144, y: 108), title: CGPoint(x: 147, y: 253), titlePitch: 123,
                body: CGPoint(x: 127, y: 597), bodyPitch: 85,
                pill: CGRect(x: 131, y: 869, width: 1037, height: 204),
                art: CGRect(x: 1380, y: 250, width: 1020, height: 940))),

        ExploreCard(
            id: "progress", eyebrow: "EVERY LITTLE STEP COUNTS",
            titleLines: ["Little steps.", "A growing story."],
            bodyLines: ["Completed activities, learning time", "and little wins, all in one place."],
            button: "View Progress", art: "ExploreArtProgress", action: .viewProgress,
            layout: ExploreLayout(
                fill: grey, bordered: true, eyebrowColor: slate, bodyColor: slate,
                eyebrow: CGPoint(x: 100, y: 122), title: CGPoint(x: 103, y: 308), titlePitch: 150,
                body: CGPoint(x: 100, y: 685), bodyPitch: 96,
                pill: CGRect(x: 97, y: 972, width: 940, height: 200),
                art: CGRect(x: 1540, y: 190, width: 860, height: 960)))
    ]
}

/// Draws one explore card at the same proportions as the design, at any width.
private struct ExploreCardView: View {
    let card: ExploreCard
    let onTap: () -> Void

    private let designWidth: CGFloat = 2435
    private let designHeight: CGFloat = 1259

    // Text sizes from the design, in design pixels.
    private let eyebrowSize: CGFloat = 62
    private let titleSize: CGFloat = 125
    private let bodySize: CGFloat = 85
    private let buttonSize: CGFloat = 88
    private let chipSize: CGFloat = 66

    private let ink = Color(red: 17 / 255, green: 18 / 255, blue: 21 / 255)
    private let pillColor = Color(red: 26 / 255, green: 30 / 255, blue: 27 / 255)
    private let border = Color(red: 213 / 255, green: 210 / 255, blue: 224 / 255)
    private let fold = Color(red: 239 / 255, green: 221 / 255, blue: 223 / 255)
    private let chipPurple = Color(red: 133 / 255, green: 114 / 255, blue: 190 / 255)

    var body: some View {
        Color.clear
            .aspectRatio(designWidth / designHeight, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                    // Built at design size, then scaled to the card's real width below.
                    let s: CGFloat = 1
                    let layout = card.layout
                    let shape: RoundedRectangle = .rect(cornerRadius: 135 * s)

                    ZStack(alignment: .topLeading) {
                        shape.fill(layout.fill)

                        if layout.bordered {
                            // A folded pink corner, like a paper tab.
                            Path { path in
                                path.move(to: CGPoint(x: 2320 * s, y: 0))
                                path.addLine(to: CGPoint(x: 2340 * s, y: 99 * s))
                                path.addLine(to: CGPoint(x: designWidth * s, y: 117 * s))
                                path.addLine(to: CGPoint(x: designWidth * s, y: 0))
                                path.closeSubpath()
                            }
                            .fill(fold)
                            .accessibilityHidden(true)
                        }

                        Image(card.art)
                            .resizable()
                            .frame(width: layout.art.width * s, height: layout.art.height * s)
                            .offset(x: layout.art.minX * s, y: layout.art.minY * s)
                            .accessibilityHidden(true)

                        text(card.eyebrow, size: eyebrowSize, weight: .medium, color: layout.eyebrowColor,
                             at: layout.eyebrow, scale: s)

                        if let chip = layout.chip, let chipText = card.chipText {
                            chipView(chipText, rect: chip, scale: s)
                        }

                        ForEach(Array(card.titleLines.enumerated()), id: \.offset) { index, line in
                            text(line, size: titleSize, weight: .bold, color: ink,
                                 at: CGPoint(x: layout.title.x, y: layout.title.y + CGFloat(index) * layout.titlePitch),
                                 scale: s)
                        }

                        ForEach(Array(card.bodyLines.enumerated()), id: \.offset) { index, line in
                            text(line, size: bodySize, weight: .regular, color: layout.bodyColor,
                                 at: CGPoint(x: layout.body.x, y: layout.body.y + CGFloat(index) * layout.bodyPitch),
                                 scale: s)
                        }

                        pillButton(layout.pill, scale: s)

                        if layout.bordered {
                            shape.strokeBorder(border, lineWidth: 7 * s)
                        }
                    }
                    .frame(width: designWidth, height: designHeight, alignment: .topLeading)
                    .clipShape(shape)
            }
            .visualEffect { content, proxy in
                content.scaleEffect(proxy.size.width / designWidth, anchor: .topLeading)
            }
    }

    /// One line of text. `at.y` is the top of the capital letters, so the line sits where the design puts it.
    /// Lines keep their full size and are never shortened, so every line of a title matches.
    private func text(_ string: String, size: CGFloat, weight: Font.Weight, color: Color,
                      at point: CGPoint, scale s: CGFloat) -> some View {
        Text(string)
            .font(.system(size: size * s, weight: weight))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            // The font's line box starts about a quarter of its size above the capital letters.
            .offset(x: point.x * s, y: (point.y - 0.248 * size) * s)
    }

    /// The pill grows with its text, so the whole label always shows.
    private func chipView(_ string: String, rect: CGRect, scale s: CGFloat) -> some View {
        HStack(spacing: 18 * s) {
            Image(systemName: "paintpalette")
                .font(.system(size: 92 * s))
            Text(string)
                .font(.system(size: chipSize * s))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(chipPurple)
        .padding(.leading, 42 * s)
        .padding(.trailing, 60 * s)
        .frame(height: rect.height * s)
        .background(Capsule().fill(Color.white))
        .fixedSize()
        .offset(x: rect.minX * s, y: rect.minY * s)
    }

    private func pillButton(_ rect: CGRect, scale s: CGFloat) -> some View {
        Button(action: onTap) {
            ZStack {
                Capsule().fill(pillColor)
                Text(card.button)
                    .font(.system(size: buttonSize * s, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 24 * s)
            }
            .frame(width: rect.width * s, height: rect.height * s)
            // The pill is a little under 30 points tall, so the tap area is made larger around it.
            .padding(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(x: rect.minX * s - 8, y: rect.minY * s - 8)
    }
}

// MARK: - Sheets

private struct FirstWeekSheet: View {
    let days: [String]
    let hours: Int
    let tasks: [TaskItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("A light first week. You can change the days and hours before saving.")
                        .scaledFont(16, maxScale: 1.3)
                        .foregroundStyle(Theme.secondary)

                    ForEach(Array(days.enumerated()), id: \.element) { index, day in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(day).scaledFont(20, weight: .bold, maxScale: 1.2)
                                Spacer()
                                Text("\(hours)h").scaledFont(16, weight: .medium, maxScale: 1.2)
                                    .foregroundStyle(Theme.secondary)
                            }
                            ForEach(sample(for: index)) { task in
                                HStack(spacing: 10) {
                                    Image(systemName: "circle").foregroundStyle(Theme.secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Eyebrow(task.subject)
                                        Text(task.title).scaledFont(16, maxScale: 1.3)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white, in: .rect(cornerRadius: 22))
                    }
                }
                .padding(24)
            }
            .background(Theme.background)
            .navigationTitle("Your first week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    /// Two sample activities per day, taken in turn from the task list.
    private func sample(for index: Int) -> [TaskItem] {
        guard !tasks.isEmpty else { return [] }
        return (0..<2).map { tasks[(index * 2 + $0) % tasks.count] }
    }
}

private struct IdeaPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let steps = [
        "Pick one word problem from this week’s algebra practice.",
        "Draw it as three comic panels: who is in it, what happens, and the question.",
        "Solve it in the last panel and let your child read it aloud."
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Art + Maths", systemImage: "paintpalette")
                        .scaledFont(14, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Color(hex: 0x7B5FC0))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.field))

                    Text("Turn a word problem into a comic.")
                        .pageTitle()

                    Image("HomeArtComic")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 170)
                        .accessibilityHidden(true)

                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .scaledFont(14, weight: .bold, maxScale: 1.2)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Theme.lavender))
                            Text(step).scaledFont(16, maxScale: 1.3)
                        }
                    }

                    Button("Got it") { dismiss() }
                        .buttonStyle(.primaryHomeschool)
                        .padding(.top, 8)
                }
                .foregroundStyle(Theme.ink)
                .padding(24)
            }
            .background(Theme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }
}
