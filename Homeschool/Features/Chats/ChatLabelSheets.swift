import SwiftUI

// MARK: - ThreadRef

/// Lets a `ChatThread.ID` be used with `.sheet(item:)`.
struct ThreadRef: Identifiable {
    let id: ChatThread.ID
}

// MARK: - LabelEditorSheet

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
                                    .overlay(Circle().stroke(Theme.ink.opacity(0.12), lineWidth: 0.5))
                                    .overlay {
                                        if colorIndex == index {
                                            Image(systemName: "checkmark")
                                                .scaledFont(13, weight: .bold)
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

// MARK: - ThreadLabelsSheet

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
                                    .overlay(Circle().stroke(Theme.ink.opacity(0.12), lineWidth: 0.5))
                                Text(label.name).foregroundStyle(Theme.ink)
                                Spacer()
                                if thread?.labelIDs.contains(label.id) == true {
                                    Image(systemName: "checkmark")
                                        .scaledFont(15, weight: .bold)
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
