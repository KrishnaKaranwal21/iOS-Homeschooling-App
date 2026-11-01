import SwiftUI

struct GatherView: View {
    @Environment(AppState.self) private var state
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var filter = GatherFeedFilter()
    @State private var place: Place = .nearYou
    @State private var showFilters = false
    @State private var showLocationPicker = false
    @State private var showMap = false
    @State private var showHost = false
    @State private var showProfile = false
    @State private var showProfilePrompt = false
    @State private var pageLimit = 3
    @State private var feedGeneration = UUID()
    private let pageSize = 3

    private var events: [Event] {
        state.events.filter {
            filter.includes($0) && PlaceCatalog.matches($0, selection: place, home: state.homeLocation)
        }.sorted { $0.start < $1.start }
    }
    private var activeFilterCount: Int {
        (filter.freeOnly ? 1 : 0) + (filter.onlineOnly ? 1 : 0) + (place != .nearYou ? 1 : 0)
    }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 24, alignment: .top), count: sizeClass == .regular ? 2 : 1)
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                discoveryControls.padding(.bottom, 22)
                Section {
                    if events.isEmpty {
                        emptyState.padding(.top, 44)
                    } else {
                        LazyVGrid(columns: columns, alignment: .leading, spacing: 28) {
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
                        .padding(.top, 30)
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button { showMap = true } label: {
                Label("Map", systemImage: "map")
                    .scaledFont(16, weight: .semibold, maxScale: 1.35)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22).frame(minHeight: 48)
                    .background(Theme.accentFill, in: Capsule())
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show event areas on a map")
            .padding(.top, 8).padding(.bottom, 8)
        }
        .toolbarVisibility(.hidden, for: .navigationBar)
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        .navigationDestination(isPresented: $showHost) { HostEventView() }
        .navigationDestination(isPresented: $showProfile) { ProfileView() }
        .sheet(isPresented: $showFilters) { filtersSheet }
        .sheet(isPresented: $showMap) { GatherMapView(events: events) }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(selection: place, home: state.homeLocation) { place = $0 }
        }
        .sheet(isPresented: $showProfilePrompt) {
            CompleteProfileSheet(missing: state.missingProfileItems) {
                showProfilePrompt = false
                showProfile = true
            }
        }
        .onChange(of: filter) { resetPagination() }
        .onChange(of: place) { resetPagination() }
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
            ScrollView(.horizontal) {
                HStack(spacing: 4) {
                    ForEach(GatherTimeFilter.allCases) { time in
                        Button { filter.time = time } label: {
                            Text(time.rawValue).scaledFont(14, weight: .semibold, maxScale: 1.35)
                                .foregroundStyle(filter.time == time ? Color.white : Theme.ink)
                                .padding(.horizontal, 14).frame(minHeight: 40)
                                .background(filter.time == time ? Theme.accentFill : .clear, in: Capsule())
                        }
                        .accessibilityAddTraits(filter.time == time ? .isSelected : [])
                    }
                }.padding(.horizontal, 20)
            }.scrollIndicators(.hidden)
        }
        .buttonStyle(.plain)
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 22) {
                ForEach(GatherFeedCategory.allCases) { category in
                    Button { filter.category = category } label: {
                        VStack(spacing: 8) {
                            Text(category.emoji).scaledFont(25, maxScale: 1.35).accessibilityHidden(true)
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: filter.category == category ? .semibold : .regular))
                                .foregroundStyle(filter.category == category ? Theme.ink : Theme.secondary)
                            Rectangle().fill(filter.category == category ? Theme.ink : .clear)
                                .frame(height: 2).padding(.top, 6)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter.category == category ? .isSelected : [])
                }
            }
            .padding(.horizontal, 28).padding(.top, 7)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.cardBorder).frame(height: 1) }
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
                    Toggle("Free events only", isOn: $filter.freeOnly)
                    Toggle("Online events only", isOn: $filter.onlineOnly)
                }
                Section("Your gatherings") {
                    NavigationLink { SavedEventsView() } label: {
                        Label("Saved events (\(state.savedEvents.count))", systemImage: "heart")
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
                        if state.missingProfileItems.isEmpty { showHost = true } else { showProfilePrompt = true }
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
            .tint(Theme.accent)
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
            Text("Try another day, location or category to find your next gathering.")
        } actions: {
            Button("Explore all upcoming events") { filter = GatherFeedFilter(); place = .world }
                .buttonStyle(.bordered).tint(Theme.accent)
        }
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
