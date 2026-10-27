import SwiftUI

/// Family profile, laid out like the Settings app: a grouped list with a large title.
struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private struct EditTarget: Identifiable {
        let id = UUID()
        let child: Child
        let step: Int
        let singleStep: Bool
    }

    private enum ProfileSection: String, CaseIterable, Identifiable {
        case parent = "Parent", children = "Children", settings = "Settings"
        var id: String { rawValue }
    }

    @State private var editTarget: EditTarget?
    @State private var showAdd = false
    @State private var showParentEdit = false
    @State private var showLocationPicker = false
    @State private var levelTarget: Child?
    /// Set when a level changed, so the subjects page opens once the level sheet has closed.
    @State private var pendingSubjectsEdit: Child?
    @State private var jump: ProfileSection = .parent

    private let avatarColors: [Color] = [Theme.lavender, Theme.yellow, Theme.lime, Theme.pink]

    var body: some View {
        ScrollViewReader { proxy in
            List {
                examBanner

                profileHeader
                    .id("profile-\(ProfileSection.parent.rawValue)")

                parentSection

                childrenSections

                Section {
                    Button { showAdd = true } label: {
                        Label("Add a child", systemImage: "plus.circle.fill")
                    }
                }

                settingsSection
                    .id("profile-\(ProfileSection.settings.rawValue)")
            }
            .listStyle(.insetGrouped)
            .tint(Theme.tabSelected)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            // Shortcuts to the three parts of a long page.
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Jump to", selection: $jump) {
                    ForEach(ProfileSection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .onChange(of: jump) { _, section in
                withAnimation(.smooth) { proxy.scrollTo("profile-\(section.rawValue)", anchor: .top) }
            }
        }
        .fullScreenCover(item: $editTarget) { target in
            EditChildFlow(child: target.child, startStep: target.step, singleStep: target.singleStep)
        }
        .fullScreenCover(isPresented: $showAdd) { AddChildFlow() }
        .sheet(isPresented: $showParentEdit) { ParentEditSheet() }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(allowsWorld: false, selection: state.homeLocation,
                                home: state.homeLocation) { state.homeLocation = $0 }
        }
        .sheet(item: $levelTarget, onDismiss: {
            if let changed = pendingSubjectsEdit {
                pendingSubjectsEdit = nil
                editTarget = EditTarget(child: changed, step: 2, singleStep: true)
            }
        }) { child in
            LevelPickerSheet(child: child) { pendingSubjectsEdit = $0 }
        }
        .onChange(of: state.locationService.status) { _, status in
            // If location access was refused, the switch goes back off and a city is needed.
            if status == .denied, state.usesLiveLocation {
                state.usesLiveLocation = false
                showLocationPicker = true
            }
        }
    }

    // MARK: Exam reminder

    @ViewBuilder private var examBanner: some View {
        let urgent = state.children.filter(\.examNeedsAttention)
        if !urgent.isEmpty {
            Section {
                ForEach(urgent) { child in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(child.displayName)’s exam form")
                                .font(.headline)
                            Text(bannerText(for: child))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .listRowBackground(Color(hex: 0xFFEBD9))
        }
    }

    private func bannerText(for child: Child) -> String {
        guard let days = child.daysUntilExamDeadline else { return "" }
        switch days {
        case ..<0: return "The last date passed \(-days) \(-days == 1 ? "day" : "days") ago. Check with NIOS."
        case 0:    return "The last date to register is today."
        case 1:    return "The last date to register is tomorrow."
        default:   return "\(days) days left to register for the exams."
        }
    }

    // MARK: Parent

    private var parentName: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "Add your name" : name
    }

    private var parentInitial: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return String((name.isEmpty ? (state.account?.email ?? "P") : name).prefix(1)).uppercased()
    }

    private var profileHeader: some View {
        Section {
            Button { showParentEdit = true } label: {
                HStack(spacing: 14) {
                    Text(parentInitial)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 64, height: 64)
                        .background(Circle().fill(Theme.lavender))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(parentName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(state.account?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityLabel("\(parentName). Edit your details")
        }
    }

    private var parentSection: some View {
        Section("Parent or guardian") {
            Button { showParentEdit = true } label: {
                LabeledContent("Mobile",
                               value: (state.account?.mobile).flatMap { $0.isEmpty ? nil : $0 } ?? "Add a number")
            }
            .foregroundStyle(.primary)
            LabeledContent("Email", value: state.account?.email ?? "Not set")
        }
    }

    // MARK: Children

    @ViewBuilder private var childrenSections: some View {
        ForEach(Array(state.children.enumerated()), id: \.element.id) { index, child in
            // Only the first child carries the "Children" shortcut id, so no two rows share one.
            childSection(child, color: avatarColors[index % avatarColors.count])
                .id(index == 0 ? "profile-\(ProfileSection.children.rawValue)" : child.id.uuidString)
        }
    }

    private func childSection(_ child: Child, color: Color) -> some View {
        let isCurrent = child.id == state.selectedChildID

        return Section {
            Button { openHome(with: child) } label: {
                HStack(spacing: 14) {
                    Text(String(child.displayName.prefix(1)).uppercased())
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(color))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(child.programmeText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isCurrent {
                        Text("Viewing")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Theme.lavender))
                    }
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .accessibilityLabel("\(child.displayName). Open Home")

            editRow("NIOS level", value: levelText(child)) { levelTarget = child }
            editRow("Date of birth", value: dobText(child)) {
                editTarget = EditTarget(child: child, step: 1, singleStep: false)
            }
            editRow("Subjects", value: subjectsText(child)) {
                editTarget = EditTarget(child: child, step: 2, singleStep: true)
            }
            editRow("Learning rhythm", value: rhythmText(child)) {
                editTarget = EditTarget(child: child, step: 3, singleStep: true)
            }

            ExamRows(child: child)

            Button { editTarget = EditTarget(child: child, step: 1, singleStep: false) } label: {
                Label("Edit all details", systemImage: "pencil")
            }
        } header: {
            Text(state.children.count == 1 ? "Your child" : child.displayName)
        }
    }

    private func editRow(_ title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            LabeledContent {
                HStack(spacing: 6) {
                    Text(value)
                        .multilineTextAlignment(.trailing)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            } label: {
                Text(title)
            }
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("\(title), \(value). Edit")
    }

    /// Picks the child and goes back to Home.
    private func openHome(with child: Child) {
        state.selectChild(child.id)
        dismiss()
    }

    // MARK: Settings

    private var settingsSection: some View {
        Section {
            Toggle("Show my approximate live location", isOn: Binding(
                get: { state.usesLiveLocation },
                set: { on in
                    state.setLiveLocation(on)
                    // Without live location the family chooses a city.
                    if !on { showLocationPicker = true }
                }))

            if state.usesLiveLocation {
                LabeledContent("Area") {
                    if state.locationService.status == .locating {
                        ProgressView()
                    } else {
                        Text(state.homeLocation.name)
                    }
                }
            } else {
                Button { showLocationPicker = true } label: {
                    LabeledContent {
                        HStack(spacing: 6) {
                            Text(state.homeLocation.name)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                    } label: {
                        Text("City")
                    }
                }
                .foregroundStyle(.primary)
            }

            Picker("Community distance", selection: Binding(
                get: { state.communityRadiusKm },
                set: { state.communityRadiusKm = $0 })) {
                ForEach([1, 2, 3, 5, 10, 20], id: \.self) { Text("\($0) km").tag($0) }
            }
        } header: {
            Text("Settings")
        } footer: {
            Text(state.usesLiveLocation
                 ? "Only your approximate area is used, never your exact position. “Near you” in Gather and the Community list follow it."
                 : "Choose your city. “Near you” in Gather and the Community list use it.")
        }
    }

    // MARK: Text helpers

    private func levelText(_ child: Child) -> String {
        guard !child.level.isEmpty else { return "Not set" }
        let name = Curriculum.displayName(for: child.level)
        if let grade = AgeRules.rules.first(where: { $0.level == child.level })?.grade {
            return "\(name) · \(grade)"
        }
        return name
    }

    private func dobText(_ child: Child) -> String {
        guard let birthDate = child.birthDate else { return "Not set" }
        return birthDate.formatted(date: .long, time: .omitted)
    }

    private func subjectsText(_ child: Child) -> String {
        let names = child.subjectNames
        guard !names.isEmpty else { return "None chosen yet" }
        let shown = names.prefix(2).joined(separator: ", ")
        return names.count > 2 ? "\(shown) +\(names.count - 2)" : shown
    }

    private func rhythmText(_ child: Child) -> String {
        let order = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let days = order.filter { child.learningDays.contains($0) }
        guard !days.isEmpty else { return "No days chosen" }
        return "\(days.count) days · \(child.hoursPerDay)h"
    }
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
            Form {
                Section("Your details") {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                    PhoneField(number: $mobile)
                    LabeledContent("Email", value: state.account?.email ?? "")
                }
                Section {
                } footer: {
                    Text("Your email is how you sign in, so it can’t be changed here.")
                }
            }
            .navigationTitle("Your details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        state.updateAccount(name: name, mobile: mobile)
                        dismiss()
                    }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                name = state.account?.name ?? ""
                mobile = state.account?.mobile ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }
}
