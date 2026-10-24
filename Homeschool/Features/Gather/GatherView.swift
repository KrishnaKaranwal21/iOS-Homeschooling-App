import SwiftUI

struct GatherView: View {
    @Environment(AppState.self) private var state
    @State private var query = ""
    @State private var category = "All"
    @State private var locality = "Potheri"
    @State private var ticketIndex = 0
    @State private var outingID: Event.ID?
    @State private var confirmation: Event?

    private let categories = ["All", "Science", "Habit", "Art", "Coding", "Nature"]
    private let localities = ["Potheri", "Guduvanchery", "Chengalpattu", "All areas"]

    private var visibleEvents: [Event] {
        state.events.filter { event in
            (category == "All" || event.category == category)
                && (locality == "All areas" || event.locality == locality)
                && (query.isEmpty || event.title.localizedCaseInsensitiveContains(query))
        }
    }

    private var registered: [Event] { visibleEvents.filter(\.isRegistered) }
    private var outings: [Event] { visibleEvents.filter { !$0.isRegistered } }

    private var outingPageCount: Int { (outings.count + 1) / 2 }
    private var currentOutingPage: Int {
        outings.firstIndex { $0.id == outingID }.map { $0 / 2 } ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                locationChip
                searchField
                categoryChips

                if registered.isEmpty && outings.isEmpty {
                    emptyState
                }
                if !registered.isEmpty {
                    nextGatherings
                }
                if !outings.isEmpty {
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
        .onChange(of: registered.count) { ticketIndex = 0 }
    }

    // MARK: Top of the page

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Gatherings")
                    .scaledFont(34, weight: .bold, maxScale: 1.3)
                    .lineLimit(1)
                    .tracking(-1.2)
                    .foregroundStyle(Theme.ink)
                Text("Good company. Shared discoveries.")
                    .scaledFont(15, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
            }
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
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
    }

    /// Opens the saved events list; shows how many are saved.
    private var savedIcon: some View {
        Image(systemName: state.savedEvents.isEmpty ? "bookmark" : "bookmark.fill")
            .scaledFont(17, weight: .semibold, maxScale: 1.3)
            .foregroundStyle(Theme.gatherAccent)
            .frame(width: 44, height: 44)
            .gatherGlass(in: Circle())
            .overlay(alignment: .topTrailing) {
                if !state.savedEvents.isEmpty {
                    Text("\(state.savedEvents.count)")
                        .scaledFont(11, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Circle().fill(Theme.gatherAccent))
                        .offset(x: 4, y: -4)
                }
            }
            .accessibilityLabel("Saved events")
    }

    private var locationChip: some View {
        Menu {
            Picker("Area", selection: $locality) {
                ForEach(localities, id: \.self) { Text($0).tag($0) }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(Theme.gatherAccent)
                Text(locality).fontWeight(.semibold)
                Image(systemName: "chevron.down").font(.footnote.weight(.bold))
            }
            .scaledFont(15, maxScale: 1.3)
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 38)
            .gatherGlass(in: Capsule())
        }
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

            TabView(selection: $ticketIndex) {
                ForEach(Array(registered.enumerated()), id: \.element.id) { index, event in
                    TicketCard(event: event) { confirmation = event }
                        .padding(.horizontal, 24)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 180)

            if registered.count > 1 {
                GatherPageDots(count: registered.count, current: ticketIndex)
            }
        }
    }

    private var findOutings: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Find your next outing")

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(outings) { event in
                        NavigationLink(value: event) { OutingCard(event: event) }
                            .buttonStyle(.plain)
                            .containerRelativeFrame(.horizontal, count: 2, spacing: 12)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $outingID)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 24, for: .scrollContent)

            if outingPageCount > 1 {
                GatherPageDots(count: outingPageCount, current: currentOutingPage)
            }
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
