import SwiftUI

/// Sheet for sending one message to every reachable chat in a label; blocked chats are skipped.
struct BroadcastSheet: View {
    let label: ChatLabel

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var message = ""
    @FocusState private var focused: Bool

    private var recipients: [ChatThread] { state.chats.threads(for: label) }
    private var reachable: [ChatThread] { recipients.filter { !$0.isBlocked } }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section {
                        if recipients.isEmpty {
                            Text("No chats are in this list yet.")
                                .foregroundStyle(Theme.secondary)
                        }
                        ForEach(recipients) { thread in
                            HStack(spacing: 12) {
                                ChatAvatar(thread: thread, size: 38)
                                Text(thread.title).foregroundStyle(Theme.ink)
                                Spacer()
                                if thread.isBlocked {
                                    Text("Blocked, skipped")
                                        .scaledFont(12, maxScale: 1.2)
                                        .foregroundStyle(Theme.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("To everyone in \(label.name) (\(reachable.count))")
                    } footer: {
                        Text("Each chat gets its own copy, and replies come back to that chat only.")
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)

                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(1...4)
                        .scaledFont(17, maxScale: 1.3)
                        .focused($focused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(minHeight: 42)
                        .background(Theme.field, in: .rect(cornerRadius: 21))

                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .scaledFont(16, weight: .bold)
                            .foregroundStyle(canSend ? Color.white : Theme.secondary)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(canSend ? Theme.buttonFill : Theme.field))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend)
                    .accessibilityLabel("Send to \(reachable.count) chats")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.background)
            }
            .background(Theme.background)
            .navigationTitle("Send to \(label.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear { focused = true }
        }
        .presentationDetents([.large])
    }

    private var canSend: Bool {
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !reachable.isEmpty
    }

    private func send() {
        state.chats.broadcast(message, to: label.id)
        dismiss()
    }
}
