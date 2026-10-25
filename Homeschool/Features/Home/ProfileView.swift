import SwiftUI

/// Family profile: the parent's details, every child with their plan, and a way to edit or add one.
struct ProfileView: View {
    @Environment(AppState.self) private var state

    private struct EditTarget: Identifiable {
        let id = UUID()
        let child: Child
        let step: Int
        let singleStep: Bool
    }

    @State private var editTarget: EditTarget?
    @State private var showAdd = false
    @State private var showParentEdit = false

    private let lavenderCard = Color(hex: 0xE6E1FF)
    private let avatarColors: [Color] = [Theme.lavender, Theme.yellow, Theme.lime, Theme.pink]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                parentCard
                childrenSection
                addChildCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $editTarget) { target in
            EditChildFlow(child: target.child, startStep: target.step, singleStep: target.singleStep)
        }
        .fullScreenCover(isPresented: $showAdd) { AddChildFlow() }
        .sheet(isPresented: $showParentEdit) { ParentEditSheet() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .pageTitle()
                Text("You, your children and their plans.")
                    .pageSubtitle()
            }
            Spacer(minLength: 0)
            Image("HomeMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 92)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 4)
    }

    // MARK: Parent

    private var parentName: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "Add your name" : name
    }

    private var parentInitial: String {
        let source = state.account?.name.trimmingCharacters(in: .whitespaces).nonEmpty
            ?? state.account?.email ?? "P"
        return String(source.prefix(1)).uppercased()
    }

    private var parentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Text(parentInitial)
                    .scaledFont(24, weight: .heavy, maxScale: 1.15)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.white))
                VStack(alignment: .leading, spacing: 3) {
                    Text("PARENT OR GUARDIAN")
                        .scaledFont(11, weight: .medium, maxScale: 1.2)
                        .tracking(0.5)
                        .foregroundStyle(Theme.secondary)
                    Text(parentName)
                        .scaledFont(22, weight: .heavy, maxScale: 1.15)
                        .tracking(-0.4)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 8)
                Button { showParentEdit = true } label: {
                    Text("Edit")
                        .scaledFont(14, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .background(Capsule().fill(Color.white))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 0) {
                infoRow(icon: "envelope", title: "Email",
                        value: state.account?.email ?? "Not set", showsChevron: false)
                divider
                infoRow(icon: "phone", title: "Mobile",
                        value: (state.account?.mobile).flatMap { $0.isEmpty ? nil : $0 } ?? "Add a number",
                        showsChevron: true) { showParentEdit = true }
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(lavenderCard))
    }

    // MARK: Children

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(state.children.count == 1 ? "Your child" : "Your children")
                    .sectionTitle()
                Text("\(state.children.count)")
                    .scaledFont(13, weight: .semibold, maxScale: 1.2)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Capsule().fill(Theme.lavender))
            }
            .padding(.horizontal, 4)

            ForEach(Array(state.children.enumerated()), id: \.element.id) { index, child in
                childCard(child, color: avatarColors[index % avatarColors.count])
            }
        }
    }

    private func childCard(_ child: Child, color: Color) -> some View {
        let isCurrent = child.id == state.selectedChildID

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(String(child.displayName.prefix(1)).uppercased())
                    .scaledFont(22, weight: .heavy, maxScale: 1.15)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(color))
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                VStack(alignment: .leading, spacing: 5) {
                    Text(child.displayName)
                        .scaledFont(24, weight: .heavy, maxScale: 1.15)
                        .tracking(-0.5)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(child.programmeText)
                        .scaledFont(13, weight: .medium, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .frame(height: 24)
                        .background(Capsule().fill(Color.white))
                }
                Spacer(minLength: 0)
                if isCurrent {
                    Label("Viewing", systemImage: "checkmark.circle.fill")
                        .scaledFont(12, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(Capsule().fill(Color.white.opacity(0.75)))
                }
            }

            HStack(spacing: 8) {
                statTile(title: "Age", value: ageValue(child))
                statTile(title: "Subjects", value: "\(child.selectedSubjects.count)")
                statTile(title: "Per week", value: "\(child.learningDays.count * child.hoursPerDay)h")
            }

            VStack(spacing: 0) {
                infoRow(icon: "graduationcap", title: "Level", value: levelText(child), showsChevron: true) {
                    editTarget = EditTarget(child: child, step: 1, singleStep: false)
                }
                divider
                infoRow(icon: "birthday.cake", title: "Date of birth", value: dobText(child), showsChevron: true) {
                    editTarget = EditTarget(child: child, step: 1, singleStep: false)
                }
                divider
                infoRow(icon: "books.vertical", title: "Subjects", value: subjectsText(child), showsChevron: true) {
                    editTarget = EditTarget(child: child, step: 2, singleStep: true)
                }
                divider
                infoRow(icon: "calendar", title: "Learning rhythm", value: rhythmText(child), showsChevron: true) {
                    editTarget = EditTarget(child: child, step: 3, singleStep: true)
                }
            }
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))

            HStack(spacing: 10) {
                Button { editTarget = EditTarget(child: child, step: 1, singleStep: false) } label: {
                    Text("Edit details")
                        .scaledFont(15, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Capsule().fill(Theme.ink))
                }
                .buttonStyle(.plain)

                if !isCurrent {
                    Button { state.selectChild(child.id) } label: {
                        Text("Switch to \(child.displayName)")
                            .scaledFont(15, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Capsule().fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(isCurrent ? Theme.pink : Color(hex: 0xF1EFFA)))
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .scaledFont(20, weight: .heavy, maxScale: 1.15)
                .foregroundStyle(Theme.ink)
            Text(title)
                .scaledFont(12, weight: .medium, maxScale: 1.2)
                .foregroundStyle(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
        .accessibilityElement(children: .combine)
    }

    // MARK: Shared rows

    private var divider: some View {
        Rectangle().fill(Color.black.opacity(0.06)).frame(height: 1).padding(.leading, 52)
    }

    @ViewBuilder
    private func infoRow(icon: String, title: String, value: String, showsChevron: Bool,
                         action: (() -> Void)? = nil) -> some View {
        let content = HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.tabSelected)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .scaledFont(12, weight: .medium, maxScale: 1.2)
                    .foregroundStyle(Theme.secondary)
                Text(value)
                    .scaledFont(15, weight: .medium, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 8)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.dotInactive)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())

        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityLabel("\(title), \(value). Edit")
        } else {
            content.accessibilityElement(children: .combine)
        }
    }

    // MARK: Add a child

    private var addChildCard: some View {
        Button { showAdd = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(lavenderCard))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add a child")
                        .scaledFont(18, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                    Text("Set up another learner’s plan.")
                        .scaledFont(14, maxScale: 1.25)
                        .foregroundStyle(Theme.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Theme.tabIconInactive, style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            )
            .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Text helpers

    private func ageValue(_ child: Child) -> String {
        guard let birthDate = child.birthDate else { return "–" }
        return "\(AgeRules.age(of: birthDate, on: .now))"
    }

    private func levelText(_ child: Child) -> String {
        guard !child.level.isEmpty else { return "Not set" }
        if let grade = AgeRules.rules.first(where: { $0.level == child.level })?.grade {
            return "\(child.level) · \(grade)"
        }
        return child.level
    }

    private func dobText(_ child: Child) -> String {
        guard let birthDate = child.birthDate else { return "Not set" }
        return birthDate.formatted(date: .long, time: .omitted)
    }

    private func subjectsText(_ child: Child) -> String {
        let names = child.subjectNames
        guard !names.isEmpty else { return "None chosen yet" }
        let shown = names.prefix(3).joined(separator: ", ")
        return names.count > 3 ? "\(shown) +\(names.count - 3) more" : shown
    }

    private func rhythmText(_ child: Child) -> String {
        let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let days = order.filter { child.learningDays.contains($0) }
        guard !days.isEmpty else { return "No days chosen" }
        return "\(days.joined(separator: ", ")) · \(child.hoursPerDay)h a day"
    }
}

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

// MARK: - Edit parent details

private struct ParentEditSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var mobile = ""
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    field("Full name") {
                        TextField("Your full name", text: $name)
                            .textContentType(.name)
                    }
                    field("Mobile number") {
                        TextField("+91 98765 43210", text: $mobile)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email address")
                            .scaledFont(15, maxScale: 1.3)
                        Text(state.account?.email ?? "")
                            .scaledFont(17, maxScale: 1.3)
                            .foregroundStyle(Theme.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .gatherField()
                        Text("Your email is how you sign in, so it can’t be changed here.")
                            .scaledFont(13, maxScale: 1.3)
                            .foregroundStyle(Theme.secondary)
                    }

                    PrimaryButton(title: "Save") {
                        state.updateAccount(name: name, mobile: mobile)
                        dismiss()
                    }
                    .padding(.top, 6)
                }
                .foregroundStyle(Theme.ink)
                .padding(24)
            }
            .background(Theme.background)
            .navigationTitle("Your details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                name = state.account?.name ?? ""
                mobile = state.account?.mobile ?? ""
            }
        }
        .presentationDetents([.large])
    }

    private func field<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).scaledFont(15, maxScale: 1.3)
            content()
                .scaledFont(17, maxScale: 1.3)
                .gatherField()
        }
    }
}
