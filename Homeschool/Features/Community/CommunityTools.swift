import SwiftUI

/// The optional introduction uses the original Community request flow.
struct CommunityRequestSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let parent: Parent
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 14) {
                        ParentAvatar(parent: parent, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Say hello to \(parent.firstName)").sectionTitle()
                            Text("A small introduction can start a lovely connection.").rowDetail()
                        }
                    }
                    ProfileCard(symbol: "text.bubble", title: "Your introduction", subtitle: "Optional · up to 300 characters") {
                        TextField("What would your family like to connect for?", text: $note, axis: .vertical)
                            .lineLimit(3...5)
                            .onChange(of: note) { _, value in note = String(value.prefix(300)) }
                        Text("\(note.count)/300").font(.caption).foregroundStyle(Theme.secondary)
                    }
                    Text("You can start chatting once \(parent.firstName) accepts your request.")
                        .font(.footnote).foregroundStyle(Theme.secondary)
                }.padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                Button("Send request") {
                    if state.sendRequest(to: parent, note: note) { dismiss() }
                }
                .buttonStyle(.primaryHomeschool)
                .padding(.horizontal, 24).padding(.vertical, 12).background(.bar)
            }
            .background(Theme.background)
            .navigationTitle("Connect").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
