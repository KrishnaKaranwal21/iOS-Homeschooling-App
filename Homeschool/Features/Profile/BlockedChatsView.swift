import SwiftUI

/// Chats the parent blocked, with a way to unblock them.
struct BlockedChatsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let blocked = state.chats.threads.filter(\.isBlocked)
        ScrollView {
            VStack(spacing: 18) {
                if blocked.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "nosign")
                            .scaledFont(36)
                            .foregroundStyle(Theme.tabIconInactive)
                        Text("No blocked chats")
                            .scaledFont(18, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        Text("People you block can’t message you. They show up here so you can unblock them.")
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                } else {
                    ProfileCard {
                        VStack(spacing: 12) {
                            ForEach(Array(blocked.enumerated()), id: \.element.id) { index, thread in
                                HStack(spacing: 14) {
                                    ChatAvatar(thread: thread, size: 44)
                                    Text(thread.title)
                                        .scaledFont(17, maxScale: 1.25)
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    Button { state.chats.toggleBlock(thread.id) } label: {
                                        Text("Unblock")
                                            .scaledFont(14, weight: .semibold, maxScale: 1.2)
                                            .foregroundStyle(Theme.ink)
                                            .padding(.horizontal, 14)
                                            .frame(height: 34)
                                            .background(Capsule().fill(Theme.lavender))
                                    }
                                    .buttonStyle(.plain)
                                }
                                if index < blocked.count - 1 { ProfileDivider() }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background)
        .navigationTitle("Blocked chats")
        .navigationBarTitleDisplayMode(.inline)
    }
}
