import SwiftUI

struct ChatsListView: View {
    @State private var query = ""
    @State private var filter = "All"
    private var threads: [ChatThread] {
        MockData.threads.filter {
            (query.isEmpty || $0.title.localizedCaseInsensitiveContains(query)) &&
            (filter == "All" || (filter == "Unread" && $0.unread > 0) || (filter == "Groups" && $0.isGroup))
        }
    }
    var body: some View {
        List {
            Picker("Filter", selection: $filter) { ForEach(["All", "Unread", "Groups"], id: \.self, content: Text.init) }
                .pickerStyle(.segmented).listRowSeparator(.hidden)
            ForEach(threads) { t in
                NavigationLink { ChatDetailView(title: t.title) } label: {
                    HStack(spacing: 12) {
                        AvatarView(initials: String(t.title.prefix(2)).uppercased(), color: t.isGroup ? Theme.pink : Theme.lavender)
                        VStack(alignment: .leading) { Text(t.title).font(.headline); Text(t.preview).font(.subheadline).foregroundStyle(Theme.secondary).lineLimit(1) }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(t.time).font(.caption).foregroundStyle(Theme.secondary)
                            if t.unread > 0 { Text("\(t.unread)").font(.caption2.bold()).padding(6).background(Theme.lime, in: Circle()) }
                        }
                    }
                }
            }
        }
        .listStyle(.plain).navigationTitle("Chats")
        .searchable(text: $query, prompt: "Search chats")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("New chat") {}.buttonStyle(.borderedProminent).tint(Theme.lime).foregroundStyle(Theme.ink) } }
    }
}
