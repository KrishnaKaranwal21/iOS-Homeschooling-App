import SwiftUI

// MARK: - ManageListView

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
                                    .scaledFont(20, weight: .semibold)
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

// MARK: - AddChatsToListSheet

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

// MARK: - ReorderListsSheet

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
