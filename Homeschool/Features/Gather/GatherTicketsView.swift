import SwiftUI

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
        .fullScreenCover(item: $confirmation) { GatherConfirmationSheet(event: $0) }
    }
}
