import SwiftUI
import LocalAuthentication

enum ChatAuth {
    /// Asks for Face ID, Touch ID or the passcode. A phone without any lock has nothing to ask, so it passes.
    @MainActor static func unlock(reason: String) async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else { return true }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }
}

/// The chats hidden with "Chat lock". Swipe a chat to take the lock off.
struct LockedChatsView: View {
    let onOpen: (ChatThread.ID) -> Void

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if state.chats.lockedThreads.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "lock")
                            .scaledFont(36)
                            .foregroundStyle(Theme.tabIconInactive)
                        Text("No locked chats")
                            .scaledFont(18, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        Text("Turn on Chat lock in a chat's info to hide it here.")
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                } else {
                    List {
                        ForEach(state.chats.lockedThreads) { thread in
                            Button { onOpen(thread.id) } label: {
                                HStack(spacing: 14) {
                                    ChatAvatar(thread: thread, size: 52)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(thread.title)
                                            .scaledFont(17, weight: .semibold, maxScale: 1.25)
                                            .foregroundStyle(Theme.ink)
                                        Text(thread.preview)
                                            .scaledFont(15, maxScale: 1.25)
                                            .foregroundStyle(Theme.secondary)
                                            .lineLimit(1)
                                    }
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button { state.chats.toggleLock(thread.id) } label: {
                                    Label("Unlock", systemImage: "lock.open")
                                }
                                .tint(Theme.tabSelected)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)
            .navigationTitle("Locked chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
