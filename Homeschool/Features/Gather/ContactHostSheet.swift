import SwiftUI

/// Ask the host a question. It goes to their chat in the Chats tab.
struct ContactHostSheet: View {
    let event: Event

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openTab) private var openTab

    @State private var message = ""
    @FocusState private var focused: Bool

    private let suggestions = [
        "What should we bring?",
        "Can my younger child join?",
        "Is there parking nearby?",
        "Is there a waiting list?"
    ]

    private var canSend: Bool { !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Text(String(event.host.prefix(1)).uppercased())
                            .scaledFont(18, weight: .bold, maxScale: 1.15)
                            .foregroundStyle(Theme.ink)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Theme.lavender))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.host).rowTitle()
                            Text("About “\\(event.title)”").rowDetail().lineLimit(1)
                        }
                    }

                    Text("Quick questions").sectionTitle()

                    FlowLayout(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button { message = suggestion } label: {
                                Text(suggestion)
                                    .scaledFont(14, weight: .medium, maxScale: 1.2)
                                    .foregroundStyle(Theme.ink)
                                    .padding(.horizontal, 14)
                                    .frame(height: 34)
                                    .background(Capsule().fill(Theme.field))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Your message").sectionTitle().padding(.top, 4)

                    TextField("Write your question", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                        .scaledFont(17, maxScale: 1.3)
                        .focused($focused)
                        .gatherField()

                    Text("The host replies in Chats.")
                        .caption()

                    PrimaryButton(title: "Send message", isDimmed: !canSend) {
                        guard canSend else { return }
                        send()
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle("Message host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.large])
    }

    private func send() {
        let id = state.chats.startChat(withHost: event.host, role: event.hostRole)
        state.chats.send(text: message, in: id)
        state.chats.pendingOpenID = id
        dismiss()
        openTab(.chats)
    }
}

/// Shown when someone tries to host with an unfinished profile.
struct CompleteProfileSheet: View {
    let missing: [String]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Theme.tabSelected)
                .padding(.top, 8)

            Text("Complete your profile to host")
                .detailTitle()

            Text("Families see who is hosting, so we need a few details first.")
                .pageSubtitle()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(missing, id: \.self) { item in
                    Label(item, systemImage: "circle")
                        .rowTitle()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))

            Spacer(minLength: 0)

            PrimaryButton(title: "Complete profile", action: onComplete)
            Button("Not now") { dismiss() }
                .scaledFont(16, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .padding(24)
        .background(Theme.background)
        .presentationDetents([.medium, .large])
    }
}
