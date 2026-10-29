import SwiftUI

/// The family's profile: a hero card, then three tabs (Parent, Children, Settings) made of cards.
/// What other parents see on the community profile is edited here too.
struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    private struct EditTarget: Identifiable {
        let id = UUID()
        let child: Child
        let step: Int
        let singleStep: Bool
    }

    private enum ProfileTab: String, CaseIterable, Identifiable {
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
    @State private var tab: ProfileTab = .parent
    @Namespace private var tabNamespace

    private let avatarColors: [Color] = [Theme.lavender, Theme.yellow, Theme.lime, Theme.pink]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                examBanner
                hero

                Group {
                    switch tab {
                    case .parent:   parentTab
                    case .children: childrenTab
                    case .settings: settingsTab
                    }
                }
                .transition(.opacity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollNavigationTitle("Profile")
        .background(Theme.background)
        .navigationBarTitleDisplayMode(.inline)
        // The three parts stay in reach while scrolling.
        .safeAreaInset(edge: .top, spacing: 0) { tabBar }
        .animation(.snappy, value: tab)
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

    // MARK: Tabs

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(ProfileTab.allCases) { item in
                Button { tab = item } label: {
                    Text(item.rawValue)
                        .scaledFont(15, weight: tab == item ? .semibold : .regular, maxScale: 1.2)
                        .foregroundStyle(tab == item ? Theme.ink : Theme.gatherText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background {
                            if tab == item {
                                Capsule().fill(Theme.lavender)
                                    .matchedGeometryEffect(id: "tab", in: tabNamespace)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == item ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Capsule().fill(Theme.chipFill))
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.bar)
        .sensoryFeedback(.selection, trigger: tab)
    }

    // MARK: Top

    private var parentName: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "Add your name" : name
    }

    private var parentInitial: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return String((name.isEmpty ? (state.account?.email ?? "P") : name).prefix(1)).uppercased()
    }

    private var hero: some View {
        let count = state.children.count
        return ProfileHero(
            initial: parentInitial,
            title: parentName,
            subtitle: state.account?.email ?? "",
            chips: [
                ProfileHeroChip(symbol: "person.2.fill", text: count == 1 ? "1 child" : "\(count) children"),
                ProfileHeroChip(symbol: "mappin.and.ellipse", text: state.homeLocation.name),
                ProfileHeroChip(symbol: "location", text: "Within \(state.communityRadiusKm) km")
            ],
            actionSymbol: "pencil", actionLabel: "Edit your details",
            action: { showParentEdit = true })
    }

    // MARK: Exam reminder

    @ViewBuilder private var examBanner: some View {
        let urgent = state.children.filter(\.examNeedsAttention)
        if !urgent.isEmpty {
            VStack(spacing: 10) {
                ForEach(urgent) { child in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(child.displayName)’s exam form")
                                .scaledFont(16, weight: .semibold, maxScale: 1.25)
                                .foregroundStyle(Theme.ink)
                            Text(bannerText(for: child))
                                .scaledFont(14, maxScale: 1.3)
                                .foregroundStyle(Theme.gatherText)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xFFEBD9), in: .rect(cornerRadius: 22))
                    .accessibilityElement(children: .combine)
                }
            }
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

    // MARK: Parent tab

    private var bioBinding: Binding<String> {
        Binding(get: { state.account?.bio ?? "" },
                set: { state.updateCommunityProfile(bio: $0) })
    }

    private var lookingFor: [String] { state.account?.lookingFor ?? [] }

    private func toggleLookingFor(_ option: String) {
        var current = lookingFor
        if let index = current.firstIndex(of: option) { current.remove(at: index) } else { current.append(option) }
        state.updateCommunityProfile(lookingFor: current)
    }

    private var parentTab: some View {
        VStack(spacing: 18) {
            ProfileCard(symbol: "person.crop.circle", title: "Your details") {
                VStack(spacing: 6) {
                    Button { showParentEdit = true } label: {
                        ProfileInfoRow(symbol: "phone", title: "Mobile",
                                       value: (state.account?.mobile).flatMap { $0.isEmpty ? nil : $0 } ?? "Add a number")
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                    ProfileInfoRow(symbol: "envelope", title: "Email",
                                   value: state.account?.email ?? "Not set", showsChevron: false)
                }
            }

            ProfileCard(symbol: "text.quote", title: "A little about us",
                        subtitle: "Shown on your community profile") {
                TextField("Tell other families a little about you", text: bioBinding, axis: .vertical)
                    .lineLimit(3...8)
                    .scaledFont(16, maxScale: 1.3)
                    .foregroundStyle(Theme.ink)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.lilac, in: .rect(cornerRadius: 18))
            }

            ProfileCard(symbol: "person.2.wave.2", title: "Looking to connect for",
                        subtitle: "Pick as many as you like") {
                FlowLayout(spacing: 8) {
                    ForEach(CommunityOptions.lookingFor, id: \.self) { option in
                        SelectableChip(title: option, isOn: lookingFor.contains(option)) {
                            toggleLookingFor(option)
                        }
                    }
                }
            }

            previewCard
        }
    }

    /// Opens the profile as another parent sees it.
    private var previewCard: some View {
        NavigationLink {
            ConnectView(parent: communityPreview, isPreview: true)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("See how other parents see you")
                        .scaledFont(18, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.leading)
                    Text("Only an approximate distance is shared.")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.ink.opacity(0.65))
                        .multilineTextAlignment(.leading)
                    Label("Preview", systemImage: "eye")
                        .scaledFont(14, weight: .semibold, maxScale: 1.2)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .frame(height: 38)
                        .background(Capsule().fill(Theme.ink))
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
                Image("HomeMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 84)
                    .accessibilityHidden(true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.pink.opacity(0.55), in: .rect(cornerRadius: 26))
        }
        .buttonStyle(.plain)
    }

    /// The profile as another parent would see it.
    private var communityPreview: Parent {
        let kids = state.children.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let interests = CommunityOptions.interests.filter { name in kids.contains { $0.interests.contains(name) } }
        let levels = Dictionary(uniqueKeysWithValues: kids.map { ($0.id, $0.level.isEmpty ? "" : levelText($0)) })
        return Parent(
            name: parentName, role: kids.isEmpty ? "Parent" : "Parent to " + kids.map(\.name).joined(separator: " & "),
            tags: "", distanceKm: 0, about: "", bio: state.account?.bio ?? "",
            children: kids.map { child in
                ParentChild(name: child.name,
                            age: child.birthDate.map { AgeRules.age(of: $0, on: .now) } ?? 0,
                            level: levels[child.id] ?? "")
            },
            interests: interests, lookingFor: lookingFor)
    }

    // MARK: Children tab

    private var childrenTab: some View {
        VStack(spacing: 18) {
            ForEach(Array(state.children.enumerated()), id: \.element.id) { index, child in
                childCard(child, color: avatarColors[index % avatarColors.count])
            }

            Button { showAdd = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
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

    private func toggleInterest(_ name: String, for child: Child) {
        guard let index = state.children.firstIndex(where: { $0.id == child.id }) else { return }
        if state.children[index].interests.contains(name) {
            state.children[index].interests.remove(name)
        } else {
            state.children[index].interests.insert(name)
        }
    }

    private func childCard(_ child: Child, color: Color) -> some View {
        let isCurrent = child.id == state.selectedChildID

        return ProfileCard {
            Button { openHome(with: child) } label: {
                HStack(spacing: 14) {
                    Text(String(child.displayName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 58, height: 58)
                        .background(Circle().fill(color))
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
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.dotInactive)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(child.displayName). Open Home")

            ProfileDivider()

            VStack(spacing: 4) {
                editRow("graduationcap", "NIOS level", levelText(child)) { levelTarget = child }
                editRow("calendar", "Date of birth", dobText(child)) {
                    editTarget = EditTarget(child: child, step: 1, singleStep: false)
                }
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

            Button { editTarget = EditTarget(child: child, step: 1, singleStep: false) } label: {
                Label("Edit all details", systemImage: "pencil")
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Capsule().fill(Theme.chipFill))
            }
            .buttonStyle(.plain)
        }
    }

    private func editRow(_ symbol: String, _ title: String, _ value: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ProfileInfoRow(symbol: symbol, title: title, value: value)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(value). Edit")
    }

    /// Picks the child and goes back to Home.
    private func openHome(with child: Child) {
        state.selectChild(child.id)
        dismiss()
    }

    // MARK: Settings tab

    private var settingsTab: some View {
        VStack(spacing: 18) {
            ProfileCard(symbol: "location", title: "Your area",
                        subtitle: "Used for “Near you” in Gather and Community") {
                VStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { state.usesLiveLocation },
                        set: { on in
                            state.setLiveLocation(on)
                            // Without live location the family chooses a city.
                            if !on { showLocationPicker = true }
                        })) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use my approximate live location")
                                .scaledFont(16, maxScale: 1.25)
                                .foregroundStyle(Theme.ink)
                            Text("Never your exact position.")
                                .scaledFont(13, maxScale: 1.3)
                                .foregroundStyle(Theme.gatherText)
                        }
                    }
                    .tint(Theme.tabSelected)

                    ProfileDivider()

                    if state.usesLiveLocation {
                        HStack {
                            ProfileInfoRow(symbol: "mappin.and.ellipse", title: "Area",
                                           value: state.locationService.status == .locating ? "" : state.homeLocation.name,
                                           showsChevron: false)
                            if state.locationService.status == .locating { ProgressView() }
                        }
                    } else {
                        Button { showLocationPicker = true } label: {
                            ProfileInfoRow(symbol: "building.2", title: "City", value: state.homeLocation.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ProfileCard(symbol: "scope", title: "Community distance",
                        subtitle: "How far to look for other parents") {
                FlowLayout(spacing: 8) {
                    ForEach([1, 2, 3, 5, 10, 20], id: \.self) { km in
                        SelectableChip(title: "\(km) km", isOn: state.communityRadiusKm == km) {
                            state.communityRadiusKm = km
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.title3)
                    .foregroundStyle(Theme.gatherAccent)
                Text("Other families only see an approximate distance. Your exact location stays private.")
                    .scaledFont(14, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
            }
            .padding(.horizontal, 6)
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
