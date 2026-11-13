import SwiftUI

private enum CommunityFilter: String, CaseIterable {
    case nearby = "Nearby"
    case similarAges = "Similar ages"
    case sharedInterests = "Shared interests"
}

struct CommunityView: View {
    @Environment(AppState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var isWide: Bool { sizeClass == .regular }
    private var pageInset: CGFloat { isWide ? 24 : 20 }
    @State private var query = ""
    @State private var filter: CommunityFilter = .nearby
    @State private var showLocationPicker = false

    /// Ages of my children, from their dates of birth.
    private var myAges: [Int] {
        state.children.compactMap { child in child.birthDate.map { AgeRules.age(of: $0, on: .now) } }
    }

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) { $0.formUnion($1.interests) }
    }

    private var parents: [Parent] {
        // "Near you" is the same 10 km as on the Gatherings page. No distance is ever shown.
        let nearby = MockData.parents
            .filter { $0.distanceKm <= CommunityOptions.nearKm }
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

    /// The parent with the most interests in common with my family, if any.
    private var bestMatchID: Parent.ID? {
        let scored = parents.map { ($0.id, $0.interests.filter { myInterests.contains($0) }.count) }
        guard let best = scored.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
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

                Text("Parents near you")
                    .sectionTitle()
                    .padding(.horizontal, pageInset)
                    .padding(.top, 4)

                if parents.isEmpty {
                    emptyState
                } else if isWide {
                    // Two parents in each row.
                    let rows = stride(from: 0, to: parents.count, by: 2).map { start in
                        Array(parents[start..<min(start + 2, parents.count)])
                    }
                    VStack(spacing: 18) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                            HStack(alignment: .top, spacing: 18) {
                                ForEach(row) { parent in
                                    ParentCard(parent: parent, highlight: parent.id == bestMatchID)
                                        .frame(maxWidth: .infinity, alignment: .top)
                                }
                                if row.count == 1 { Color.clear.frame(maxWidth: .infinity) }
                            }
                        }
                    }
                    .padding(.horizontal, pageInset)
                } else {
                    VStack(spacing: 16) {
                        ForEach(parents) { parent in
                            ParentCard(parent: parent, highlight: parent.id == bestMatchID)
                        }
                    }
                    .padding(.horizontal, pageInset)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollTitleBar("Community")
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Community")
        .toolbarVisibility(isWide ? .visible : .hidden, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Parent.self) { ConnectView(parent: $0) }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(allowsWorld: false, selection: state.homeLocation,
                                home: state.homeLocation) { state.homeLocation = $0 }
        }
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
        .padding(.horizontal, pageInset)
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
            .accessibilityLabel(unread > 0 ? "Notifications, \(unread) new" : "Notifications")
    }

    /// The same "Near you" chip as on the Gatherings page: everything within 10 km.
    private var locationChip: some View {
        Button { showLocationPicker = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.gatherAccent)
                Text("Near you").fontWeight(.semibold).lineLimit(1)
                Image(systemName: "chevron.down").font(.footnote.weight(.bold))
            }
            .scaledFont(15, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .gatherGlass(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Near you, based on \(state.homeLocation.name). Change area")
        .padding(.horizontal, isWide ? 0 : pageInset)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.gatherText)
            TextField("Search parents or interests", text: $query)
                .scaledFont(16, maxScale: 1.3)
                .submitLabel(.search)
                .accessibilityLabel("Search parents or interests")
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.secondary)
                        .frame(width: 28, height: 44)
                }
                .buttonStyle(.plain).accessibilityLabel("Clear parent search")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 50)
        .background(Theme.field, in: Capsule())
        .frame(maxWidth: .infinity)
        .padding(.horizontal, isWide ? 0 : pageInset)
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
                            .background(Capsule().fill(isSelected ? Theme.lavender : Theme.field))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, pageInset, for: .scrollContent)
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
            return "No parents found near you yet."
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

/// One parent: who they are and where, their children, what the children like, and what to do next.
struct ParentCard: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab
    let parent: Parent
    /// True for the family with the most in common.
    var highlight = false

    private var myInterests: Set<String> {
        state.children.reduce(into: Set<String>()) { $0.formUnion($1.interests) }
    }

    private var requested: Bool { state.requestedParents.contains(parent.id) }
    private var connected: Bool { state.connectedParents.contains(parent.id) }

    /// Their interests with the shared ones first.
    private var interests: [String] {
        let all = parent.interests
        return all.filter { myInterests.contains($0) } + all.filter { !myInterests.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            identityHeader.padding(6)

            VStack(alignment: .leading, spacing: 12) {
                Text(parent.about)
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(3).fixedSize(horizontal: false, vertical: true)

                if !interests.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(interests.prefix(4), id: \.self) { name in
                            InfoChip(title: name,tint: Theme.chipFill, isCompact: true,
                                     symbol: myInterests.contains(name) ? "sparkles" : nil)
                        }
                        if interests.count > 4 {
                            InfoChip(title: "+\(interests.count - 4)", tint: Theme.chipFill, isCompact: true)
                        }
                    }
                }

                if highlight {
                    Label {
                        Text("Most in common").foregroundStyle(Theme.ink)
                    } icon: {
                        Image(systemName: "sparkles").foregroundStyle(Theme.gatherAccent)
                    }
                    .scaledFont(12, weight: .semibold, maxScale: 1.3)
                    .padding(.top, 1)
                }

                ProfileDivider().padding(.horizontal, -10).padding(.top, 2)
                footer
            }
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: .rect(cornerRadius: 30))
        .roundedStroke(highlight ? Theme.lavender : Theme.lilacBorder,
                       cornerRadius: 30, lineWidth: highlight ? 1.5 : 1)
    }

    private var identityHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            ParentAvatar(parent: parent, size: 72)
            VStack(alignment: .leading, spacing: 5) {
                Text(parent.name)
                    .scaledFont(21, weight: .bold, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(parent.role)
                    .scaledFont(14, maxScale: 1.3)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !parent.place.isEmpty {
                    Label(parent.place, systemImage: "mappin.and.ellipse")
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
        .background(Theme.pink_light, in: .rect(cornerRadius: 24))
    }

    private var profileLink: some View {
        NavigationLink(value: parent) {
            HStack(spacing: 8) {
                Text("View profile")
                Image(systemName: "arrow.right").fontWeight(.medium)
            }
            .scaledFont(15, weight: .semibold, maxScale: 1.3)
            .foregroundStyle(Theme.tabSelected)
            .frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View \(parent.name)’s profile")
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                profileLink.fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: 0)
                actionButton.fixedSize(horizontal: true, vertical: false)
            }
            VStack(alignment: .leading, spacing: 8) {
                profileLink
                actionButton.frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    @ViewBuilder private var actionButton: some View {
        if connected {
            Button {
                state.chats.pendingOpenID = state.chats.startChat(with: parent)
                openTab(.chats)
            } label: {
                Label("Message", systemImage: "bubble.left")
                    .scaledFont(15, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 20)
                    .frame(minWidth: 104, minHeight: 44)
                    .background(Capsule().fill(Theme.lavender))
            }
            .buttonStyle(.plain)
        } else {
            Button { state.sendRequest(to: parent) } label: {
                Text(requested ? "Requested" : "Connect")
                    .scaledFont(15, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(requested ? Theme.gatherText : Theme.buttonText)
                    .padding(.horizontal, 22)
                    .frame(minWidth: 104, minHeight: 44)
                    .background(Capsule().fill(requested ? Theme.chipFill : Theme.buttonFill))
            }
            .buttonStyle(.plain)
            .disabled(requested)
        }
    }
}

/// Round photo, or the first letter of the name when there is no photo in the asset catalog
/// (add an image named like `Parent-Sara` to show a photo).
struct ParentAvatar: View {
    let parent: Parent
    var size: CGFloat = 88

    var body: some View {
        ZStack {
            Circle().fill(Theme.pink)
            Text(String(parent.name.prefix(1)))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(Theme.ink)
            if let photo = UIImage(named: parent.photoName) {
                Image(uiImage: photo).resizable().scaledToFill()
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .accessibilityHidden(true)
    }
}

// MARK: - Notifications

/// Updates from the community. Tap one to go straight to what it is about.
struct NotificationsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab

    private var sentRequests: [Parent] {
        MockData.parents.filter { state.requestedParents.contains($0.id) && !state.connectedParents.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications")
                        .pageTitle()
                    Text("Tap one to see what it is about.")
                        .pageSubtitle()
                }

                if !sentRequests.isEmpty {
                    Text("Requests you sent")
                        .sectionTitle()
                        .padding(.top, 4)
                    ForEach(sentRequests) { parent in
                        NotificationCard(symbol: "paperplane",
                                         title: "Request sent to \(parent.name)",
                                         detail: "You can chat once \(parent.firstName) accepts.",
                                         time: "Just now", isNew: false)
                    }
                }

                Text("Recent")
                    .sectionTitle()
                    .padding(.top, 4)

                if state.notifications.isEmpty {
                    Text("You’re all caught up.")
                        .rowDetail()
                }

                ForEach(state.notifications) { item in
                    row(item)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollNavigationTitle("Notifications")
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: state.notifications.count)
    }

    @ViewBuilder private func row(_ item: AppNotification) -> some View {
        if case .connectionRequest(let parentID) = item.action,
           let parent = MockData.parents.first(where: { $0.id == parentID }) {
            // Someone wants to connect: accept or decline right here, or look at their profile first.
            VStack(spacing: 12) {
                NavigationLink(value: parent) {
                    NotificationCard(symbol: item.symbol, title: item.title, detail: item.detail,
                                     time: item.time, isNew: item.isNew, showsChevron: true, framed: false)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded { state.markRead(item.id) })

                HStack(spacing: 10) {
                    Button {
                        if let chat = state.acceptRequest(from: parentID) {
                            state.chats.pendingOpenID = chat
                            openTab(.chats)
                        }
                    } label: {
                        Text("Accept")
                            .scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(Capsule().fill(Theme.buttonFill))
                    }
                    .buttonStyle(.plain)

                    Button { state.declineRequest(from: parentID) } label: {
                        Text("Decline")
                            .scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(Capsule().fill(Theme.chipFill))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(Theme.surface, in: .rect(cornerRadius: 24))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 24)
        } else {
            Button {
                state.markRead(item.id)
                state.open(item.action, openTab: openTab)
            } label: {
                NotificationCard(symbol: item.symbol, title: item.title, detail: item.detail,
                                 time: item.time, isNew: item.isNew,
                                 showsChevron: item.action != .none)
            }
            .buttonStyle(.plain)
            .disabled(item.action == .none)
        }
    }
}

private struct NotificationCard: View {
    let symbol: String
    let title: String
    let detail: String
    let time: String
    let isNew: Bool
    var showsChevron = false
    /// False when the card sits inside a larger card that draws the frame.
    var framed = true

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .scaledFont(17, weight: .semibold, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.lavender))

            VStack(alignment: .leading, spacing: 3) {
                Text(title).rowTitle()
                    .multilineTextAlignment(.leading)
                Text(detail).rowDetail()
                    .multilineTextAlignment(.leading)
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
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.dotInactive)
                    .padding(.top, 6)
            }
        }
        .padding(framed ? 14 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(framed ? Theme.surface : Color.clear, in: .rect(cornerRadius: 24))
        .roundedStroke(framed ? Theme.lilacBorder : Color.clear, cornerRadius: 24)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
