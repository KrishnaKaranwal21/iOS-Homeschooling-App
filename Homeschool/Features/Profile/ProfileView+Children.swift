import SwiftUI

/// The "Children" tab of the profile: one card per child with its editable details.
extension ProfileView {
    // MARK: Children tab

    var childrenTab: some View {
        VStack(spacing: 18) {
            ForEach(state.children) { child in
                childCard(child)
            }

            Button { showAdd = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .scaledFont(16, weight: .semibold)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Theme.lavender))
                    Text("Add a child")
                        .scaledFont(17, weight: .semibold, maxScale: 1.25)
                }
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, minHeight: 68)
                .background {
                    let shape: RoundedRectangle = .rect(cornerRadius: 26)
                    shape.strokeBorder(Theme.lilacBorder, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                }
                .contentShape(.rect(cornerRadius: 26))
            }
            .buttonStyle(.plain)
        }
    }

    func toggleInterest(_ name: String, for child: Child) {
        guard let index = state.children.firstIndex(where: { $0.id == child.id }) else { return }
        if state.children[index].interests.contains(name) {
            state.children[index].interests.remove(name)
        } else {
            state.children[index].interests.insert(name)
        }
    }

    func childCard(_ child: Child) -> some View {
        let isCurrent = child.id == state.selectedChildID

        return ProfileCard {
            Button { openHome(with: child) } label: {
                HStack(spacing: 14) {
                    Text(String(child.displayName.prefix(1)).uppercased())
                        .scaledFont(24, weight: .bold)
                        .foregroundStyle(Theme.ink)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(Theme.lavender))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(child.displayName)
                            .scaledFont(20, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        Text(child.programmeText)
                            .scaledFont(14, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                    }
                    Spacer(minLength: 8)
                    if isCurrent {
                        Text("Viewing")
                            .scaledFont(12, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Theme.lavender))
                    }
                    Image(systemName: "chevron.right").accessibilityHidden(true)
                        .scaledFont(12, weight: .semibold)
                        .foregroundStyle(Theme.dotInactive)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(child.displayName). Open Home")

            ProfileDivider()

            VStack(spacing: 4) {
                editRow("person", "Name", child.displayName) {
                    renameID = child.id
                    renameText = child.name
                    showRename = true
                }
                levelMenuRow(child)
                ChildDOBRow(child: child) { openSubjects(for: $0) }
                editRow("books.vertical", "Subjects", subjectsText(child)) {
                    editTarget = EditTarget(child: child, step: 2, singleStep: true)
                }
                editRow("clock", "Learning rhythm", rhythmText(child)) {
                    editTarget = EditTarget(child: child, step: 3, singleStep: true)
                }
            }

            ProfileDivider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Interests")
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                Text("Shown to other parents so they can find you.")
                    .scaledFont(13, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                FlowLayout(spacing: 8) {
                    ForEach(CommunityOptions.interests, id: \.self) { name in
                        SelectableChip(title: name, isOn: child.interests.contains(name)) {
                            toggleInterest(name, for: child)
                        }
                    }
                }
            }

            ProfileDivider()

            VStack(alignment: .leading, spacing: 12) {
                Text("NIOS exams")
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                ExamRows(child: child)
            }

            Button {
                if state.children.count < 2 {
                    showCannotRemove = true
                } else {
                    removeID = child.id
                    removeName = child.displayName
                    showRemove = true
                }
            } label: {
                Label("Remove child", systemImage: "trash")
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// Same picker as the child setup page. A new level clears the subjects, so they open next.
    func levelMenuRow(_ child: Child) -> some View {
        ProfileInfoRow(symbol: "graduationcap", title: "NIOS level", value: levelText(child))
            .overlay {
                Menu {
                    ForEach(Curriculum.levels, id: \.self) { level in
                        Button("\(Curriculum.displayName(for: level)) · \(AgeRules.rule(for: level)?.grade ?? "")") {
                            if let changed = state.changeLevel(of: child.id, to: level) {
                                openSubjects(for: changed)
                            }
                        }
                    }
                } label: {
                    Color.clear.contentShape(Rectangle())
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityHint("Opens a list of levels")
    }

    /// Opens the subjects page once the menu or calendar has closed.
    func openSubjects(for child: Child) {
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            editTarget = EditTarget(child: child, step: 2, singleStep: true)
        }
    }

    func saveName() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let id = renameID,
              var changed = state.children.first(where: { $0.id == id }) else { return }
        changed.name = trimmed
        state.updateChild(changed)
    }

    func editRow(_ symbol: String, _ title: String, _ value: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ProfileInfoRow(symbol: symbol, title: title, value: value)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(value). Edit")
    }

    /// Picks the child and goes back to Home.
    func openHome(with child: Child) {
        state.selectChild(child.id)
        dismiss()
    }

    // MARK: Text helpers

    func levelText(_ child: Child) -> String {
        guard !child.level.isEmpty else { return "Not set" }
        return Curriculum.displayName(for: child.level)
    }

    func subjectsText(_ child: Child) -> String {
        let names = child.subjectNames
        guard !names.isEmpty else { return "None chosen yet" }
        let shown = names.prefix(2).joined(separator: ", ")
        return names.count > 2 ? "\(shown) +\(names.count - 2)" : shown
    }

    func rhythmText(_ child: Child) -> String {
        let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let days = order.filter { child.learningDays.contains($0) }
        guard !days.isEmpty else { return "No days chosen" }
        return "\(days.count) days · \(child.hoursPerDay)h"
    }
}
