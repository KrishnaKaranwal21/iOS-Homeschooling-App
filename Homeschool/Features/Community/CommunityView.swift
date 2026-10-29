import SwiftUI

private enum CommunityFilter: String, CaseIterable {
    case nearby = "Nearby"
    case similarAges = "Similar ages"
    case sharedInterests = "Shared interests"
}

struct CommunityView: View {
    @Environment(AppState.self) private var state
    @State private var query = ""
    @State private var filter: CommunityFilter = .nearby
    @State private var isRadiusOpen = false

    private var radius: Int { state.communityRadiusKm }

    /// Ages of my children, from their dates of birth.
    private var myAges: [Int] {
        state.children.compactMap { child in child.birthDate.map { AgeRules.age(of: $0, on: .now) } }
    }

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) { $0.formUnion($1.interests) }
    }

    private var parents: [Parent] {
        let nearby = MockData.parents
            .filter { $0.distanceKm <= Double(radius) }
            .sorted { $0.distanceKm < $1.distanceKm }
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = text.isEmpty ? nearby : nearby.filter { $0.searchText.localizedCaseInsensitiveContains(text) }

        switch filter {
        case .nearby:
            return searched
        case .similarAges:
            return searched.filter { parent in
                parent.children.contains { child in myAges.contains { abs($0 - child.age) <= 2 } }
            }
        case .sharedInterests:
            return searched.filter { !myInterests.isDisjoint(with: $0.interests) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                locationBar
                searchField
                filterChips

                Text("Parents around you")
                    .sectionTitle()
                    .padding(.horizontal, 24)
                    .padding(.top, 4)

                if parents.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(parents.enumerated()), id: \.element.id) { index, parent in
                        ParentCard(parent: parent, highlighted: index == 0)
                            .padding(.horizontal, 24)
                    }
                }

                Label("Only approximate distance is shown.", systemImage: "checkmark.shield")
                    .scaledFont(12, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Community")
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: Parent.self) { ConnectView(parent: $0) }
    }

    // MARK: Top of the page

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Community")
                .pageTitle()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)

            NavigationLink { NotificationsView() } label: { bellIcon }
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    private var bellIcon: some View {
        let unread = MockData.notifications.filter(\.isNew).count
        return Image(systemName: "bell")
            .scaledFont(18, weight: .semibold, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Theme.lavender))
            .overlay(alignment: .topTrailing) {
                if unread > 0 {
                    Text("\(unread)")
                        .scaledFont(11, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Circle().fill(Theme.ink))
                }
            }
            .accessibilityLabel(unread > 0 ? "Notifications, \(unread) new" : "Notifications")
    }

    private let radiusOptions = [1, 2, 3, 5, 10, 20]

    /// Pink bar with the distance. Tapping it drops down the other distances.
    private var locationBar: some View {
        Button {
            withAnimation(.snappy) { isRadiusOpen.toggle() }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title3)
                    .foregroundStyle(Theme.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Within \(radius) km of you")
                        .scaledFont(17, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    Text(state.usesLiveLocation
                         ? "Based on your current location"
                         : "Based on \(state.homeLocation.name)")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(Theme.pink, in: .rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Distance: within \(radius) kilometres")
        .accessibilityHint("Choose a different distance")
        .overlay(alignment: .bottom) {
            if isRadiusOpen {
                // Hangs just below the bar and floats over the cards.
                radiusMenu
                    .alignmentGuide(.bottom) { $0[.top] - 8 }
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .padding(.horizontal, 24)
        .zIndex(1)
    }

    private var radiusMenu: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.snappy) { isRadiusOpen = false } } label: {
                HStack {
                    Text("\(radius) km")
                        .scaledFont(17, weight: .semibold, maxScale: 1.3)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                }
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                .background(Theme.pink)
            }
            .buttonStyle(.plain)

            ForEach(radiusOptions.filter { $0 != radius }, id: \.self) { km in
                Button {
                    state.communityRadiusKm = km
                    withAnimation(.snappy) { isRadiusOpen = false }
                } label: {
                    HStack {
                        Text("\(km) km")
                            .scaledFont(17, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.gatherText)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(km) kilometres")
            }

            // The home area itself is still changed in Profile.
            Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1)
            NavigationLink { ProfileView() } label: {
                Label("Change area in Profile", systemImage: "mappin.and.ellipse")
                    .scaledFont(15, weight: .medium, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherAccent)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 24))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 24)
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.gatherText)
            TextField("Search parents or interests", text: $query)
                .scaledFont(16, maxScale: 1.3)
                .submitLabel(.search)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(Theme.chipFill, in: .rect(cornerRadius: 20))
        .padding(.horizontal, 24)
    }

    /// Same look as the category labels on the Gatherings page.
    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(CommunityFilter.allCases, id: \.self) { item in
                    let isSelected = item == filter
                    Button { filter = item } label: {
                        Text(item.rawValue)
                            .scaledFont(15, weight: isSelected ? .semibold : .regular, maxScale: 1.3)
                            .foregroundStyle(isSelected ? Theme.ink : Theme.gatherText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(isSelected ? Theme.lavender : Theme.chipFill))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 24, for: .scrollContent)
        .animation(.snappy, value: filter)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.3")
                .font(.title2)
                .foregroundStyle(Theme.gatherText)
            Text(emptyMessage)
                .rowDetail()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }

    private var emptyMessage: String {
        switch filter {
        case .nearby:
            return "No parents found within \(radius) km. You can widen the distance in Profile › Settings."
        case .similarAges:
            return myAges.isEmpty
                ? "Add your child’s date of birth in their profile to find families with similar ages."
                : "No families with children of a similar age nearby yet."
        case .sharedInterests:
            return myInterests.isEmpty
                ? "Pick your child’s interests in their profile to find families who share them."
                : "No families with shared interests nearby yet."
        }
    }
}

// MARK: - Parent card

struct ParentCard: View {
    @Environment(AppState.self) private var state
    let parent: Parent
    var highlighted = false

    private var requested: Bool { state.requestedParents.contains(parent.id) }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                ParentAvatar(parent: parent, size: 98)

                VStack(alignment: .leading, spacing: 4) {
                    // Name on the left, approximate distance on the right.
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(parent.name)
                            .scaledFont(19, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4)
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                            Text(parent.approxDistance)
                        }
                        .scaledFont(13, maxScale: 1.2)
                        .foregroundStyle(Theme.gatherText)
                        .lineLimit(1)
                    }

                    // Role and intro on the left, the sticky note on the right.
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(parent.role)
                                .scaledFont(14, maxScale: 1.25)
                                .foregroundStyle(Theme.gatherText)
                            Text(parent.about)
                                .scaledFont(14.5, maxScale: 1.25)
                                .foregroundStyle(Theme.gatherText)
                                .lineLimit(3)
                        }
                        Spacer(minLength: 0)
                        StickyNote(text: parent.note)
                    }
                }
            }

            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)

            HStack {
                NavigationLink(value: parent) {
                    HStack(spacing: 8) {
                        Text("View profile")
                        Image(systemName: "arrow.right")
                            .fontWeight(.bold)
                    }
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Color(hex: 0x5A1FD6))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Button { state.sendRequest(to: parent) } label: {
                    Text(requested ? "Requested" : "Connect")
                        .scaledFont(15, weight: .medium, maxScale: 1.25)
                        .foregroundStyle(requested ? Theme.gatherText : Color.white)
                        .padding(.horizontal, 20)
                        .frame(minHeight: 42)
                        .background(Capsule().fill(requested ? Theme.chipFill : Theme.ink))
                }
                .buttonStyle(.plain)
                .disabled(requested)
            }
        }
        .padding(16)
        .background(highlighted ? Color(hex: 0xFDEFF2) : Color.white, in: .rect(cornerRadius: 20))
        .roundedStroke(highlighted ? Theme.pink.opacity(0.5) : Theme.lilacBorder, cornerRadius: 20)
    }
}

/// Round photo, or the first letter of the name when there is no photo in the asset catalog
/// (add an image named like `Parent-Sara` to show a photo).
struct ParentAvatar: View {
    let parent: Parent
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle().fill(Theme.lavender)
            Text(String(parent.name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Image(parent.photoName)
                .resizable()
                .scaledToFill()
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

/// The little yellow note on a parent card.
struct StickyNote: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Handwriting-style font that ships with iOS.
            Text(text)
                .font(.custom("Noteworthy-Light", size: 13, relativeTo: .footnote))
                .foregroundStyle(Theme.ink.opacity(0.9))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Image(systemName: "face.smiling")
                .font(.footnote)
                .foregroundStyle(Theme.ink.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .padding(8)
        .frame(width: 68, height: 72)
        .background(Color(hex: 0xFFF3C4), in: .rect(cornerRadius: 2))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.pink)
                .frame(width: 22, height: 11)
                .offset(x: -6, y: -5)
        }
        .shadow(color: .black.opacity(0.14), radius: 3, y: 2)
        .rotationEffect(.degrees(-4))
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Note: \(text)")
    }
}

// MARK: - Notifications

struct NotificationsView: View {
    @Environment(AppState.self) private var state

    private var sentRequests: [Parent] {
        MockData.parents.filter { state.requestedParents.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications")
                        .pageTitle()
                    Text("Requests and updates from your community.")
                        .pageSubtitle()
                }

                if !sentRequests.isEmpty {
                    Text("Requests you sent")
                        .sectionTitle()
                        .padding(.top, 4)
                    ForEach(sentRequests) { parent in
                        NotificationRow(symbol: "paperplane",
                                        title: "Request sent to \(parent.name)",
                                        detail: "You can chat once \(parent.firstName) accepts.",
                                        time: "Just now", isNew: false)
                    }
                }

                Text("Recent")
                    .sectionTitle()
                    .padding(.top, 4)
                ForEach(MockData.notifications) { item in
                    NotificationRow(symbol: item.symbol, title: item.title,
                                    detail: item.detail, time: item.time, isNew: item.isNew)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NotificationRow: View {
    let symbol: String
    let title: String
    let detail: String
    let time: String
    let isNew: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .scaledFont(17, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.lavender))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).rowTitle()
                Text(detail).rowDetail()
                Text(time)
                    .scaledFont(12, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)

            if isNew {
                Circle()
                    .fill(Theme.gatherAccent)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
                    .accessibilityLabel("New")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: .rect(cornerRadius: 24))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 24)
        .accessibilityElement(children: .combine)
    }
}
