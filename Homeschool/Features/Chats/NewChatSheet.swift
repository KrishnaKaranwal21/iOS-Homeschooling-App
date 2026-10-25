import SwiftUI

/// Pick a parent to message, or start a group.
struct NewChatSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let onOpen: (ChatThread.ID) -> Void

    @State private var query = ""

    private var parents: [Parent] {
        MockData.parents.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        NavigationLink {
                            NewGroupView(onOpen: onOpen)
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "person.3.fill")
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 46, height: 46)
                                    .background(Circle().fill(Color(hex: 0xE6E1FF)))
                                Text("New group")
                                    .scaledFont(17, weight: .medium, maxScale: 1.2)
                            }
                        }
                    }
                }

                Section("Parents near you") {
                    ForEach(parents) { parent in
                        Button {
                            onOpen(state.chats.startChat(with: parent))
                        } label: {
                            HStack(spacing: 14) {
                                Text(String(parent.name.prefix(2)).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 46, height: 46)
                                    .background(Circle().fill(Theme.lavender))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(parent.name).scaledFont(17, weight: .medium, maxScale: 1.2)
                                    Text("\(parent.role) · \(parent.distanceKm.formatted(.number.precision(.fractionLength(1)))) km")
                                        .scaledFont(14, maxScale: 1.2)
                                        .foregroundStyle(Theme.secondary)
                                }
                            }
                            .foregroundStyle(Theme.ink)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("New chat")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search parents")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
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
                            Text(parent.name)
                                .scaledFont(17, maxScale: 1.2)
                                .foregroundStyle(Theme.ink)
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
