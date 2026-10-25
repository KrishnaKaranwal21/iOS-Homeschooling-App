import SwiftUI
import PhotosUI

/// One conversation: day-grouped bubbles, a message bar and a menu with chat settings.
struct ChatDetailView: View {
    let threadID: ChatThread.ID

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ""
    @State private var showInfo = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var composerFocused: Bool

    private var thread: ChatThread? { state.chats.thread(threadID) }

    private var visibleMessages: [ChatMessage] {
        guard let thread else { return [] }
        guard isSearching, !searchText.isEmpty else { return thread.messages }
        return thread.messages.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    /// Messages grouped by calendar day, oldest first.
    private var days: [(day: Date, messages: [ChatMessage])] {
        let grouped = Dictionary(grouping: visibleMessages) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted().map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        Group {
            if let thread {
                content(thread)
            } else {
                Color.clear
            }
        }
        .background(Theme.background)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: thread == nil) { _, isGone in
            if isGone { dismiss() }
        }
        .onAppear { state.chats.markRead(threadID) }
    }

    // MARK: Layout

    private func content(_ thread: ChatThread) -> some View {
        VStack(spacing: 0) {
            if isSearching { searchBar }
            messageList(thread)
        }
        // The message bar sits in the bottom safe area, so it rises with the keyboard
        // and stays clear of the home indicator. The title bar stays clear of the Dynamic Island.
        .safeAreaInset(edge: .bottom, spacing: 0) { composerArea(thread) }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button { showInfo = true } label: {
                    HStack(spacing: 10) {
                        ChatAvatar(thread: thread, size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(thread.title)
                                .scaledFont(17, weight: .bold, maxScale: 1.15)
                                .foregroundStyle(Theme.ink)
                                .lineLimit(1)
                            if !thread.subtitle.isEmpty {
                                Text(thread.subtitle)
                                    .scaledFont(12, maxScale: 1.15)
                                    .foregroundStyle(Theme.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(thread.title). Chat info")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showInfo = true } label: {
                        Label(thread.isGroup ? "Group info" : "View info", systemImage: "info.circle")
                    }
                    Button { startSearch() } label: { Label("Search", systemImage: "magnifyingglass") }
                    Button { state.chats.toggleMute(threadID) } label: {
                        Label(thread.isMuted ? "Unmute notifications" : "Mute notifications",
                              systemImage: thread.isMuted ? "bell" : "bell.slash")
                    }
                    Button(role: .destructive) { state.chats.clear(threadID) } label: {
                        Label("Clear chat", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More")
            }
        }
        .navigationDestination(isPresented: $showInfo) {
            ChatInfoView(threadID: threadID) { startSearch() }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.secondary)
                TextField("Search in chat", text: $searchText)
                    .scaledFont(16, maxScale: 1.3)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Capsule().fill(Theme.field))

            Button("Cancel") {
                isSearching = false
                searchText = ""
            }
            .foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func startSearch() {
        isSearching = true
    }

    // MARK: Messages

    private func messageList(_ thread: ChatThread) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 6) {
                    if thread.messages.isEmpty {
                        emptyChat(thread)
                    } else if visibleMessages.isEmpty {
                        Text("No messages match “\(searchText)”")
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.secondary)
                            .padding(.top, 40)
                    }

                    ForEach(days, id: \.day) { group in
                        dayPill(group.day)
                        ForEach(group.messages) { message in
                            bubble(message, in: thread)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            .onChange(of: composerFocused) { _, focused in
                // Keep the latest message visible when the keyboard opens.
                guard focused, let last = thread.messages.last else { return }
                withAnimation(.snappy) { proxy.scrollTo(last.id, anchor: .bottom) }
            }
            .onChange(of: thread.messages.count) {
                guard let last = thread.messages.last else { return }
                withAnimation(.snappy) { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private func emptyChat(_ thread: ChatThread) -> some View {
        VStack(spacing: 8) {
            ChatAvatar(thread: thread, size: 72)
            Text(thread.isGroup ? "Say hello to the group" : "Say hello to \(thread.title)")
                .scaledFont(18, weight: .bold, maxScale: 1.2)
                .foregroundStyle(Theme.ink)
            Text("Messages you send here stay between you and \(thread.isGroup ? "the group" : "them").")
                .scaledFont(14, maxScale: 1.3)
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 30)
    }

    private func dayPill(_ date: Date) -> some View {
        Text(ChatFormat.dayHeader(date))
            .scaledFont(13, maxScale: 1.2)
            .foregroundStyle(Theme.secondary)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background(Capsule().fill(Theme.field))
            .padding(.vertical, 8)
    }

    private func bubble(_ message: ChatMessage, in thread: ChatThread) -> some View {
        let mine = message.isMine
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 22,
            bottomLeadingRadius: mine ? 22 : 6,
            bottomTrailingRadius: mine ? 6 : 22,
            topTrailingRadius: 22,
            style: .continuous)

        return HStack {
            if mine { Spacer(minLength: 56) }
            VStack(alignment: .leading, spacing: 4) {
                if thread.isGroup, !mine, let sender = message.sender {
                    Text(sender)
                        .scaledFont(13, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.tabSelected)
                }
                if let data = message.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("Photo")
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .scaledFont(17, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 4) {
                    Spacer(minLength: 0)
                    Text(ChatFormat.clock(message.date))
                        .scaledFont(12, maxScale: 1.2)
                        .foregroundStyle(Theme.secondary)
                    if mine { ReadTicks(status: message.status) }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(shape.fill(mine ? Theme.pink : Color(hex: 0xF0F1F4)))
            .contextMenu {
                if !message.text.isEmpty {
                    Button { UIPasteboard.general.string = message.text } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                }
                Button(role: .destructive) {
                    state.chats.deleteMessage(message.id, in: threadID)
                } label: {
                    Label("Delete for me", systemImage: "trash")
                }
            }
            if !mine { Spacer(minLength: 56) }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    // MARK: Composer

    @ViewBuilder
    private func composerArea(_ thread: ChatThread) -> some View {
        if thread.isBlocked {
            Button { state.chats.toggleBlock(threadID) } label: {
                Text("You blocked \(thread.title). Tap to unblock.")
                    .scaledFont(15, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.field)
            }
            .buttonStyle(.plain)
        } else {
            composer
        }
    }

    private var composer: some View {
        let hasText = !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return HStack(alignment: .bottom, spacing: 10) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Theme.field))
            }
            .accessibilityLabel("Attach a photo")
            .onChange(of: photoItem) { _, item in loadPhoto(item) }

            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .scaledFont(17, maxScale: 1.3)
                .foregroundStyle(Theme.ink)
                .focused($composerFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(minHeight: 42)
                .background(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(Theme.field))

            Button(action: sendDraft) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(hasText ? Color.white : Theme.secondary)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(hasText ? Theme.ink : Theme.field))
            }
            .buttonStyle(.plain)
            .disabled(!hasText)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Theme.background)
    }

    private func sendDraft() {
        state.chats.send(text: draft, in: threadID)
        draft = ""
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            defer { photoItem = nil }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            // Keep the saved size small.
            let maxSide: CGFloat = 1000
            let scale = min(1, maxSide / max(image.size.width, image.size.height))
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let resized = UIGraphicsImageRenderer(size: size).jpegData(withCompressionQuality: 0.75) { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
            state.chats.send(text: "", imageData: resized, in: threadID)
        }
    }
}
