import SwiftUI

struct GatherView: View {
    @Environment(AppState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filter = GatherFeedFilter()
    @State private var place: Place = .nearYou
    @State private var showFilters = false
    @State private var showLocationPicker = false
    @State private var showHost = false
    @State private var showProfile = false
    @State private var showProfilePrompt = false
    @State private var openProfileAfterPrompt = false
    @State private var pageLimit = 3
    @State private var feedGeneration = UUID()
    private let pageSize = 3

    private var events: [Event] {
        GatherFeedCategory.prioritize(state.events.filter {
            filter.includes($0) && PlaceCatalog.matches($0, selection: place, home: state.homeLocation)
        }, interests: state.child.interests)
    }
    private var activeFilterCount: Int {
        (filter.freeOnly ? 1 : 0) + (filter.onlineOnly ? 1 : 0) + (place != .nearYou ? 1 : 0)
    }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 18, alignment: .top), count: sizeClass == .regular ? 2 : 1)
    }

    private static let topID = "gather.top"

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Color.clear.frame(height: 0).id(Self.topID)
                discoveryControls.padding(.bottom, 20)
                Section {
                    if events.isEmpty {
                        emptyState.padding(.top, 44)
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                            ForEach(Array(events.prefix(pageLimit))) { event in
                                GatherFeedCard(event: event)
                            }
                            if events.count > pageLimit {
                                GatherLoadingCard()
                                    .id("\(feedGeneration)-\(pageLimit)")
                                    .task { await revealNextPage(generation: feedGeneration) }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }
                } header: {
                    categoryStrip
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .background(Theme.background.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .top, spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    Text("Gather").pageTitle().fixedSize()
                    Spacer(minLength: 8)
                    likedEventsButton
                    hostEventButton
                }
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Gather").pageTitle()
                        Spacer()
                        likedEventsButton
                    }
                    hostEventButton.frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 12)
            .background(Theme.background)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        .navigationDestination(isPresented: $showHost) { HostEventView() }
        .navigationDestination(isPresented: $showProfile) { ProfileView() }
        .sheet(isPresented: $showFilters) { filtersSheet }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(selection: place, home: state.homeLocation) { place = $0 }
        }
        .sheet(isPresented: $showProfilePrompt, onDismiss: {
            if openProfileAfterPrompt {
                openProfileAfterPrompt = false
                showProfile = true
            }
        }) {
            CompleteProfileSheet(missing: state.missingProfileItems) {
                openProfileAfterPrompt = true
                showProfilePrompt = false
            }
        }
        .onChange(of: filter) { resetPagination() }
        .onChange(of: place) { resetPagination() }
        .onChange(of: state.child.interests) { resetPagination() }
        .onChange(of: state.child.id) { resetPagination() }
        // A new label always opens from the top, not where the previous one was scrolled to.
        .onChange(of: filter.category) { proxy.scrollTo(Self.topID, anchor: .top) }
        }
    }

    private var likedEventsButton: some View {
        NavigationLink {
            SavedEventsView()
        } label: {
            Image(systemName: state.savedEvents.isEmpty ? "heart" : "heart.fill")
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(Theme.accent)
                .frame(width: 44, height: 44)
                .gatherGlass(in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Liked events, \(state.savedEvents.count) saved")
        .accessibilityIdentifier("gather.likedEvents")
    }

    private var hostEventButton: some View {
        Button(action: hostEvent) {
            Label("Host an event", systemImage: "plus")
                .scaledFont(14, weight: .semibold, maxScale: 1.3)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 15).frame(minHeight: 44)
                .background(Theme.lilac, in: Capsule())
                .fixedSize(horizontal: true, vertical: false)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("gather.hostEvent")
    }

    private var discoveryControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").scaledFont(20, maxScale: 1.35)
                        .foregroundStyle(Theme.secondary)
                    TextField("Search events or activities…", text: $filter.query)
                        .scaledFont(16, maxScale: 1.35).submitLabel(.search)
                        .accessibilityIdentifier("gather.search")
                    if !filter.query.isEmpty {
                        Button { filter.query = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.secondary)
                        }.accessibilityLabel("Clear search")
                    }
                }
                .padding(.horizontal, 18).frame(minHeight: 50)
                .background(Theme.field, in: Capsule())
                Button { showFilters = true } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .scaledFont(23, weight: .regular, maxScale: 1.35)
                        .foregroundStyle(Theme.ink).frame(width: 44, height: 48)
                        .overlay(alignment: .topTrailing) {
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)").font(.caption2.bold()).foregroundStyle(.white)
                                    .frame(width: 17, height: 17).background(Theme.accentFill, in: Circle())
                            }
                        }
                }
                .accessibilityLabel("Filters and your events")
                .accessibilityIdentifier("gather.filters")
            }
            .padding(.horizontal, 20)

        }
        .buttonStyle(.plain)
    }

    /// Same look as the filter chips in Chats: rounded pills, lavender when selected.
    private var categoryStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(GatherFeedCategory.ordered(interests: state.child.interests)) { category in
                    let selected = filter.category == category
                    Button { filter.category = category } label: {
                        Text(category.rawValue)
                            .scaledFont(15, weight: selected ? .semibold : .regular, maxScale: 1.2)
                            .lineLimit(1)
                            .foregroundStyle(selected ? Theme.ink : Theme.secondary)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(Capsule().fill(selected ? Color.adaptive(0xD9D2FF, 0x3B3059) : Theme.field))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .padding(.vertical, 8)
        .background(Theme.background)
    }

    private var filtersSheet: some View {
        NavigationStack {
            List {
                Section("Discover") {
                    Button {
                        showFilters = false
                        showLocationPicker = true
                    } label: {
                        HStack { Label("Location", systemImage: "mappin.and.ellipse"); Spacer(); Text(place.name).foregroundStyle(Theme.secondary) }
                    }
                    Toggle("Free events only", isOn: $filter.freeOnly).tint(Theme.accent)
                    Toggle("Online events only", isOn: $filter.onlineOnly).tint(Theme.accent)
                }
                Section("Your gatherings") {
                    NavigationLink { SavedEventsView() } label: {
                        Label("Liked events (\(state.savedEvents.count))", systemImage: "heart")
                    }
                    Button {
                        filter.category = .yours
                        showFilters = false
                    } label: { Label("Your events", systemImage: "calendar") }
                    NavigationLink { GatherTicketsView() } label: {
                        Label("Your tickets", systemImage: "ticket")
                    }
                    Button {
                        showFilters = false
                        hostEvent()
                    } label: { Label("Host an event", systemImage: "plus.circle") }
                }
                if !state.hostedEventsWithQuestions.isEmpty {
                    Section("Questions for you") {
                        ForEach(state.hostedEventsWithQuestions) { event in
                            NavigationLink {
                                EventDetailView(event: event)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title)
                                    Text("\(event.unansweredCount) unanswered questions").font(.caption).foregroundStyle(Theme.secondary)
                                }
                            }
                        }
                    }
                }
                Section {
                    Button("Reset filters") { filter = GatherFeedFilter(); place = .nearYou }
                }
            }
            // Text buttons and "Done" are black, not purple. Toggles keep the app's purple.
            .tint(Theme.ink)
            .navigationTitle("Make it your kind of day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showFilters = false } } }
        }
        .presentationDragIndicator(.visible)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("A little quiet here", systemImage: "sparkles")
        } description: {
            Text("Try another location or category to find your next gathering.")
        } actions: {
            Button("Explore all upcoming events") { filter = GatherFeedFilter(); place = .world }
                .buttonStyle(.bordered).tint(Theme.accent)
        }
    }

    private func hostEvent() {
        if state.missingProfileItems.isEmpty { showHost = true } else { showProfilePrompt = true }
    }

    private func resetPagination() {
        feedGeneration = UUID()
        pageLimit = pageSize
    }

    @MainActor private func revealNextPage(generation: UUID) async {
        // The current catalog is local. Reveal it in finite pages, with the same loading
        // treatment ready for a paginated event service. Never duplicate events at the end.
        do { try await Task.sleep(for: .milliseconds(750)) } catch { return }
        guard !Task.isCancelled, generation == feedGeneration else { return }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
            pageLimit = min(pageLimit + pageSize, events.count)
        }
    }
}
