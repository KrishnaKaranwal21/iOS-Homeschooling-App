import SwiftUI

/// Lets a `ChatThread.ID` be used with `.sheet(item:)`.
struct ThreadRef: Identifiable {
    let id: ChatThread.ID
}

// MARK: - Add or edit a label

/// Add a built-in filter back to the bar, or create (or edit) a custom label.
struct LabelEditorSheet: View {
    /// `nil` when adding.
    let editing: ChatLabel?

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorIndex = 0
    @State private var loaded = false

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    private var isDuplicate: Bool {
        state.chats.labels.contains {
            $0.id != editing?.id && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if editing == nil, !state.chats.removedBuiltIns.isEmpty {
                    Section("Add a filter") {
                        ForEach(state.chats.removedBuiltIns) { label in
                            Button {
                                state.chats.addBuiltIn(label)
                                dismiss()
                            } label: {
                                Label(label.name, systemImage: "plus.circle")
                                    .foregroundStyle(Theme.ink)
                            }
                        }
                    }
                }

                Section {
                    TextField("Label name", text: $name)
                        .scaledFont(17, maxScale: 1.3)
                        .submitLabel(.done)

                    HStack(spacing: 12) {
                        ForEach(ChatLabel.palette.indices, id: \.self) { index in
                            Button { colorIndex = index } label: {
                                Circle()
                                    .fill(ChatLabel.palette[index])
                                    .frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                                    .overlay {
                                        if colorIndex == index {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(Theme.ink)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Colour \(index + 1)")
                            .accessibilityAddTraits(colorIndex == index ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(editing == nil ? "Create a label" : "Edit label")
                } footer: {
                    if isDuplicate {
                        Text("You already have a label with this name.").foregroundStyle(Color.red)
                    } else {
                        Text("Add labels to chats, then filter by them or send one message to everyone under a label.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(editing == nil ? "New label" : "Edit label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Create" : "Save") { save() }
                        .disabled(trimmed.isEmpty || isDuplicate)
                }
            }
            .onAppear {
                guard !loaded, let editing else { return }
                loaded = true
                name = editing.name
                colorIndex = editing.colorIndex
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        if let editing {
            state.chats.updateLabel(editing.id, name: trimmed, colorIndex: colorIndex)
        } else if let created = state.chats.addCustomLabel(name: trimmed, colorIndex: colorIndex) {
            state.chats.select(created.id)
        }
        dismiss()
    }
}

// MARK: - Label a chat

/// Tick the labels that belong on one chat. A new label can be made right here.
struct ThreadLabelsSheet: View {
    let threadID: ChatThread.ID

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

    private var thread: ChatThread? { state.chats.thread(threadID) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: Binding(
                        get: { thread?.isFavourite ?? false },
                        set: { _ in state.chats.toggleFavourite(threadID) })) {
                        Label("Favourite", systemImage: "star")
                    }
                    .tint(Theme.tabSelected)
                }

                Section("Your labels") {
                    ForEach(state.chats.customLabels) { label in
                        Button { state.chats.toggleLabel(label.id, on: threadID) } label: {
                            HStack(spacing: 12) {
                                Circle().fill(label.color).frame(width: 14, height: 14)
                                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
                                Text(label.name).foregroundStyle(Theme.ink)
                                Spacer()
                                if thread?.labelIDs.contains(label.id) == true {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Theme.tabSelected)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .accessibilityAddTraits(thread?.labelIDs.contains(label.id) == true ? .isSelected : [])
                    }

                    HStack {
                        TextField("New label", text: $newName)
                            .submitLabel(.done)
                            .onSubmit(addLabel)
                        Button("Add", action: addLabel)
                            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(thread?.title ?? "Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    private func addLabel() {
        let used = state.chats.customLabels.count
        if let created = state.chats.addCustomLabel(name: newName, colorIndex: used % ChatLabel.palette.count) {
            state.chats.toggleLabel(created.id, on: threadID)
            newName = ""
        }
    }
}

// MARK: - Send to everyone under a label

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
                            Text("No chats have this label yet.")
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
                        .background(RoundedRectangle(cornerRadius: 21, style: .continuous).fill(Theme.field))

                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(canSend ? Color.white : Theme.secondary)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(canSend ? Theme.ink : Theme.field))
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
