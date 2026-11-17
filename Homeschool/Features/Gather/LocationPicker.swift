import SwiftUI
import MapKit

/// Search box on top. With nothing typed it lists nearby areas, then India, then the rest of the world.
struct LocationPickerSheet: View {
    /// Offers "All over the world". Hosts must choose a real place, so they turn it off.
    var allowsWorld = true
    let selection: Place?
    /// The family's home area, shown under "Near you".
    var home: Place = .potheri
    let onSelect: (Place) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var suggester = PlaceSuggester()

    private var trimmed: String { query.trimmingCharacters(in: .whitespaces) }
    private var isSearching: Bool { !trimmed.isEmpty }

    private var matches: [Place] {
        PlaceCatalog.all.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.country.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// Map results that are not already in the built-in list.
    private var extraSuggestions: [Place] {
        let known = Set(matches.map { $0.name.lowercased() })
        return suggester.suggestions.filter { !known.contains($0.name.lowercased()) }
    }

    var body: some View {
        NavigationStack {
            List {
                if isSearching {
                    searchResults
                } else {
                    browseSections
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(allowsWorld ? "Choose a location" : "Where is it?")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search any city, area or country")
            .onChange(of: query) { _, newValue in suggester.update(newValue) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder private var browseSections: some View {
        if allowsWorld {
            Section {
                row(.nearYou)
                row(.world)
            }
        }
        Section("Nearby areas") { ForEach(PlaceCatalog.nearby) { row($0) } }
        Section("India") { ForEach(PlaceCatalog.india) { row($0) } }
        Section("All over the world") {
            ForEach(PlaceCatalog.worldCountries + PlaceCatalog.worldCities) { row($0) }
        }
    }

    @ViewBuilder private var searchResults: some View {
        let local = matches
        let extra = extraSuggestions

        if !local.isEmpty {
            Section("Matches") { ForEach(local) { row($0) } }
        }
        if !extra.isEmpty {
            Section("More places") { ForEach(extra) { row($0) } }
        }
        if local.isEmpty && extra.isEmpty {
            Section {
                row(Place(name: trimmed, detail: "Use exactly what you typed", country: "", kind: .city))
            }
        }
    }

    private func row(_ place: Place) -> some View {
        Button {
            onSelect(place)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon(for: place))
                    .foregroundStyle(Theme.gatherAccent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .scaledFont(16, weight: .medium, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    Text(place.kind == .nearby ? "Around \(home.name)" : place.detail)
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
                Spacer(minLength: 0)
                if selection?.id == place.id {
                    Image(systemName: "checkmark").foregroundStyle(Theme.gatherAccent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func icon(for place: Place) -> String {
        switch place.kind {
        case .nearby:  return "location.fill"
        case .world:   return "globe"
        case .country: return "flag"
        case .city:    return "building.2"
        case .area:    return "mappin.and.ellipse"
        }
    }
}
