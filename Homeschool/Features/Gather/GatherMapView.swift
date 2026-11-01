import SwiftUI
import MapKit

/// Events do not store verified venue coordinates yet. Resolve their real areas and
/// label them as areas rather than placing invented pins on individual venues.
struct GatherMapView: View {
    let events: [Event]
    @Environment(\.dismiss) private var dismiss
    @State private var areas: [GatherMapArea] = []
    @State private var selection: String?
    @State private var loading = true

    private var inPerson: [Event] { events.filter { $0.mode == .inPerson } }
    private var shown: [Event] {
        guard let selection else { return inPerson }
        return inPerson.filter { "\($0.locality), \($0.country)" == selection }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !areas.isEmpty {
                    Map(selection: $selection) {
                        ForEach(areas) { area in
                            Marker(area.name, systemImage: "person.2", coordinate: area.coordinate)
                                .tint(Theme.accentFill).tag(area.id)
                        }
                    }
                    .mapStyle(.standard(elevation: .flat))
                    .frame(minHeight: 220, maxHeight: 340)
                    Text("Pins show event areas. Check each event for its venue.")
                        .font(.caption).foregroundStyle(Theme.secondary).padding(12)
                } else if loading {
                    ProgressView("Finding event areas…").frame(maxWidth: .infinity).frame(height: 220)
                }
                if inPerson.isEmpty {
                    ContentUnavailableView("No in-person events", systemImage: "map",
                        description: Text("Change your filters to explore event areas."))
                } else {
                    List {
                        if areas.isEmpty && !loading {
                            Text("The map is unavailable right now. You can still explore the event venues below.")
                                .font(.subheadline).foregroundStyle(Theme.secondary)
                        }
                        ForEach(shown) { event in
                            NavigationLink(value: event) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(event.title).font(.headline)
                                    Text(event.location.replacingOccurrences(of: "\n", with: ", "))
                                        .font(.subheadline).foregroundStyle(Theme.secondary)
                                    Text(event.shortDateText).font(.caption).foregroundStyle(Theme.accent)
                                }.padding(.vertical, 4)
                            }
                        }
                    }.listStyle(.plain)
                }
            }
            .background(Theme.background)
            .navigationTitle("Gather around")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                if selection != nil {
                    ToolbarItem(placement: .topBarLeading) { Button("All areas") { selection = nil } }
                }
            }
        }
        .tint(Theme.accent)
        .presentationDragIndicator(.visible)
        .task { await findAreas() }
    }

    @MainActor private func findAreas() async {
        defer { loading = false }
        let names = Set(inPerson.map { "\($0.locality), \($0.country)" }).sorted()
        for name in names {
            guard !Task.isCancelled else { return }
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = name
            request.resultTypes = .address
            let search = MKLocalSearch(request: request)
            do {
                let response = try await withTaskCancellationHandler {
                    try await search.start()
                } onCancel: { search.cancel() }
                guard !Task.isCancelled else { return }
                if let item = response.mapItems.first {
                    areas.append(GatherMapArea(id: name, name: name, coordinate: item.placemark.coordinate))
                }
            } catch { /* The venue list remains usable when Maps is offline. */ }
        }
    }
}

private struct GatherMapArea: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
}
