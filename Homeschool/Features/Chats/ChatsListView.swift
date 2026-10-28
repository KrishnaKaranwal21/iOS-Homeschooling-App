import SwiftUI

/// All conversations: search, filter chips and a swipeable list.
struct ChatsListView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openTab) private var openTab

    @State private var query = ""
    @State private var showLabelEditor = false
    @State private var editingLabel: ChatLabel?
    @State private var broadcastLabel: ChatLabel?
    @State private var labelsThread: ThreadRef?
    @State private var openID: ChatThread.ID?
    @State private var showNewChat = false
    @State private var deleteTarget: ChatThread.ID?
    @State private var isConfirmingDelete = false

    private let accent = Color(hex: 0xD9D2FF)
    private let unreadTime = Color(hex: 0x5B6B2F)

    private var selectedLabel: ChatLabel { state.chats.selectedLabel }

    private var threads: [ChatThread] {
        state.chats.threads(for: selectedLabel).filter { thread in
            query.isEmpty
                || thread.title.localizedCaseInsensitiveContains(query)
                || thread.messages.contains { $0.text.localizedCaseInsensitiveContains(query) }
        }
    }

    // MARK: Body

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                header
                searchField
                chips
            }
            .padding(.horizontal, 18)
            .padding(.top, 6)
            .padding(.bottom, 8)

            labelStrip

            if threads.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $openID) { id in
            ChatDetailView(threadID: id)
        }
        .onAppear(perform: openPendingChat)
        .onChange(of: state.chats.pendingOpenID) { openPendingChat() }
        .sheet(isPresented: $showNewChat) {
            NewChatSheet { id in
                showNewChat = false
                // Wait for the sheet to close before opening the chat.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openID = id }
            }
        }
        .sheet(isPresented: $showLabelEditor) { LabelEditorSheet(editing: nil) }
        .sheet(item: $editingLabel) { label in LabelEditorSheet(editing: label) }
        .sheet(item: $broadcastLabel) { label in BroadcastSheet(label: label) }
        .sheet(item: $labelsThread) { ref in ThreadLabelsSheet(threadID: ref.id) }
        .confirmationDialog("Delete this chat?",
                            isPresented: $isConfirmingDelete,
                            titleVisibility: .visible,
                            presenting: deleteTarget) { id in
            Button("Delete chat", role: .destructive) {
                state.chats.delete(id)
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: { _ in
            Text("The messages will be removed from this device.")
        }
    }

    /// Opens a chat that another screen asked for, such as "Message host".
    private func openPendingChat() {
        guard let id = state.chats.pendingOpenID else { return }
        state.chats.pendingOpenID = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { openID = id }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Text("Chats")
                .pageTitle()
            Spacer()
            Button { showNewChat = true } label: {
                Text("New chat")
                    .scaledFont(15, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 18)
                    .frame(height: 40)
                    .background(Capsule().fill(accent))
            }
            .buttonStyle(.plain)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondary)
            TextField("Search chats", text: $query)
                .scaledFont(16, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
                .submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.dotInactive)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(Capsule().fill(Theme.field))
    }

    /// A horizontal bar of filters. Tap to filter, long-press to edit, move, remove or send to everyone under it.
    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(state.chats.labels) { label in
                    chip(label)
                }

                Button { showLabelEditor = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                        .frame(width: 46, height: 36)
                        .background(Capsule().fill(Theme.field))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add a label")
            }
            .padding(.horizontal, 18)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -18)
    }

    private func chip(_ label: ChatLabel) -> some View {
        let selected = state.chats.selectedLabelID == label.id
        let canBroadcast = !label.isBuiltIn || label.id == ChatLabel.favourites.id
        let index = state.chats.labels.firstIndex(of: label) ?? 0

        return Button { state.chats.select(label.id) } label: {
            HStack(spacing: 6) {
                if !label.isBuiltIn {
                    Circle().fill(label.color).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                }
                if label.id == ChatLabel.favourites.id {
                    Image(systemName: "star.fill").font(.system(size: 11))
                }
                Text(label.name)
                    .scaledFont(15, weight: selected ? .semibold : .regular, maxScale: 1.2)
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Theme.ink : Theme.secondary)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(Capsule().fill(selected ? accent : Theme.field))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .contextMenu {
            if canBroadcast {
                Button { broadcastLabel = label } label: {
                    Label("Send to everyone here", systemImage: "paperplane")
                }
            }
            if !label.isBuiltIn {
                Button { editingLabel = label } label: { Label("Edit label", systemImage: "pencil") }
            }
            if label.id != ChatLabel.allID {
                Button { state.chats.moveLabel(label.id, by: -1) } label: {
                    Label("Move left", systemImage: "arrow.left")
                }
                .disabled(index <= 1)
                Button { state.chats.moveLabel(label.id, by: 1) } label: {
                    Label("Move right", systemImage: "arrow.right")
                }
                .disabled(index >= state.chats.labels.count - 1)
                Button(role: .destructive) { state.chats.removeLabel(label.id) } label: {
                    Label(label.isBuiltIn ? "Remove from bar" : "Delete label", systemImage: "trash")
                }
            }
        }
    }

    /// Shown above the list while a custom label is selected.
    @ViewBuilder private var labelStrip: some View {
        if !selectedLabel.isBuiltIn && !threads.isEmpty {
            HStack(spacing: 10) {
                Text("\(threads.count) \(threads.count == 1 ? "chat" : "chats") in \(selectedLabel.name)")
                    .scaledFont(14, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.secondary)
                Spacer()
                Button { broadcastLabel = selectedLabel } label: {
                    Label("Send to all", systemImage: "paperplane.fill")
                        .scaledFont(13, weight: .semibold, maxScale: 1.15)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 30)
                        .background(Capsule().fill(accent))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 6)
        }
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach(threads) { thread in
                row(thread)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18))
                    .listRowSeparatorTint(Color.black.opacity(0.07))
                    .alignmentGuide(.listRowSeparatorLeading) { _ in 74 }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        if thread.hasUnread {
                            Button { state.chats.markRead(thread.id) } label: {
                                Label("Read", systemImage: "envelope.open")
                            }
                            .tint(Theme.tabSelected)
                        } else {
                            Button { state.chats.markUnread(thread.id) } label: {
                                Label("Unread", systemImage: "envelope.badge")
                            }
                            .tint(Theme.tabSelected)
                        }
                        Button { state.chats.togglePin(thread.id) } label: {
                            Label(thread.isPinned ? "Unpin" : "Pin", systemImage: thread.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(Color(hex: 0xB5AED0))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { deleteTarget = thread.id; isConfirmingDelete = true } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { state.chats.toggleMute(thread.id) } label: {
                            Label(thread.isMuted ? "Unmute" : "Mute",
                                  systemImage: thread.isMuted ? "bell" : "bell.slash")
                        }
                        .tint(Color(hex: 0x8E8E93))
                    }
                    .contextMenu {
                        Button { labelsThread = ThreadRef(id: thread.id) } label: {
                            Label("Labels…", systemImage: "tag")
                        }
                        Button { state.chats.toggleFavourite(thread.id) } label: {
                            Label(thread.isFavourite ? "Remove from favourites" : "Add to favourites",
                                  systemImage: thread.isFavourite ? "star.slash" : "star")
                        }
                        Button { state.chats.togglePin(thread.id) } label: {
                            Label(thread.isPinned ? "Unpin chat" : "Pin chat", systemImage: "pin")
                        }
                        Button { state.chats.toggleMute(thread.id) } label: {
                            Label(thread.isMuted ? "Unmute" : "Mute", systemImage: "bell.slash")
                        }
                        Button { state.chats.markUnread(thread.id) } label: {
                            Label("Mark as unread", systemImage: "envelope.badge")
                        }
                        Button(role: .destructive) { deleteTarget = thread.id; isConfirmingDelete = true } label: {
                            Label("Delete chat", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }

    private func row(_ thread: ChatThread) -> some View {
        Button {
            openID = thread.id
        } label: {
            HStack(spacing: 14) {
                ChatAvatar(thread: thread, size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(thread.title)
                            .scaledFont(17, weight: thread.hasUnread ? .semibold : .regular, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        if thread.isFavourite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.tabIconInactive)
                        }
                        ForEach(labelColors(for: thread), id: \.self) { color in
                            Circle().fill(color).frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                        }
                    }
                    HStack(spacing: 5) {
                        if let last = thread.messages.last, last.isMine {
                            ReadTicks(status: last.status)
                        }
                        Text(thread.preview)
                            .scaledFont(15, maxScale: 1.2)
                            .foregroundStyle(Theme.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(ChatFormat.listTime(thread.lastDate))
                        .scaledFont(13, maxScale: 1.2)
                        .foregroundStyle(thread.hasUnread && !thread.isMuted ? unreadTime : Theme.secondary)
                    HStack(spacing: 6) {
                        if thread.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.secondary)
                        }
                        if thread.isMuted {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.secondary)
                        }
                        if thread.hasUnread {
                            unreadBadge(thread)
                        }
                    }
                    .frame(height: 24)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the conversation")
    }

    private func labelColors(for thread: ChatThread) -> [Color] {
        state.chats.customLabels
            .filter { thread.labelIDs.contains($0.id) }
            .prefix(3)
            .map(\.color)
    }

    @ViewBuilder
    private func unreadBadge(_ thread: ChatThread) -> some View {
        if thread.unreadCount > 0 {
            Text("\(thread.unreadCount)")
                .scaledFont(13, weight: .semibold, maxScale: 1.1)
                .foregroundStyle(Theme.ink)
                .frame(minWidth: 24, minHeight: 24)
                .padding(.horizontal, thread.unreadCount > 9 ? 4 : 0)
                .background(Capsule().fill(thread.isMuted ? Theme.dotInactive : accent))
        } else {
            Circle().fill(accent).frame(width: 14, height: 14)
        }
    }

    @ViewBuilder private var emptyState: some View {
        if state.chats.threads.isEmpty {
            welcomeCallout
        } else {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: query.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.tabIconInactive)
                Text(query.isEmpty ? "Nothing here yet" : "No results for “\(query)”")
                    .sectionTitle()
                Text(query.isEmpty
                     ? (selectedLabel.isBuiltIn
                        ? "Chats that match this filter will show up here."
                        : "Press and hold a chat, then choose Labels to add it to \(selectedLabel.name).")
                     : "Try a name or a word from a message.")
                    .pageSubtitle()
                    .multilineTextAlignment(.center)
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
        }
    }

    /// Shown when there are no conversations at all.
    private var welcomeCallout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image("HomeMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .accessibilityHidden(true)

                Text("Your conversations start here")
                    .sectionTitle()

                Text("Connect with parents studying the same NIOS level or join a local gathering to start a conversation.")
                    .scaledFont(16, maxScale: 1.3)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    Button { showNewChat = true } label: {
                        Text("Find parents")
                            .scaledFont(15, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(Theme.ink))
                    }
                    .buttonStyle(.plain)

                    Button { openTab(.gather) } label: {
                        Text("Join a gathering")
                            .scaledFont(15, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: 0xE6E1FF), in: .rect(cornerRadius: 28))
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
    }
}

// MARK: - Shared pieces

struct ChatAvatar: View {
    let thread: ChatThread
    var size: CGFloat = 56

    var body: some View {
        Text(thread.initials)
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(width: size, height: size)
            .background(Circle().fill(thread.avatarColor))
            .accessibilityHidden(true)
    }
}

/// One tick when sent, two when delivered, two in the accent colour once read.
struct ReadTicks: View {
    let status: MessageStatus

    var body: some View {
        HStack(spacing: -6) {
            Image(systemName: "checkmark")
            if status != .sent { Image(systemName: "checkmark") }
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(status == .read ? Theme.tabSelected : Theme.secondary)
        .accessibilityLabel(status == .sent ? "Sent" : (status == .delivered ? "Delivered" : "Read"))
    }
}
