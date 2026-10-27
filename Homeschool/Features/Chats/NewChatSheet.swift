import SwiftUI

/// Start a chat: a "New group" row on top, then parents listed A to Z, like a messenger's contact list.
struct NewChatSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let onOpen: (ChatThread.ID) -> Void

    @State private var query = ""

    private var parents: [Parent] {
        MockData.parents
            .filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Parents grouped under the first letter of their name.
    private var sections: [(letter: String, parents: [Parent])] {
        let grouped = Dictionary(grouping: parents) { String($0.name.prefix(1)).uppercased() }
        return grouped.keys.sorted().map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        NavigationLink {
                            NewGroupView(onOpen: onOpen)
                        } label: {
                            actionRow(symbol: "person.3.fill", title: "New group")
                        }
                        ShareLink(item: "Join me on Homeschool to meet families near you.") {
                            actionRow(symbol: "square.and.arrow.up", title: "Invite parents")
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                if parents.isEmpty {
                    Text("No parents found for “\(query)”")
                        .rowDetail()
                        .listRowBackground(Color.clear)
                }

                ForEach(sections, id: \.letter) { section in
                    Section {
                        ForEach(section.parents) { parent in
                            Button {
                                onOpen(state.chats.startChat(with: parent))
                            } label: {
                                parentRow(parent)
                            }
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        Text(section.letter)
                            .scaledFont(14, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("New chat")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search parents")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func actionRow(symbol: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.lavender))
            Text(title).rowTitle()
        }
        .padding(.vertical, 2)
    }

    private func parentRow(_ parent: Parent) -> some View {
        HStack(spacing: 14) {
            Text(String(parent.name.prefix(2)).uppercased())
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Theme.lavender))
            VStack(alignment: .leading, spacing: 2) {
                Text(parent.name).rowTitle()
                Text("\(parent.role) · \(parent.distanceKm.formatted(.number.precision(.fractionLength(1)))) km away")
                    .rowDetail()
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct NewGroupView: View {
    @Environment(AppState.self) private var state
    let onOpen: (ChatThread.ID) -> Void

    @State private var name = ""
    @State private var selected: Set<String> = []

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selected.isEmpty
    }

    var body: some View {
        List {
            Section {
                TextField("Group name", text: $name)
                    .scaledFont(17, maxScale: 1.3)
            }
            Section("Add members") {
                ForEach(MockData.parents) { parent in
                    Button {
                        if selected.contains(parent.name) { selected.remove(parent.name) }
                        else { selected.insert(parent.name) }
                    } label: {
                        HStack(spacing: 14) {
                            Text(String(parent.name.prefix(2)).uppercased())
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Theme.lavender))
                            Text(parent.name).rowTitle()
                            Spacer()
                            Image(systemName: selected.contains(parent.name) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected.contains(parent.name) ? Theme.tabSelected : Theme.dotInactive)
                                .font(.system(size: 22))
                        }
                    }
                    .accessibilityAddTraits(selected.contains(parent.name) ? .isSelected : [])
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("New group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    let members = MockData.parents.map(\.name).filter { selected.contains($0) }
                    onOpen(state.chats.createGroup(title: name.trimmingCharacters(in: .whitespaces), members: members))
                }
                .disabled(!canCreate)
            }
        }
    }
}
