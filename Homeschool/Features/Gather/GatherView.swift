import SwiftUI

struct GatherView: View {
    @Environment(AppState.self) private var state
    @State private var query = ""
    @State private var category = "All"
    @State private var place: Place = .nearYou
    @State private var showLocationPicker = false
    @State private var ticketID: Event.ID?
    @State private var confirmation: Event?

    private let categories = ["All"] + Event.categories

    private var visibleEvents: [Event] {
        state.events.filter { event in
            (category == "All" || event.category == category)
                && PlaceCatalog.matches(event, selection: place)
                && (query.isEmpty || event.title.localizedCaseInsensitiveContains(query))
        }
    }

    private var registered: [Event] { visibleEvents.filter(\.isRegistered) }
    private var hasNoRegistrations: Bool { !state.events.contains(where: \.isRegistered) }
    /// Everything that matches the filters. Outside "Near you", registered events stay in the list with a badge.
    /// In "Near you" the registered events already sit in the tickets above, so they are left out here.
    private var outings: [Event] {
        isNearYou ? visibleEvents.filter { !$0.isRegistered } : visibleEvents
    }

    /// Tickets are only shown in the default "Near you" view.
    private var isNearYou: Bool { place.kind == .nearby }
    private var ticketPage: Int { registered.firstIndex { $0.id == ticketID } ?? 0 }

    private var outingsTitle: String {
        switch place.kind {
        case .nearby: return "Find your next outing"
        case .world:  return "All gatherings"
        default:      return "Gatherings in \(place.name)"
        }
    }

    var body: some View {
        ScrollViewReader { proxy in
            page(proxy)
        }
    }

    private func page(_ proxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    locationChip
                    searchField
                }

                categoryChips

                if isNearYou {
                    if hasNoRegistrations {
                        noRegistrations(proxy)
                    } else if !registered.isEmpty {
                        nextGatherings
                    }
                }
                if outings.isEmpty {
                    if !(isNearYou && !registered.isEmpty) { emptyState }
                } else {
                    findOutings
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background)
        .navigationTitle("Gatherings")
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        .sheet(item: $confirmation) { GatherConfirmationSheet(event: $0) }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(selection: place) { place = $0 }
        }
    }

    // MARK: Top of the page

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
        HStack(alignment: .center, spacing: 12) {
            Text("Gatherings")
                .scaledFont(34, weight: .bold, maxScale: 1.3)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .tracking(-1.2)
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)

            GatherGlassContainer(spacing: 10) {
                HStack(spacing: 10) {
                    NavigationLink { SavedEventsView() } label: { savedIcon }
                    NavigationLink { HostEventView() } label: {
                        Label("Host", systemImage: "plus")
                            .scaledFont(17, weight: .semibold, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherAccent)
                            .padding(.horizontal, 18)
                            .frame(minHeight: 44)
                            .gatherGlass(in: Capsule())
                    }
                }
            }
            .buttonStyle(.plain)
            .overlay(alignment: .topLeading) { savedBadge }
        }

        Text("Good company. Shared discoveries.")
            .scaledFont(15, maxScale: 1.3)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(Theme.gatherText)
        }
        .padding(.horizontal, 24)
    }

    /// Opens the saved events list.
    private var savedIcon: some View {
        Image(systemName: state.savedEvents.isEmpty ? "bookmark" : "bookmark.fill")
            .scaledFont(17, weight: .semibold, maxScale: 1.3)
            .foregroundStyle(Theme.gatherAccent)
            .frame(width: 44, height: 44)
            .gatherGlass(in: Circle())
            .accessibilityLabel(state.savedEvents.isEmpty
                                ? "Saved events"
                                : "Saved events, \(state.savedEvents.count)")
    }

    /// Drawn outside the glass container so the glass can never cover it.
    @ViewBuilder private var savedBadge: some View {
        if !state.savedEvents.isEmpty {
            Text("\(state.savedEvents.count)")
                .scaledFont(11, weight: .bold, maxScale: 1.2)
                .foregroundStyle(Color.white)
                .frame(minWidth: 18, minHeight: 18)
                .background(Circle().fill(Theme.gatherAccent))
                .overlay(Circle().stroke(Theme.background, lineWidth: 2))
                .offset(x: 26, y: -4)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var locationChip: some View {
        Button { showLocationPicker = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.gatherAccent)
                Text(place.name).fontWeight(.semibold).lineLimit(1)
                Image(systemName: "chevron.down").font(.footnote.weight(.bold))
            }
            .scaledFont(15, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .gatherGlass(in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Location: \(place.name). Change location")
        .padding(.horizontal, 24)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.gatherText)
            TextField("Find a workshop or outing", text: $query)
                .scaledFont(16, maxScale: 1.3)
                .submitLabel(.search)
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 48)
        .background(Capsule().fill(Color.white))
        .overlay(Capsule().stroke(Theme.lilacBorder, lineWidth: 1))
        .padding(.horizontal, 24)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { name in
                    Button { category = name } label: {
                        Text(name)
                            .scaledFont(15, weight: name == category ? .semibold : .regular, maxScale: 1.3)
                            .foregroundStyle(name == category ? Theme.ink : Theme.gatherText)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Capsule().fill(name == category ? Theme.lavender : Theme.chipFill))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(name == category ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 24, for: .scrollContent)
        .animation(.snappy, value: category)
    }

    // MARK: Sections

    private var nextGatherings: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Your next gathering")

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(registered) { event in
                        TicketCard(event: event) { confirmation = event }
                            .padding(.horizontal, 24)
                            .containerRelativeFrame(.horizontal)
                            .id(event.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $ticketID)
            .scrollIndicators(.hidden)

            if registered.count > 1 {
                GatherPageDots(count: registered.count, current: ticketPage)
            }
        }
    }

    private func noRegistrations(_ proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Your next gathering")
            EmptyTicketCard(onBrowse: outings.isEmpty ? nil : {
                withAnimation(.smooth) { proxy.scrollTo("outings", anchor: .top) }
            })
            .padding(.horizontal, 24)
        }
    }

    private var findOutings: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(outingsTitle)
                .id("outings")

            LazyVStack(spacing: 16) {
                ForEach(outings) { event in
                    NavigationLink(value: event) { OutingCard(event: event, coverHeight: 180) }
                        .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView("Nothing here yet",
                               systemImage: "calendar.badge.exclamationmark",
                               description: Text("Try another area or category, or host the first one."))
            .padding(.top, 24)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .scaledFont(24, weight: .bold, maxScale: 1.3)
            .tracking(-0.6)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 24)
    }
}
