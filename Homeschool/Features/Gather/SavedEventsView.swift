import SwiftUI

/// Every event the parent has bookmarked. Reached from the bookmark button on the Gatherings page.
struct SavedEventsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollView {
            Text("Saved events")
                .pageTitle()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 4)

            if state.savedEvents.isEmpty {
                ContentUnavailableView("No saved events yet",
                                       systemImage: "bookmark",
                                       description: Text("Tap the bookmark on any event to keep it here."))
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
        .animation(.snappy, value: state.savedEvents.count)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SavedEventRow: View {
    let event: Event
    @Environment(AppState.self) private var state

    var body: some View {
        HStack(spacing: 12) {
            NavigationLink {
                EventDetailView(event: event)
            } label: {
                HStack(spacing: 12) {
                    EventCover(event: event)
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
                Image(systemName: "bookmark.fill")
                    .foregroundStyle(Theme.gatherAccent)
                    .frame(width: 40, height: 40)
                    .gatherGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove from saved events")
        }
        .padding(10)
        .background(Color.white, in: .rect(cornerRadius: 24))
        .roundedStroke(Theme.lilacBorder, cornerRadius: 24, lineWidth: 1)
    }
}
