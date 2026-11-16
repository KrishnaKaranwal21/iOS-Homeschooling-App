import SwiftUI

// MARK: - SavedEventsView

/// Every event the parent has liked, reached from the Gather header’s heart.
struct SavedEventsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollView {
            Text("Liked events")
                .pageTitle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            if state.savedEvents.isEmpty {
                ContentUnavailableView("No liked events yet",
                                       systemImage: "heart",
                                       description: Text("Tap the heart on any event to keep it here."))
                    .padding(.top, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(state.savedEvents) { event in
                        SavedEventRow(event: event)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .scrollNavigationTitle("Liked events")
        .toolbarVisibility(.visible, for: .navigationBar)
        .animation(.snappy, value: state.savedEvents.count)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - SavedEventRow

struct SavedEventRow: View {
    let event: Event
    @Environment(AppState.self) private var state

    /// A host's own photo stays; otherwise only the category icon, not the full artwork.
    @ViewBuilder private var thumbnail: some View {
        if event.coverImage != nil {
            EventCover(event: event)
        } else {
            EventIconTile(event: event)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                EventDetailView(event: event)
            } label: {
                HStack(spacing: 12) {
                    thumbnail
                        .frame(width: 76, height: 76)
                        .clipShape(.rect(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .scaledFont(17, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        GatherInfoRow(icon: "calendar", text: event.shortDateText)
                        GatherInfoRow(icon: "mappin.and.ellipse", text: event.locality)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                state.toggleBookmark(event)
            } label: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(Theme.gatherAccent)
                    .frame(width: 40, height: 40)
                    .gatherGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unlike \(event.title)")
        }
        .padding(10)
        .background(Theme.surface, in: .rect(cornerRadius: 24))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
    }
}

// MARK: - PastEventsView

struct PastEventsView: View {
    @Environment(AppState.self) private var state

    private var pastEvents: [Event] {
        state.events
            .filter {
                state.registrations[$0.id] != nil &&
                $0.end < .now
            }
            .sorted { $0.start > $1.start }
    }
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Past events")
                        .pageTitle()

                    Text("Look back at the gatherings and workshops that have taken place.")
                        .pageSubtitle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 4)

                if pastEvents.isEmpty {
                    ContentUnavailableView(
                        "No past events yet",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Events will appear here once they have finished.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(pastEvents) { event in
                        NavigationLink(value: event) {
                            OutingCard(event: event, coverHeight: 150)
                                .overlay(alignment: .topTrailing) {
                                    Text("Completed")
                                        .scaledFont(12, weight: .semibold)
                                        .foregroundStyle(Theme.ink)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Theme.lavender, in: Capsule())
                                        .padding(14)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.background)
        .navigationTitle("Past events")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Event.self) {
            EventDetailView(event: $0)
        }
    }
    
}

// MARK: - GatherTicketsView

/// Tickets remain available independently of the discovery date and location filters.
struct GatherTicketsView: View {
    @Environment(AppState.self) private var state
    @State private var confirmation: Event?
    private var tickets: [Event] { state.events.filter(\.isRegistered).sorted { $0.start < $1.start } }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if tickets.isEmpty {
                    ContentUnavailableView("Your next adventure awaits", systemImage: "ticket",
                        description: Text("When you register for a gathering, your ticket will be here."))
                        .padding(.top, 40)
                }
                ForEach(tickets) { event in
                    VStack(alignment: .leading, spacing: 10) {
                        TicketCard(event: event) { confirmation = event }
                        NavigationLink("Event details", value: event)
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
                            .padding(.leading, 8)
                    }
                }
            }.padding(20)
        }
        .background(Theme.background)
        .navigationTitle("Your tickets")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
        .fullScreenCover(item: $confirmation) { BookingTicketView(event: $0) }
    }
}
