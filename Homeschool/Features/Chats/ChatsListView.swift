import SwiftUI

/// All conversations: search, filter chips and a swipeable list.
struct ChatsListView: View {
    @Environment(AppState.self) private var state

    private enum Filter: String, CaseIterable {
        case all = "All", unread = "Unread", groups = "Groups", direct = "Direct", muted = "Muted"
    }

    @State private var query = ""
    @State private var filter: Filter = .all
    @State private var openID: ChatThread.ID?
    @State private var showNewChat = false
    @State private var deleteTarget: ChatThread.ID?

    private let accent = Color(hex: 0xD9D2FF)
    private let unreadTime = Color(hex: 0x5B6B2F)

    private var threads: [ChatThread] {
        state.chats.sortedThreads.filter { thread in
            let matchesQuery = query.isEmpty
                || thread.title.localizedCaseInsensitiveContains(query)
                || thread.messages.contains { $0.text.localizedCaseInsensitiveContains(query) }
            let matchesFilter: Bool
            switch filter {
            case .all:    matchesFilter = true
            case .unread: matchesFilter = thread.hasUnread
            case .groups: matchesFilter = thread.isGroup
            case .direct: matchesFilter = !thread.isGroup
            case .muted:  matchesFilter = thread.isMuted
            }
            return matchesQuery && matchesFilter
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
        .sheet(isPresented: $showNewChat) {
            NewChatSheet { id in
                showNewChat = false
                // Wait for the sheet to close before opening the chat.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { openID = id }
            }
        }
        .confirmationDialog("Delete this chat?",
                            isPresented: Binding(get: { deleteTarget != nil },
                                                 set: { if !$0 { deleteTarget = nil } }),
                            titleVisibility: .visible) {
            Button("Delete chat", role: .destructive) {
                if let id = deleteTarget { state.chats.delete(id) }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        } message: {
            Text("The messages will be removed from this device.")
        }
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

    private var chips: some View {
        HStack(spacing: 8) {
            chip(.all)
            chip(.unread)
            chip(.groups)
            if filter == .direct || filter == .muted { chip(filter) }

            Menu {
                Button("Direct chats") { filter = .direct }
                Button("Muted") { filter = .muted }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 46, height: 36)
                    .background(Capsule().fill(Theme.field))
            }
            .accessibilityLabel("More filters")
            Spacer(minLength: 0)
        }
    }

    private func chip(_ value: Filter) -> some View {
        let selected = filter == value
        return Button { filter = value } label: {
            Text(value.rawValue)
                .scaledFont(15, weight: selected ? .semibold : .regular, maxScale: 1.2)
                .foregroundStyle(selected ? Theme.ink : Theme.secondary)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Capsule().fill(selected ? accent : Theme.field))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
                        Button(role: .destructive) { deleteTarget = thread.id } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button { state.chats.toggleMute(thread.id) } label: {
                            Label(thread.isMuted ? "Unmute" : "Mute",
                                  systemImage: thread.isMuted ? "bell" : "bell.slash")
                        }
                        .tint(Color(hex: 0x8E8E93))
                    }
                    .contextMenu {
                        Button { state.chats.togglePin(thread.id) } label: {
                            Label(thread.isPinned ? "Unpin chat" : "Pin chat", systemImage: "pin")
                        }
                        Button { state.chats.toggleMute(thread.id) } label: {
                            Label(thread.isMuted ? "Unmute" : "Mute", systemImage: "bell.slash")
                        }
                        Button { state.chats.markUnread(thread.id) } label: {
                            Label("Mark as unread", systemImage: "envelope.badge")
                        }
                        Button(role: .destructive) { deleteTarget = thread.id } label: {
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
                    Text(thread.title)
                        .scaledFont(17, weight: thread.hasUnread ? .semibold : .regular, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
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

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: query.isEmpty ? "bubble.left.and.bubble.right" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Theme.tabIconInactive)
            Text(query.isEmpty ? "No chats here yet" : "No results for “\(query)”")
                .scaledFont(20, weight: .heavy, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
            Text(query.isEmpty ? "Start a conversation with a parent near you." : "Try a name or a word from a message.")
                .scaledFont(15, maxScale: 1.3)
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
            if query.isEmpty && filter == .all {
                Button { showNewChat = true } label: {
                    Text("New chat")
                        .scaledFont(15, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 22)
                        .frame(height: 44)
                        .background(Capsule().fill(Theme.ink))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
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
