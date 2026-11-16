import SwiftUI

/// The ways the Community list can be narrowed.
enum CommunityFilter: String, CaseIterable {
    case nearby = "Nearby"
    case similarAges = "Similar ages"
    case sharedInterests = "Shared interests"
}

/// The Community tab: search and filter nearby families and send connection requests.
struct CommunityView: View {
    @Environment(AppState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var isWide: Bool { sizeClass == .regular }
    private var pageInset: CGFloat { TabPageLayout.horizontalInset }

    @State private var query = ""
    @State private var filter: CommunityFilter = .nearby
    @State private var showLocationPicker = false
    @State private var place: Place = .nearYou

    private var myAges: [Int] {
        state.children.compactMap { child in
            child.birthDate.map { AgeRules.age(of: $0, on: .now) }
        }
    }

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) {
            $0.formUnion($1.interests)
        }
    }

    private var parents: [Parent] {
        let nearby = MockData.parents
            .filter {
                PlaceCatalog.matchesCommunity(
                    $0,
                    selection: place,
                    home: state.homeLocation
                ) && !state.connectedParents.contains($0.id)
            }
            .sorted { $0.distanceKm < $1.distanceKm }

        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = text.isEmpty
            ? nearby
            : nearby.filter {
                $0.searchText.localizedCaseInsensitiveContains(text)
            }

        switch filter {
        case .nearby:
            return searched

        case .similarAges:
            return searched.filter { parent in
                parent.children.contains { child in
                    myAges.contains { abs($0 - child.age) <= 2 }
                }
            }

        case .sharedInterests:
            return searched.filter {
                !myInterests.isDisjoint(with: $0.interests)
            }
        }
    }

    private var bestMatchID: Parent.ID? {
        let scored = parents.map {
            ($0.id, $0.interests.filter { myInterests.contains($0) }.count)
        }

        guard let best = scored.max(by: { $0.1 < $1.1 }),
              best.1 > 0 else {
            return nil
        }

        return best.0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if isWide {
                    HStack(alignment: .center, spacing: 14) {
                        locationChip
                        searchField
                    }
                    .padding(.horizontal, pageInset)
                } else {
                    locationChip
                    searchField
                }

                filterChips

                if !state.preferences.showProfile {
                    Label(
                        "Your profile is hidden. You can still browse and message your connections.",
                        systemImage: "eye.slash"
                    )
                    .caption()
                    .foregroundStyle(Theme.secondary)
                    .padding(.horizontal, pageInset)
                    .accessibilityIdentifier("community.profileHidden")
                }

                Text(
                    place.kind == .nearby
                    ? "Parents near you"
                    : place.kind == .world
                    ? "Parents everywhere"
                    : "Parents in \(place.name)"
                )
                .sectionTitle()
                .padding(.horizontal, pageInset)
                .padding(.top, 4)

                if parents.isEmpty {
                    emptyState
                } else if isWide {
                    let rows = stride(
                        from: 0,
                        to: parents.count,
                        by: 2
                    ).map { start in
                        Array(parents[start..<min(start + 2, parents.count)])
                    }

                    VStack(spacing: 18) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(alignment: .top, spacing: 18) {
                                ForEach(row) { parent in
                                    ParentCard(
                                        parent: parent,
                                        highlight: parent.id == bestMatchID
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .top
                                    )
                                }

                                if row.count == 1 {
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, pageInset)
                } else {
                    VStack(spacing: 16) {
                        ForEach(parents) { parent in
                            ParentCard(
                                parent: parent,
                                highlight: parent.id == bestMatchID
                            )
                        }
                    }
                    .padding(.horizontal, pageInset)
                }
            }
            .padding(.top, TabPageLayout.topInset)
            .padding(.bottom, 24)
        }
        .scrollTitleBar("Community")
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Community")
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Parent.self) {
            ConnectView(parent: $0)
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(
                selection: place,
                home: state.homeLocation
            ) {
                place = $0
            }
        }
    }

    // MARK: Top of the page

    private var header: some View {
        TabPageHeader(title: "Community") {
            HStack(spacing: 10) {
                NavigationLink {
                    MyConnectionsView()
                } label: {
                    connectionsIcon
                }
                .buttonStyle(.plain)

                NavigationLink {
                    NotificationsView()
                } label: {
                    bellIcon
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, pageInset)
    }

    private var connectionsIcon: some View {
        Image(systemName: "person.fill.checkmark")
            .scaledFont(18, weight: .semibold, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .frame(width: 48, height: 48)
            .background(Circle().fill(Theme.lavender))
            .accessibilityLabel("My connections")
    }

    private var bellIcon: some View {
        let unread = state.unreadNotificationCount

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
                        .background(Circle().fill(Theme.buttonFill))
                }
            }
            .accessibilityLabel(
                unread > 0
                ? "Notifications, \(unread) new"
                : "Notifications"
            )
    }

    // MARK: Location

    private var locationChip: some View {
        Button {
            showLocationPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.gatherAccent)

                Text(place.kind == .nearby ? "Near you" : place.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Image(systemName: "chevron.down").accessibilityHidden(true)
                    .font(.footnote.weight(.bold))
            }
            .scaledFont(15, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .gatherGlass(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            place.kind == .nearby
            ? "Near you, based on \(state.homeLocation.name). Change area"
            : "\(place.name). Change area"
        )
        .padding(.horizontal, isWide ? 0 : pageInset)
    }

    // MARK: Search

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.gatherText)

            TextField("Search parents or interests", text: $query)
                .scaledFont(16, maxScale: 1.3)
                .submitLabel(.search)
                .accessibilityLabel("Search parents or interests")

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 28, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear parent search")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .background(Theme.field, in: Capsule())
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isWide ? 0 : pageInset)
    }

    // MARK: Filters

    private var filterChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(CommunityFilter.allCases, id: \.self) { item in
                    let isSelected = item == filter

                    Button {
                        filter = item
                    } label: {
                        Text(item.rawValue)
                            .scaledFont(
                                15,
                                weight: isSelected ? .semibold : .regular,
                                maxScale: 1.3
                            )
                            .foregroundStyle(
                                isSelected ? Theme.ink : Theme.gatherText
                            )
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(
                                    isSelected ? Theme.lavender : Theme.field
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(
                        isSelected ? .isSelected : []
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, pageInset, for: .scrollContent)
        .animation(.snappy, value: filter)
    }

    // MARK: Empty state

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
            return place.kind == .nearby
                ? "No parents found near you yet."
                : "No parents found in \(place.kind == .world ? "this area" : place.name) yet."

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

#Preview("Community") {
    CommunityView()
        .environment(AppState())
}
