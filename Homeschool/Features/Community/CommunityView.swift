import SwiftUI

struct CommunityView: View {
    @State private var radius = 5
    @State private var filter = "All parents"
    private var nearby: [Parent] { MockData.parents.filter { $0.distanceKm <= Double(radius) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: "Community", subtitle: "Like minded families near you.")
                Card(color: Theme.pink) {
                    Menu {
                        Picker("Radius", selection: $radius) { ForEach([1, 2, 3, 5, 10, 20], id: \.self) { Text("\($0) km").tag($0) } }
                    } label: {
                        HStack { Image(systemName: "mappin.circle"); VStack(alignment: .leading) { Text("Within \(radius) km of you").font(.headline); Text("Based on your current location").font(.caption) }; Spacer(); Image(systemName: "chevron.down") }.foregroundStyle(Theme.ink)
                    }
                }
                HStack { ForEach(["All parents", "Shared interests"], id: \.self) { f in Chip(title: f, selected: f == filter).onTapGesture { filter = f } } }
                Text("People near you").font(.title3.bold())
                ForEach(nearby) { p in
                    NavigationLink(value: p) { ParentRow(parent: p) }.buttonStyle(.plain)
                }
                Label("Only approximate distance is shared.", systemImage: "checkmark.shield").font(.caption).foregroundStyle(Theme.secondary)
            }.padding()
        }
        .background(Theme.background)
        .navigationDestination(for: Parent.self) { ConnectView(parent: $0) }
    }
}

struct ParentRow: View {
    let parent: Parent
    var body: some View {
        Card { HStack(spacing: 12) {
            AvatarView(initials: String(parent.name.prefix(1)), color: Theme.lime)
            VStack(alignment: .leading) { Text(parent.name).font(.headline); Text(parent.role).font(.caption); Text(parent.tags).font(.caption).foregroundStyle(Theme.secondary); Text(String(format: "%.1f km away", parent.distanceKm)).font(.caption) }
            Spacer()
            Text("Connect").font(.footnote.bold()).foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 8).background(Theme.ink, in: Capsule())
        } }
    }
}
