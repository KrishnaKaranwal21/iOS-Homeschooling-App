import SwiftUI

/// Shared child picker used by Home, the weekly plan and Progress.
struct ChildSwitcherMenu<Content: View>: View {
    @Environment(AppState.self) private var state
    @State private var isPresented = false
    @State private var pendingAction: ChildSwitcherAction?
    let onAddChild: () -> Void
    let label: Content

    init(onAddChild: @escaping () -> Void, @ViewBuilder label: () -> Content) {
        self.onAddChild = onAddChild
        self.label = label()
    }

    var body: some View {
        Button { isPresented.toggle() } label: {
            label.frame(minHeight: 44).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Switch child, \(state.child.displayName)")
        .accessibilityHint("Choose a learner or add a child")
        .accessibilityIdentifier("child.switcher")
        .popover(isPresented: $isPresented) {
            ChildSwitcherPopover(children: state.children, selectedID: state.selectedChildID) { childID in
                pendingAction = .select(childID)
                isPresented = false
            } onAddChild: {
                pendingAction = .add
                isPresented = false
            }
            .presentationCompactAdaptation(.popover)
            .presentationBackground(Theme.surface)
            .presentationCornerRadius(24)
            .onDisappear(perform: finishSelection)
        }
        .sensoryFeedback(.selection, trigger: state.selectedChildID)
    }

    private func finishSelection() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        // Let the popover close before changing the page or presenting child setup.
        Task { @MainActor in
            await Task.yield()
            switch action {
            case .select(let childID): state.selectChild(childID)
            case .add: onAddChild()
            }
        }
    }
}

private enum ChildSwitcherAction {
    case select(Child.ID)
    case add
}

struct ChildSwitcherPopover: View {
    let children: [Child]
    let selectedID: Child.ID
    let onSelect: (Child.ID) -> Void
    let onAddChild: () -> Void

    private var listHeight: CGFloat {
        min(300, CGFloat(children.count) * 60 + CGFloat(max(0, children.count - 1)) * 6)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Switch child").scaledFont(15, weight: .semibold, maxScale: 1.3)
                    .foregroundStyle(Theme.ink).accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(children.count) \(children.count == 1 ? "profile" : "profiles")")
                    .scaledFont(11, maxScale: 1.3).foregroundStyle(Theme.secondary)
            }
            .padding(.horizontal, 10).padding(.top, 6)

            if !children.isEmpty {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                            childRow(child, index: index)
                        }
                    }
                }
                .frame(height: listHeight)
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }

            Rectangle().fill(Theme.cardBorder).frame(height: 1).padding(.horizontal, 10)

            Button(action: onAddChild) {
                HStack(spacing: 12) {
                    Image(systemName: "plus").font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 36, height: 36).background(Theme.lilac, in: Circle())
                    Text("Add a child").scaledFont(15, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                }
                .padding(.horizontal, 10).frame(minHeight: 56).contentShape(Rectangle())
                .background(Theme.field.opacity(0.65), in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("child.switcher.add")
        }
        .padding(12).frame(width: 288)
    }

    private func childRow(_ child: Child, index: Int) -> some View {
        let selected = child.id == selectedID
        let colors = [Theme.lavender, Theme.pink, Theme.yellow]
        return Button { onSelect(child.id) } label: {
            HStack(spacing: 12) {
                AvatarView(initials: String(child.displayName.prefix(1)).uppercased(),
                    color: colors[index % colors.count], size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(child.displayName).scaledFont(16, weight: .semibold, maxScale: 1.3)
                        .foregroundStyle(Theme.ink).lineLimit(1).minimumScaleFactor(0.85)
                    if !child.level.isEmpty {
                        Text(child.programmeText).scaledFont(11, maxScale: 1.3)
                            .foregroundStyle(Theme.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(selected ? Theme.accent : Theme.cardBorder)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10).frame(minHeight: 60).contentShape(Rectangle())
            .background(selected ? Theme.lilac.opacity(0.8) : .clear, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(child.level.isEmpty ? child.displayName : "\(child.displayName), \(child.programmeText)")
        .accessibilityAddTraits(selected ? .isSelected : [])
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
