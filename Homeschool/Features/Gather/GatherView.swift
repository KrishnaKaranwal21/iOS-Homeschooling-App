import SwiftUI

struct GatherView: View {
    @EnvironmentObject var state: AppState
    @State private var query = ""
    @State private var filter = "All"
    private let filters = ["All", "Science", "Nature", "Arts"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(filters, id: \.self) { f in Chip(title: f, selected: f == filter).onTapGesture { filter = f } } }
                }
                Text("Upcoming events").font(.title3.bold())
                ForEach(state.events.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }) { e in
                    NavigationLink(value: e) {
                        Card(color: Theme.lavender) { HStack {
                            VStack { Text(e.month).font(.caption); Text("\(e.day)").font(.title.bold()) }.padding(10).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading) { Text(e.title).font(.headline); Text("\(e.time) · \(e.place)").font(.caption); if e.isRegistered { Label("You are registered", systemImage: "checkmark.circle").font(.caption) } }
                            Spacer(); Image(systemName: "chevron.right")
                        } }
                    }.buttonStyle(.plain)
                }
                NavigationLink { HostEventView() } label: {
                    HStack { Text("Host an Event").font(.headline); Spacer(); Image(systemName: "arrow.right") }
                        .padding(.horizontal, 24).frame(height: 56).foregroundStyle(.white).background(Theme.ink, in: Capsule())
                }
            }.padding()
        }
        .background(Theme.background)
        .navigationTitle("Gatherings")
        .searchable(text: $query, prompt: "Workshops, outings, interests…")
        .navigationDestination(for: Event.self) { EventDetailView(event: $0) }
    }
}
