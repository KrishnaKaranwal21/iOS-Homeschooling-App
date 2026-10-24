import SwiftUI

struct ConnectView: View {
    let parent: Parent
    @State private var sent = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    AvatarView(initials: String(parent.name.prefix(1)), color: Theme.lime, size: 80)
                    VStack(alignment: .leading) { Text(parent.name).font(.title.bold()); Text(parent.role); Text("\(parent.distanceKm.formatted(.number.precision(.fractionLength(1)))) km away").font(.caption) }
                }
                Text("A little about us").font(.title3.bold())
                Text("“\(parent.about)”").foregroundStyle(Theme.secondary)
                infoCard("Interests we share", ["Science experiments", "Reading", "Art & crafts", "Nature walks"])
                infoCard("Looking to connect for", ["Learning groups", "Weekend outings"])
                Label("Only approximate distance is shared. Your exact location stays private.", systemImage: "checkmark.shield").font(.caption).foregroundStyle(Theme.secondary)
                Button { sent = true } label: {
                    Text(sent ? "Request sent" : "Connect").font(.headline).frame(maxWidth: .infinity, minHeight: 56).foregroundStyle(.white).background(sent ? Theme.secondary : Theme.ink, in: Capsule())
                }.disabled(sent)
                Text("Send a connection request. Chat once \(parent.name.components(separatedBy: " ")[0]) accepts.").font(.caption).foregroundStyle(Theme.secondary).frame(maxWidth: .infinity)
            }.padding()
        }.background(Theme.background).navigationBarTitleDisplayMode(.inline)
    }
    private func infoCard(_ title: String, _ items: [String]) -> some View {
        Card(color: Theme.pink) { VStack(alignment: .leading, spacing: 4) { Text(title).font(.headline); ForEach(items, id: \.self) { Text($0).font(.subheadline) } } }
    }
}
