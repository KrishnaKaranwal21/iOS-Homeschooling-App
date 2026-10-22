import SwiftUI

struct ChatDetailView: View {
    let title: String
    @State private var messages = MockData.messages
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("Today").font(.caption).padding(.horizontal, 12).padding(.vertical, 4).background(Theme.field, in: Capsule())
                    ForEach(messages) { MessageBubble(message: $0) }
                }.padding()
            }
            HStack(spacing: 10) {
                Button { } label: { Image(systemName: "plus") }
                TextField("Message", text: $draft).padding(12).background(Theme.field, in: Capsule())
                Button(action: send) { Image(systemName: draft.isEmpty ? "mic.fill" : "arrow.up").padding(12).background(Theme.lime, in: Circle()) }
            }.padding()
        }
        .background(Theme.background)
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
    private func send() {
        guard !draft.isEmpty else { return }
        messages.append(Message(text: draft, time: Date.now.formatted(date: .omitted, time: .shortened), isMine: true))
        draft = ""
    }
}

private struct MessageBubble: View {
    let message: Message
    var body: some View {
        HStack {
            if message.isMine { Spacer(minLength: 48) }
            VStack(alignment: message.isMine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                Text(message.time).font(.caption2).foregroundStyle(Theme.secondary)
            }
            .padding(14)
            .background(message.isMine ? Theme.pink : Theme.field, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            if !message.isMine { Spacer(minLength: 48) }
        }
    }
}
