import SwiftUI

/// Home for a brand-new family: a gentle first week and a swipeable "Explore more" row.
/// It disappears once the family has visited another tab and come back.
struct FirstHomeView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab

    @State private var showFirstWeek = false
    @State private var showIdea = false
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
        return "\(now.formatted(.dateTime.month(.wide))) \(day)\(Self.ordinalSuffix(day))"
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                topRow
                headline
                firstWeekCard
                exploreSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFirstWeek) {
            FirstWeekSheet(days: days, hours: state.child.hoursPerDay, tasks: state.tasks)
        }
        .sheet(isPresented: $showIdea) { IdeaPreviewSheet() }
    }

    // MARK: Top row and headline

    private var topRow: some View {
        HStack(spacing: 12) {
            Text(dateText)
                .scaledFont(17, maxScale: 1.3)
                .foregroundStyle(Theme.secondary)
            Spacer(minLength: 8)

            Menu {
                Text(childName)
            } label: {
                HStack(spacing: 8) {
                    AvatarView(initials: String(state.child.name.prefix(1)).uppercased(),
                               color: Theme.lavender, size: 30)
                    Text(state.child.name.isEmpty ? "Child" : state.child.name)
                        .scaledFont(17, weight: .medium, maxScale: 1.3)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Theme.ink)
                .padding(.leading, 6)
                .padding(.trailing, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(hex: 0xEFEDFB)))
            }

            Button {} label: {
                Image(systemName: "person")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(Color(hex: 0xEFEDFB)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A little plan.\nA lighter start.")
                .scaledFont(40, weight: .heavy, maxScale: 1.15)
                .tracking(-1.4)
                .lineSpacing(-4)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Let’s shape \(childName)’s first week.")
                .scaledFont(17, maxScale: 1.3)
                .foregroundStyle(Theme.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: First week card

    private var firstWeekCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("YOUR FIRST WEEK")
                .scaledFont(12, weight: .medium, maxScale: 1.2)
                .tracking(0.6)
                .foregroundStyle(warmText)

            Text(programme)
                .scaledFont(15, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))

            Text("Your chosen rhythm")
                .scaledFont(24, weight: .heavy, maxScale: 1.2)
                .tracking(-0.5)
                .foregroundStyle(Theme.ink)
                .padding(.top, 2)

            rhythmRow

            PrimaryButton(title: "Preview first week") { showFirstWeek = true }

            Text("Make changes before saving.")
                .scaledFont(14, maxScale: 1.3)
                .foregroundStyle(warmText)
                .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.pink))
        .overlay(alignment: .topTrailing) {
            Image("HomeMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 128)
                .offset(x: 4, y: -98)
                .accessibilityHidden(true)
        }
        .padding(.top, 70)
    }

    private var rhythmRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(days.enumerated()), id: \.element) { index, day in
                    VStack(spacing: 8) {
                        Text(day.uppercased())
                            .scaledFont(17, weight: .heavy, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        Capsule().fill(Color(hex: 0xF0959F)).frame(width: 26, height: 6)
                        Text("\(state.child.hoursPerDay)h")
                            .scaledFont(15, weight: .medium, maxScale: 1.2)
                            .foregroundStyle(Theme.secondary)
                    }
                    .frame(width: 70, height: 96)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                    .rotationEffect(.degrees([-3, 2, -2, 3][index % 4]))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(day), \(state.child.hoursPerDay) hours")
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    // MARK: Explore more

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Explore more")
                .scaledFont(28, weight: .heavy, maxScale: 1.2)
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 16) {
                    ForEach(ExploreCard.all) { card in
                        ExploreCardView(card: card) { perform(card.action) }
                            .containerRelativeFrame(.horizontal)
                            .id(card.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $exploreID)
            .scrollIndicators(.hidden)

            pageDots
        }
    }

    private var pageDots: some View {
        let current = ExploreCard.all.firstIndex { $0.id == exploreID } ?? 0
        return HStack(spacing: 10) {
            ForEach(ExploreCard.all.indices, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Theme.ink : Theme.dotInactive)
                    .frame(width: index == current ? 22 : 7, height: 7)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: current)
        .accessibilityHidden(true)
    }

    private func perform(_ action: ExploreCard.Action) {
        switch action {
        case .findPeople:      openTab(.community)
        case .previewIdea:     showIdea = true
        case .exploreWorkshops: openTab(.gather)
        case .viewProgress:    openTab(.progress)
        }
    }
}

// MARK: - Explore cards

struct ExploreCard: Identifiable {
    enum Action { case findPeople, previewIdea, exploreWorkshops, viewProgress }
    enum Style { case lavender, grey }

    let id: String
    let eyebrow: String
    var chip: (symbol: String, text: String)? = nil
    let title: String
    let body: String
    let button: String
    let art: String
    let style: Style
    let action: Action

    static let all: [ExploreCard] = [
        ExploreCard(id: "people", eyebrow: "NEW TO HOMESCHOOLING?",
                    title: "Start alongside someone.",
                    body: "Meet parents starting out, like you or connect with experienced ones.",
                    button: "Find my people", art: "HomeArtPeople", style: .lavender, action: .findPeople),
        ExploreCard(id: "idea", eyebrow: "CREATE WITH PURPOSE",
                    chip: ("paintpalette", "Art + Maths"),
                    title: "Turn a word problem into a comic.",
                    body: "A fresh take on this week’s algebra practice.",
                    button: "Preview Idea", art: "HomeArtComic", style: .grey, action: .previewIdea),
        ExploreCard(id: "workshops", eyebrow: "FOLLOW THEIR CURIOSITY",
                    title: "Little interests.\nBig discoveries.",
                    body: "Hands-on workshops for your child’s curious side.",
                    button: "Explore Workshops", art: "HomeArtWorkshop", style: .lavender, action: .exploreWorkshops),
        ExploreCard(id: "progress", eyebrow: "EVERY LITTLE STEP COUNTS",
                    title: "Little steps.\nA growing story.",
                    body: "Completed activities, learning time and little wins, all in one place.",
                    button: "View Progress", art: "HomeArtProgress", style: .grey, action: .viewProgress)
    ]
}

private struct ExploreCardView: View {
    let card: ExploreCard
    let onTap: () -> Void

    private var fill: Color {
        card.style == .lavender ? Color(hex: 0xE6E1FF) : Color(hex: 0xF0F1F6)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 30, style: .continuous).fill(fill)
                if card.style == .grey {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color(hex: 0xD9D6E5), lineWidth: 1.5)
                    // Folded pink corner, like a paper tab.
                    Path { path in
                        path.move(to: CGPoint(x: geo.size.width - 40, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width - 14, y: 0))
                        path.addLine(to: CGPoint(x: geo.size.width, y: 22))
                        path.closeSubpath()
                    }
                    .fill(Theme.pink.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                }

                Image(card.art)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.38)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .padding(.trailing, 14)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(card.eyebrow)
                        .scaledFont(11, weight: .medium, maxScale: 1.2)
                        .tracking(0.6)
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let chip = card.chip {
                        Label(chip.text, systemImage: chip.symbol)
                            .scaledFont(13, weight: .medium, maxScale: 1.2)
                            .foregroundStyle(Color(hex: 0x7B5FC0))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white))
                    }

                    Text(card.title)
                        .scaledFont(22, weight: .heavy, maxScale: 1.15)
                        .tracking(-0.6)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(card.body)
                        .scaledFont(14, maxScale: 1.2)
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 4)

                    Button(action: onTap) {
                        Text(card.button)
                            .scaledFont(15, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Color.white)
                            .padding(.horizontal, 20)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(Theme.ink))
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: geo.size.width * 0.62, alignment: .leading)
                .padding(20)
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(height: 300)
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
                        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))
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
                        .scaledFont(30, weight: .heavy, maxScale: 1.15)
                        .tracking(-0.8)

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

                    PrimaryButton(title: "Got it") { dismiss() }
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
