//
//  PastEventsView.swift
//  Homeschool
//
//  Created by user@51 on 16/11/26.
//


import SwiftUI

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
