import SwiftUI

// MARK: - MediaGalleryView

/// Grid of the photos shared in a chat.
struct MediaGalleryView: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state

    var body: some View {
        let items = state.chats.thread(threadID)?.mediaMessages ?? []
        ScrollView {
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .scaledFont(36)
                        .foregroundStyle(Theme.tabIconInactive)
                    Text("No media yet")
                        .scaledFont(18, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                    Text("Photos you share in this chat will appear here.")
                        .scaledFont(15, maxScale: 1.3)
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 120)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                    ForEach(items) { item in
                        if let picked = item.image {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .overlay {
                                    picked.image.resizable().scaledToFill()
                                }
                                .clipped()
                                .accessibilityLabel("Photo")
                        }
                    }
                }
            }
        }
        .background(Theme.background)
        .navigationTitle("Media")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - AddMembersSheet

/// Sheet for choosing parents to add to a group chat.
struct AddMembersSheet: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []

    private var candidates: [Parent] {
        let existing = Set(state.chats.thread(threadID)?.members ?? [])
        return MockData.parents.filter { !existing.contains($0.name) }
    }

    var body: some View {
        NavigationStack {
            List {
                if candidates.isEmpty {
                    Text("Everyone nearby is already in this group.")
                        .foregroundStyle(Theme.secondary)
                }
                ForEach(candidates) { parent in
                    Button {
                        if selected.contains(parent.name) { selected.remove(parent.name) }
                        else { selected.insert(parent.name) }
                    } label: {
                        HStack(spacing: 14) {
                            Text(String(parent.name.prefix(2)).uppercased())
                                .scaledFont(15, weight: .bold)
                                .foregroundStyle(Theme.ink)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Theme.lavender))
                            Text(parent.name).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: selected.contains(parent.name) ? "checkmark.circle.fill" : "circle")
                                .scaledFont(22)
                                .foregroundStyle(selected.contains(parent.name) ? Theme.tabSelected : Theme.dotInactive)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Add members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        state.chats.addMembers(MockData.parents.map(\.name).filter { selected.contains($0) }, to: threadID)
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - StarredMessagesView

/// The messages a person starred in one chat.
struct StarredMessagesView: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state

    var body: some View {
        let starred = state.chats.thread(threadID)?.starredMessages ?? []
        Group {
            if starred.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .scaledFont(36)
                        .foregroundStyle(Theme.tabIconInactive)
                    Text("No starred messages")
                        .scaledFont(18, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                    Text("Press and hold a message, then choose Star to keep it here.")
                        .scaledFont(15, maxScale: 1.3)
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                List {
                    ForEach(starred) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.isMine ? "You" : (message.sender ?? state.chats.thread(threadID)?.title ?? ""))
                                .scaledFont(13, weight: .semibold, maxScale: 1.2)
                                .foregroundStyle(Theme.tabSelected)
                            Text(message.text.isEmpty ? (message.image != nil ? "Photo" : "Voice message") : message.text)
                                .scaledFont(16, maxScale: 1.3)
                                .foregroundStyle(Theme.ink)
                            Text(message.date.formatted(date: .abbreviated, time: .shortened))
                                .scaledFont(12, maxScale: 1.2)
                                .foregroundStyle(Theme.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions {
                            Button { state.chats.toggleStar(message.id, in: threadID) } label: {
                                Label("Unstar", systemImage: "star.slash")
                            }
                            .tint(Theme.tabSelected)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .navigationTitle("Starred messages")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - DisappearingMessagesView

/// Picker for how long messages in a chat are kept before they disappear.
struct DisappearingMessagesView: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state

    private static let options: [(title: String, seconds: TimeInterval?)] = [
        ("Off", nil), ("24 hours", 86_400), ("7 days", 7 * 86_400), ("90 days", 90 * 86_400)
    ]

    static func title(for seconds: TimeInterval?) -> String {
        options.first { $0.seconds == seconds }?.title ?? "Off"
    }

    var body: some View {
        let current = state.chats.thread(threadID)?.disappearAfter
        List {
            Section {
                ForEach(Self.options, id: \.title) { option in
                    Button { state.chats.setDisappearing(option.seconds, for: threadID) } label: {
                        HStack {
                            Text(option.title)
                                .foregroundStyle(Theme.ink)
                            Spacer()
                            if option.seconds == current {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.tabSelected)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(option.seconds == current ? .isSelected : [])
                }
            } footer: {
                Text("New messages in this chat disappear after the time you choose. Starred messages are kept, and earlier messages are not affected.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Disappearing messages")
        .navigationBarTitleDisplayMode(.inline)
    }
}
