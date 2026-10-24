import SwiftUI

/// The child chip at the top of Home. Tapping it lists every child and an "Add a child" action.
struct ChildSwitcherMenu<Content: View>: View {
    @Environment(AppState.self) private var state
    /// The screen that shows this menu presents the add-child pages, because a menu inside a toolbar can't reliably present them itself.
    let onAddChild: () -> Void
    let label: Content

    init(onAddChild: @escaping () -> Void, @ViewBuilder label: () -> Content) {
        self.onAddChild = onAddChild
        self.label = label()
    }

    var body: some View {
        Menu {
            ForEach(state.children) { child in
                Button {
                    state.selectChild(child.id)
                } label: {
                    if child.id == state.selectedChildID {
                        Label(child.displayName, systemImage: "checkmark")
                    } else {
                        Text(child.displayName)
                    }
                }
            }
            Divider()
            Button(action: onAddChild) {
                Label("Add a child", systemImage: "plus")
            }
        } label: {
            label
        }
        .accessibilityLabel("Switch child, \(state.child.displayName)")
    }
}

/// The same three setup pages, for a brand-new child.
struct AddChildFlow: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var draft = Child.empty

    var body: some View {
        ChildSetupSteps(child: $draft, mode: .addChild, onCancel: { dismiss() }) {
            state.addChild(draft)
            dismiss()
        }
    }
}

/// The same three setup pages, opened on the page that holds the detail being edited.
struct EditChildFlow: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Child
    let startStep: Int
    let singleStep: Bool

    init(child: Child, startStep: Int, singleStep: Bool = false) {
        _draft = State(initialValue: child)
        self.startStep = startStep
        self.singleStep = singleStep
    }

    var body: some View {
        ChildSetupSteps(child: $draft, mode: .editChild, startStep: startStep, singleStep: singleStep,
                        onCancel: { dismiss() }) {
            state.updateChild(draft)
            dismiss()
        }
    }
}
