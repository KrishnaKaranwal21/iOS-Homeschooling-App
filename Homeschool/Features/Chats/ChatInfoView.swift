import SwiftUI

/// Chat settings, laid out like a messenger's contact or group info page.
struct ChatInfoView: View {
    let threadID: ChatThread.ID
    let onSearch: () -> Void

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var confirmClear = false
    @State private var confirmExit = false
    @State private var showAddMembers = false
    @State private var showLabels = false

    private var thread: ChatThread? { state.chats.thread(threadID) }

    var body: some View {
        Group {
            if let thread {
                ScrollView {
                    VStack(spacing: 18) {
                        hero(thread)
                        actions(thread)
                        mediaCard(thread)
                        chatToolsCard(thread)
                        settingsCard(thread)
                        if thread.isGroup { membersCard(thread) }
                        dangerCard(thread)
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
                .scrollIndicators(.hidden)
            } else {
                Color.clear
            }
        }
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: thread == nil) { _, isGone in
            if isGone { dismiss() }
        }
        .confirmationDialog("Clear all messages?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear chat", role: .destructive) { state.chats.clear(threadID) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(thread?.isGroup == true ? "Exit this group?" : "Delete this chat?",
                            isPresented: $confirmExit, titleVisibility: .visible) {
            Button(thread?.isGroup == true ? "Exit group" : "Delete chat", role: .destructive) {
                state.chats.delete(threadID)
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showAddMembers) {
            AddMembersSheet(threadID: threadID)
        }
        .sheet(isPresented: $showLabels) {
            ThreadLabelsSheet(threadID: threadID)
        }
    }

    // MARK: Top

    private func hero(_ thread: ChatThread) -> some View {
        VStack(spacing: 8) {
            ChatAvatar(thread: thread, size: 112)
                .padding(.top, 6)
            Text(thread.title)
                .detailTitle()
                .multilineTextAlignment(.center)
            if !thread.subtitle.isEmpty {
                Text(thread.subtitle)
                    .rowDetail()
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func actions(_ thread: ChatThread) -> some View {
        HStack(spacing: 10) {
            actionTile(icon: "magnifyingglass", title: "Search") {
                dismiss()
                onSearch()
            }
            actionTile(icon: thread.isMuted ? "bell.slash.fill" : "bell", title: thread.isMuted ? "Unmute" : "Mute") {
                state.chats.toggleMute(threadID)
            }
            actionTile(icon: thread.isPinned ? "pin.fill" : "pin", title: thread.isPinned ? "Unpin" : "Pin") {
                state.chats.togglePin(threadID)
            }
            if thread.isGroup {
                actionTile(icon: "person.badge.plus", title: "Add") { showAddMembers = true }
            }
        }
    }

    private func actionTile(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.tabSelected)
                Text(title)
                    .scaledFont(13, weight: .medium, maxScale: 1.15)
                    .foregroundStyle(Theme.ink)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
            .background(Color.white, in: .rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    // MARK: Cards

    private func mediaCard(_ thread: ChatThread) -> some View {
        card {
            NavigationLink {
                MediaGalleryView(threadID: threadID)
            } label: {
                row(icon: "photo.on.rectangle", title: "Media",
                    trailing: "\(thread.mediaMessages.count)", showsChevron: true)
            }
            .buttonStyle(.plain)

            if !thread.mediaMessages.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(thread.mediaMessages.suffix(8)) { item in
                            if let picked = item.image {
                                Color.clear
                                    .frame(width: 84, height: 84)
                                    .overlay { picked.image.resizable().scaledToFill() }
                                    .clipShape(.rect(cornerRadius: 12))
                                    .accessibilityLabel("Photo")
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    /// Storage, media visibility, starred messages, disappearing messages and chat lock.
    private func chatToolsCard(_ thread: ChatThread) -> some View {
        let stored = state.chats.storage(for: threadID)
        let items = (stored?.photos ?? 0) + (stored?.voiceNotes ?? 0)
        return card {
            NavigationLink { ManageStorageView(threadID: threadID) } label: {
                row(icon: "externaldrive", title: "Manage storage",
                    trailing: items == 0 ? nil : "\(items) \(items == 1 ? "item" : "items")", showsChevron: true)
            }
            .buttonStyle(.plain)
            separator

            Menu {
                Picker("Media visibility", selection: Binding(
                    get: { thread.hidesMedia },
                    set: { state.chats.setHidesMedia($0, for: threadID) })) {
                    Text("Show media").tag(false)
                    Text("Hide media").tag(true)
                }
            } label: {
                row(icon: "photo", title: "Media visibility",
                    trailing: thread.hidesMedia ? "Hidden" : "Shown", showsChevron: true)
            }
            .buttonStyle(.plain)
            separator

            NavigationLink { StarredMessagesView(threadID: threadID) } label: {
                row(icon: "star", title: "Starred messages",
                    trailing: thread.starredMessages.isEmpty ? nil : "\(thread.starredMessages.count)",
                    showsChevron: true)
            }
            .buttonStyle(.plain)
            separator

            NavigationLink { DisappearingMessagesView(threadID: threadID) } label: {
                row(icon: "timer", title: "Disappearing messages",
                    trailing: DisappearingMessagesView.title(for: thread.disappearAfter), showsChevron: true)
            }
            .buttonStyle(.plain)
            separator

            toggleRow(icon: "lock", title: "Chat lock",
                      subtitle: "Lock and hide this chat on this device.",
                      isOn: Binding(
                        get: { thread.isLocked },
                        set: { wantsLock in
                            guard wantsLock != thread.isLocked else { return }
                            if wantsLock {
                                Task {
                                    if await ChatAuth.unlock(reason: "Lock this chat") {
                                        state.chats.toggleLock(threadID)
                                    }
                                }
                            } else {
                                state.chats.toggleLock(threadID)
                            }
                        }))
        }
    }

    private func settingsCard(_ thread: ChatThread) -> some View {
        card {
            toggleRow(icon: "bell.slash", title: "Mute notifications", isOn: Binding(
                get: { thread.isMuted }, set: { _ in state.chats.toggleMute(threadID) }))
            separator
            toggleRow(icon: "pin", title: "Pin chat", isOn: Binding(
                get: { thread.isPinned }, set: { _ in state.chats.togglePin(threadID) }))
            separator
            toggleRow(icon: "heart", title: "Add to Favourites", isOn: Binding(
                get: { thread.isFavourite }, set: { _ in state.chats.toggleFavourite(threadID) }))
            separator
            Button { showLabels = true } label: {
                row(icon: "tag", title: "Lists", trailing: labelNames(for: thread), showsChevron: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func membersCard(_ thread: ChatThread) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(thread.members.count + 1) members")
                .scaledFont(14, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.secondary)
                .padding(.horizontal, 6)
            card {
                Button { showAddMembers = true } label: {
                    row(icon: "person.badge.plus", title: "Add members", trailing: nil, showsChevron: false)
                }
                .buttonStyle(.plain)
                separator
                memberRow(name: "You", detail: "Group admin", canRemove: false)
                ForEach(thread.members, id: \.self) { member in
                    separator
                    memberRow(name: member, detail: nil, canRemove: true)
                }
            }
        }
    }

    private func memberRow(name: String, detail: String?, canRemove: Bool) -> some View {
        HStack(spacing: 12) {
            Text(String(name.prefix(1)).uppercased())
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.lavender))
            Text(name)
                .scaledFont(16, maxScale: 1.25)
                .foregroundStyle(Theme.ink)
            Spacer()
            if let detail {
                Text(detail)
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.tabSelected)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Capsule().fill(Color(hex: 0xEFEDFB)))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contextMenu {
            if canRemove {
                Button(role: .destructive) {
                    state.chats.removeMember(name, from: threadID)
                } label: {
                    Label("Remove from group", systemImage: "person.badge.minus")
                }
            }
        }
    }

    private func dangerCard(_ thread: ChatThread) -> some View {
        card {
            Button { confirmClear = true } label: {
                row(icon: "trash", title: "Clear chat", trailing: nil, showsChevron: false, destructive: true)
            }
            .buttonStyle(.plain)
            separator
            if !thread.isGroup {
                Button { state.chats.toggleBlock(threadID) } label: {
                    row(icon: "nosign", title: thread.isBlocked ? "Unblock \(thread.title)" : "Block \(thread.title)",
                        trailing: nil, showsChevron: false, destructive: !thread.isBlocked)
                }
                .buttonStyle(.plain)
                separator
            }
            Button { confirmExit = true } label: {
                row(icon: thread.isGroup ? "rectangle.portrait.and.arrow.right" : "xmark.bin",
                    title: thread.isGroup ? "Exit group" : "Delete chat",
                    trailing: nil, showsChevron: false, destructive: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func labelNames(for thread: ChatThread) -> String? {
        let names = state.chats.customLabels.filter { thread.labelIDs.contains($0.id) }.map(\.name)
        return names.isEmpty ? "None" : names.joined(separator: ", ")
    }

    // MARK: Building blocks

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0, content: content)
            .background(Color.white, in: .rect(cornerRadius: 22))
    }

    private var separator: some View {
        Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1).padding(.leading, 52)
    }

    private func row(icon: String, title: String, trailing: String?, showsChevron: Bool,
                     destructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(destructive ? Color.red : Theme.tabSelected)
                .frame(width: 28)
            Text(title)
                .scaledFont(16, maxScale: 1.25)
                .foregroundStyle(destructive ? Color.red : Theme.ink)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .scaledFont(15, maxScale: 1.25)
                    .foregroundStyle(Theme.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.dotInactive)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func toggleRow(icon: String, title: String, subtitle: String? = nil,
                           isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Theme.tabSelected)
                .frame(width: 28)
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .scaledFont(16, maxScale: 1.25)
                        .foregroundStyle(Theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .scaledFont(13, maxScale: 1.25)
                            .foregroundStyle(Theme.secondary)
                    }
                }
            }
            .tint(Theme.tabSelected)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Media

private struct MediaGalleryView: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state

    var body: some View {
        let items = state.chats.thread(threadID)?.mediaMessages ?? []
        ScrollView {
            if items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 36))
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

// MARK: - Add members

private struct AddMembersSheet: View {
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
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.ink)
                                .frame(width: 42, height: 42)
                                .background(Circle().fill(Theme.lavender))
                            Text(parent.name).foregroundStyle(Theme.ink)
                            Spacer()
                            Image(systemName: selected.contains(parent.name) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22))
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


// MARK: - Manage storage

private struct ManageStorageView: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state

    @State private var confirmPhotos = false
    @State private var confirmVoice = false

    var body: some View {
        let stored = state.chats.storage(for: threadID) ?? (photos: 0, voiceNotes: 0, voiceBytes: 0)
        List {
            Section {
                LabeledContent("Photos", value: "\(stored.photos)")
                LabeledContent("Voice messages") {
                    Text("\(stored.voiceNotes) · " + ByteCountFormatter.string(fromByteCount: Int64(stored.voiceBytes), countStyle: .file))
                }
            } footer: {
                Text("What this chat keeps on this device.")
            }

            Section {
                Button("Clear photos", role: .destructive) { confirmPhotos = true }
                    .disabled(stored.photos == 0)
                Button("Clear voice messages", role: .destructive) { confirmVoice = true }
                    .disabled(stored.voiceNotes == 0)
            } footer: {
                Text("Text messages are kept.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .navigationTitle("Manage storage")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Clear all photos in this chat?", isPresented: $confirmPhotos, titleVisibility: .visible) {
            Button("Clear photos", role: .destructive) { state.chats.clearPhotos(in: threadID) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Clear all voice messages in this chat?", isPresented: $confirmVoice, titleVisibility: .visible) {
            Button("Clear voice messages", role: .destructive) { state.chats.clearVoiceNotes(in: threadID) }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Starred messages

private struct StarredMessagesView: View {
    let threadID: ChatThread.ID
    @Environment(AppState.self) private var state

    var body: some View {
        let starred = state.chats.thread(threadID)?.starredMessages ?? []
        Group {
            if starred.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.system(size: 36))
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

// MARK: - Disappearing messages

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
