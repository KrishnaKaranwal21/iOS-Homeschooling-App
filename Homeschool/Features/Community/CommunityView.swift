import SwiftUI

struct CommunityView: View {
    @Environment(AppState.self) private var state
    private var radius: Int { state.communityRadiusKm }
    @State private var filter = "All parents"
    private var nearby: [Parent] { MockData.parents.filter { $0.distanceKm <= Double(radius) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ScreenHeader(title: "Community", subtitle: "Like minded families near you.")
                // The location and distance are set in Profile, under Settings.
                NavigationLink {
                    ProfileView()
                } label: {
                    Card(color: Theme.pink) {
                        HStack {
                            Image(systemName: "mappin.circle")
                            VStack(alignment: .leading) {
                                Text("Within \(radius) km of \(state.homeLocation.name)").font(.headline)
                                Text("Change in Profile › Settings").font(.caption)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Theme.ink)
                    }
                }
                .buttonStyle(.plain)
                HStack { ForEach(["All parents", "Shared interests"], id: \.self) { f in Button { filter = f } label: { Chip(title: f, selected: f == filter) }.buttonStyle(.plain).accessibilityAddTraits(f == filter ? .isSelected : []) } }
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
            VStack(alignment: .leading) { Text(parent.name).font(.headline); Text(parent.role).font(.caption); Text(parent.tags).font(.caption).foregroundStyle(Theme.secondary); Text("\(parent.distanceKm.formatted(.number.precision(.fractionLength(1)))) km away").font(.caption) }
            Spacer()
            Text("Connect").font(.footnote.bold()).foregroundStyle(.white).padding(.horizontal, 14).padding(.vertical, 8).background(Theme.ink, in: Capsule())
        } }
    }
}
