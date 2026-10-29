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
                    TextField("List name", text: $name)
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
                    Text(editing == nil ? "Create a list" : "Edit list")
                } footer: {
                    if isDuplicate {
                        Text("You already have a list with this name.").foregroundStyle(Color.red)
                    } else {
                        Text("Add chats to a list, then filter by it or send one message to everyone in it.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle(editing == nil ? "New list" : "Edit list")
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

// MARK: - Add a chat to lists

/// Tick the lists that include one chat. A new label can be made right here.
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

                Section("Your lists") {
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
                        TextField("New list", text: $newName)
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
            .navigationTitle(thread?.title ?? "Lists")
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

// MARK: - Send to everyone in a list

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


// MARK: - Manage a list (members and notifications)

/// One list's page: who is in it, mute for everyone in it, rename or delete it.
struct ManageListView: View {
    let labelID: String

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var showAdd = false
    @State private var editing: ChatLabel?
    @State private var confirmDelete = false

    private var label: ChatLabel? { state.chats.labels.first { $0.id == labelID } }

    var body: some View {
        Group {
            if let label {
                List {
                    Section {
                        Button { showAdd = true } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                    .frame(width: 48, height: 48)
                                    .background(Circle().fill(Theme.lavender))
                                Text("Add people or groups")
                                    .scaledFont(17, maxScale: 1.3)
                                    .foregroundStyle(Theme.ink)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)

                        ForEach(state.chats.threads(for: label)) { thread in
                            HStack(spacing: 14) {
                                ChatAvatar(thread: thread, size: 48)
                                Text(thread.title)
                                    .scaledFont(17, maxScale: 1.3)
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    state.chats.setMember(false, threadID: thread.id, label: label)
                                } label: {
                                    Label("Remove", systemImage: "minus.circle")
                                }
                            }
                        }
                    } header: {
                        Text("Included")
                    } footer: {
                        Text("Swipe a chat to remove it from this list.")
                    }

                    Section("Notifications") {
                        Toggle("Mute notifications", isOn: Binding(
                            get: { state.chats.isMuted(label) },
                            set: { state.chats.setMuted($0, for: label) }))
                            .tint(Theme.tabSelected)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            } else {
                Color.clear
            }
        }
        .background(Theme.background)
        .navigationTitle(label?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let label, !label.isBuiltIn {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { confirmDelete = true } label: { Image(systemName: "trash") }
                        .accessibilityLabel("Delete list")
                    Button { editing = label } label: { Image(systemName: "pencil") }
                        .accessibilityLabel("Edit list")
                }
            }
        }
        .onChange(of: label == nil) { _, isGone in
            if isGone { dismiss() }
        }
        .sheet(isPresented: $showAdd) { AddChatsToListSheet(labelID: labelID) }
        .sheet(item: $editing) { LabelEditorSheet(editing: $0) }
        .confirmationDialog("Delete this list?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete list", role: .destructive) {
                state.chats.removeLabel(labelID)
                state.chats.showToast("List was deleted")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The chats stay. Only the list is removed.")
        }
    }
}

/// Tick the chats that belong in a list.
struct AddChatsToListSheet: View {
    let labelID: String

    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private var label: ChatLabel? { state.chats.labels.first { $0.id == labelID } }

    var body: some View {
        NavigationStack {
            List {
                if let label {
                    ForEach(state.chats.sortedThreads.filter { !$0.isLocked }) { thread in
                        let isIn = state.chats.matches(thread, label: label)
                        Button {
                            state.chats.setMember(!isIn, threadID: thread.id, label: label)
                        } label: {
                            HStack(spacing: 14) {
                                ChatAvatar(thread: thread, size: 44)
                                Text(thread.title)
                                    .scaledFont(17, maxScale: 1.3)
                                    .foregroundStyle(Theme.ink)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: isIn ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isIn ? Theme.tabSelected : Theme.dotInactive)
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isIn ? .isSelected : [])
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Add people or groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Reorder lists

/// Drag lists into a new order, remove the ones you don't want, and add presets back.
/// Nothing changes until you tap the tick.
struct ReorderListsSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    /// The lists in the bar without `All`, which always stays first.
    @State private var working: [ChatLabel] = []
    @State private var loaded = false

    private var availablePresets: [ChatLabel] {
        ChatLabel.builtIns.filter { preset in
            preset.id != ChatLabel.allID && !working.contains { $0.id == preset.id }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Your lists") {
                    ForEach(working) { label in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label.name)
                                    .scaledFont(18, maxScale: 1.3)
                                    .foregroundStyle(Theme.ink)
                                if label.isBuiltIn && label.id != ChatLabel.favourites.id {
                                    Text("Preset")
                                        .scaledFont(14, maxScale: 1.3)
                                        .foregroundStyle(Theme.secondary)
                                }
                            }
                            Spacer()
                            if label.id != ChatLabel.favourites.id {
                                Button { working.removeAll { $0.id == label.id } } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(Theme.secondary)
                                        .padding(8)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove \(label.name)")
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove { working.move(fromOffsets: $0, toOffset: $1) }
                }

                if !availablePresets.isEmpty {
                    Section("Available presets") {
                        ForEach(availablePresets) { preset in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(preset.name)
                                        .scaledFont(18, maxScale: 1.3)
                                        .foregroundStyle(Theme.ink)
                                    Text("Preset")
                                        .scaledFont(14, maxScale: 1.3)
                                        .foregroundStyle(Theme.secondary)
                                }
                                Spacer()
                                Button { working.append(preset) } label: {
                                    Text("Add")
                                        .scaledFont(16, weight: .semibold, maxScale: 1.3)
                                        .foregroundStyle(Theme.ink)
                                        .padding(.horizontal, 20)
                                        .frame(height: 38)
                                        .background(Capsule().fill(Theme.lavender))
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder lists")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        state.chats.applyBar(working)
                        dismiss()
                    } label: { Image(systemName: "checkmark") }
                        .accessibilityLabel("Save")
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                working = state.chats.labels.filter { $0.id != ChatLabel.allID }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Message at the bottom

/// Dark bar like "List was created", with an optional action.
struct ChatToastView: View {
    let toast: ChatToast
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(toast.message)
                .scaledFont(15, maxScale: 1.3)
                .foregroundStyle(Color.white)
            Spacer(minLength: 8)
            if let title = toast.actionTitle {
                Button(action: onAction) {
                    Text(title)
                        .scaledFont(15, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.lavender)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .background(Theme.ink, in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }
}
