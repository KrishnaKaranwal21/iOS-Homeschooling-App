import SwiftUI
import UserNotifications

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

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 18) {
                Color.clear.frame(height: 0).id("profile-top")
                examBanner
                // The profile card belongs to the Parent tab only.
                if tab == .parent { hero }

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
        // Switching tabs always starts at the top of the new tab.
        .onChange(of: tab) { proxy.scrollTo("profile-top", anchor: .top) }
        }
        .background(Theme.background)
        .navigationTitle("Profile")
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
            actionSymbol: "pencil", actionLabel: "Edit details",
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
                set: { state.updateCommunityProfile(bio: String($0.prefix(Self.bioLimit))) })
    }

    private static let bioLimit = 240

    private var lookingFor: [String] { state.account?.lookingFor ?? [] }

    private func toggleLookingFor(_ option: String) {
        var current = lookingFor
        if let index = current.firstIndex(of: option) { current.remove(at: index) } else { current.append(option) }
        state.updateCommunityProfile(lookingFor: current)
    }

    /// How far the profile is filled in, and what is still missing.
    @ViewBuilder private var completenessCard: some View {
        let missing = state.missingProfileItems
        if !missing.isEmpty {
            let total = 2 + 3 * max(state.children.count, 1)
            let done = max(0, total - missing.count)
            ProfileCard(symbol: "checkmark.seal", title: "Finish your profile",
                        subtitle: "\(done) of \(total) steps done") {
                VStack(alignment: .leading, spacing: 14) {
                    ProgressView(value: Double(done), total: Double(total))
                        .tint(Theme.tabSelected)
                    FlowLayout(spacing: 8) {
                        ForEach(missing, id: \.self) { InfoChip(title: $0, tint: Theme.chipFill, isCompact: true) }
                    }
                    Button {
                        let parentMissing = missing.contains("Your name") || missing.contains("Your mobile number")
                        if parentMissing { showParentEdit = true } else { tab = .children }
                    } label: {
                        Text("Add missing details")
                            .scaledFont(15, weight: .semibold, maxScale: 1.25)
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(Capsule().fill(Theme.lavender))
                    }
                    .buttonStyle(.plain)
                    Text("These are needed before you can host an event.")
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                }
            }
        }
    }

    private var parentTab: some View {
        VStack(spacing: 18) {
            ProfileStatsCard(items: [
                .init(value: "\(state.children.count)", label: state.children.count == 1 ? "Child" : "Children"),
                .init(value: "\(state.registrations.count)", label: "Registered"),
                .init(value: "\(state.savedEvents.count)", label: "Saved"),
                .init(value: "\(state.requestedParents.count)", label: "Requests")
            ])

            completenessCard

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
                VStack(alignment: .trailing, spacing: 6) {
                    TextField("Tell other families a little about you", text: bioBinding, axis: .vertical)
                        .lineLimit(3...8)
                        .scaledFont(16, maxScale: 1.3)
                        .foregroundStyle(Theme.ink)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.lilac, in: .rect(cornerRadius: 18))
                    Text("\((state.account?.bio ?? "").count)/\(Self.bioLimit)")
                        .scaledFont(12, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .padding(.trailing, 4)
                }
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
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.gatherText)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.lilac, in: .rect(cornerRadius: 26))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
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
                            level: levels[child.id] ?? "",
                            interests: CommunityOptions.interests.filter { child.interests.contains($0) })
            },
            interests: interests, lookingFor: lookingFor)
    }

    // MARK: Children tab

    private var childrenTab: some View {
        VStack(spacing: 18) {
            ForEach(state.children) { child in
                childCard(child)
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

    private func childCard(_ child: Child) -> some View {
        let isCurrent = child.id == state.selectedChildID

        return ProfileCard {
            Button { openHome(with: child) } label: {
                HStack(spacing: 14) {
                    Text(String(child.displayName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold))
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
        SettingsTab(showLocationPicker: $showLocationPicker)
    }

    // MARK: Text helpers

    private func levelText(_ child: Child) -> String {
        guard !child.level.isEmpty else { return "Not set" }
        return Curriculum.displayName(for: child.level)
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


// MARK: - Settings

/// Replace these before release. They are placeholders so the rows work in the prototype.
private enum AppInfo {
    static let supportEmail = "support@example.com"
    static let helpURL = URL(string: "https://example.com/help")!
    static let termsURL = URL(string: "https://example.com/terms")!
    static let privacyURL = URL(string: "https://example.com/privacy")!
    static let shareURL = URL(string: "https://example.com/homeschool")!
}

/// The settings a person expects in an app: notifications, privacy, help, about and account.
private struct SettingsTab: View {
    @Binding var showLocationPicker: Bool

    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL

    @AppStorage("pref.notifyChats") private var notifyChats = true
    @AppStorage("pref.notifyCommunity") private var notifyCommunity = true
    @AppStorage("pref.notifyGatherings") private var notifyGatherings = true
    @AppStorage("pref.showProfile") private var showProfile = true
    @AppStorage("pref.showDistance") private var showDistance = true

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var confirmAddAccount = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 18) {
            notificationsCard
            privacyCard
            helpCard
            aboutCard
            accountCard
        }
        .task { notificationStatus = await ExamReminders.authorizationStatus() }
        .confirmationDialog("Add another account?", isPresented: $confirmAddAccount, titleVisibility: .visible) {
            Button("Continue") { state.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You’ll sign in with a different email. This account stays on your device, and you can switch back to it from Settings.")
        }
        .confirmationDialog("Sign out?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { state.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You can sign back in with your email. Your family’s details stay on this device.")
        }
        .confirmationDialog("Delete your account?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) { state.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes your account, your children’s details, your chats and your registrations from this device. It can’t be undone.")
        }
    }

    // MARK: Notifications

    private var notificationsCard: some View {
        ProfileCard(symbol: "bell", title: "Notifications") {
            VStack(spacing: 12) {
                switch notificationStatus {
                case .denied:
                    Button {
                        if let url = URL(string: "app-settings:") { openURL(url) }
                    } label: {
                        ProfileInfoRow(symbol: "bell.slash", title: "Turned off in iOS", value: "Open Settings")
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                case .notDetermined:
                    Button {
                        Task {
                            _ = await ExamReminders.requestAuthorization()
                            notificationStatus = await ExamReminders.authorizationStatus()
                        }
                    } label: {
                        ProfileInfoRow(symbol: "bell.badge", title: "Allow notifications", value: "Turn on")
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                default:
                    EmptyView()
                }

                toggleRow("Chat messages", symbol: "bubble.left", isOn: $notifyChats)
                ProfileDivider()
                toggleRow("Connection requests", symbol: "person.badge.plus", isOn: $notifyCommunity)
                ProfileDivider()
                toggleRow("Gathering reminders", "Events you registered for or saved.",
                          symbol: "calendar", isOn: $notifyGatherings)
            }
        }
    }

    // MARK: Privacy

    private var privacyCard: some View {
        let blocked = state.chats.threads.filter(\.isBlocked).count
        return ProfileCard(symbol: "lock", title: "Privacy") {
            VStack(spacing: 12) {
                toggleRow("Use my live location", "Keeps your area up to date automatically.",
                          symbol: "location.fill",
                          isOn: Binding(
                            get: { state.usesLiveLocation },
                            set: { on in
                                state.setLiveLocation(on)
                                // Without live location the family chooses a city.
                                if !on { showLocationPicker = true }
                            }))
                ProfileDivider()
                if state.usesLiveLocation {
                    HStack {
                        ProfileInfoRow(symbol: "mappin.and.ellipse", title: "Location",
                                       value: state.locationService.status == .locating ? "" : state.homeLocation.name,
                                       showsChevron: false)
                        if state.locationService.status == .locating { ProgressView() }
                    }
                } else {
                    Button { showLocationPicker = true } label: {
                        ProfileInfoRow(symbol: "mappin.and.ellipse", title: "Select location",
                                       value: state.homeLocation.name)
                    }
                    .buttonStyle(.plain)
                }
                ProfileDivider()
                toggleRow("Show my profile to other parents", "Turn off to hide yourself in Community.",
                          symbol: "person.crop.circle", isOn: $showProfile)
                ProfileDivider()
                toggleRow("Show distance to other parents", "Only a rounded distance is shared, never where you are.",
                          symbol: "mappin", isOn: $showDistance)
                ProfileDivider()
                NavigationLink {
                    BlockedChatsView()
                } label: {
                    ProfileInfoRow(symbol: "nosign", title: "Blocked chats",
                                   value: blocked == 0 ? "None" : "\(blocked)")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Help and about

    private var helpCard: some View {
        ProfileCard(symbol: "questionmark.circle", title: "Help") {
            VStack(spacing: 12) {
                Button { openURL(AppInfo.helpURL) } label: {
                    ProfileInfoRow(symbol: "book", title: "Help centre", value: "")
                }
                .buttonStyle(.plain)
                ProfileDivider()
                Button {
                    if let url = URL(string: "mailto:\(AppInfo.supportEmail)?subject=Homeschool%20support") { openURL(url) }
                } label: {
                    ProfileInfoRow(symbol: "envelope", title: "Contact support", value: "")
                }
                .buttonStyle(.plain)
                ProfileDivider()
                ShareLink(item: AppInfo.shareURL,
                          message: Text("Homeschool helps families plan learning and meet other homeschoolers.")) {
                    ProfileInfoRow(symbol: "square.and.arrow.up", title: "Share the app", value: "")
                }
                .buttonStyle(.plain)
                ProfileDivider()
                Button {
                    if let url = URL(string: "app-settings:") { openURL(url) }
                } label: {
                    ProfileInfoRow(symbol: "globe", title: "Language", value: "iOS Settings")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aboutCard: some View {
        ProfileCard(symbol: "info.circle", title: "About") {
            VStack(spacing: 12) {
                Button { openURL(AppInfo.termsURL) } label: {
                    ProfileInfoRow(symbol: "doc.text", title: "Terms of Service", value: "")
                }
                .buttonStyle(.plain)
                ProfileDivider()
                Button { openURL(AppInfo.privacyURL) } label: {
                    ProfileInfoRow(symbol: "hand.raised", title: "Privacy Policy", value: "")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Account

    private func accountRow(_ account: Account, trailing: some View) -> some View {
        HStack(spacing: 12) {
            Text(String((account.name.isEmpty ? account.email : account.name).prefix(1)).uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Theme.lavender))
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name.isEmpty ? "Your account" : account.name)
                    .scaledFont(16, weight: .semibold, maxScale: 1.25)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(account.email)
                    .scaledFont(13, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            trailing
        }
    }

    private var accountCard: some View {
        ProfileCard(symbol: "person.crop.circle", title: "Account") {
            VStack(spacing: 12) {
                if let current = state.account {
                    accountRow(current, trailing:
                        Text("Signed in")
                            .scaledFont(12, weight: .semibold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Theme.lavender)))
                }

                ForEach(state.otherAccounts, id: \.email) { other in
                    ProfileDivider()
                    accountRow(other, trailing:
                        Button { state.switchAccount(to: other.email) } label: {
                            Text("Switch")
                                .scaledFont(14, weight: .semibold, maxScale: 1.2)
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 14)
                                .frame(height: 34)
                                .background(Capsule().fill(Theme.chipFill))
                        }
                        .buttonStyle(.plain))
                }

                ProfileDivider()
                Button { confirmAddAccount = true } label: {
                    ProfileInfoRow(symbol: "person.badge.plus", title: "Add another account", value: "")
                }
                .buttonStyle(.plain)
                ProfileDivider()
                Button { confirmSignOut = true } label: {
                    ProfileInfoRow(symbol: "rectangle.portrait.and.arrow.right", title: "Sign out", value: "")
                }
                .buttonStyle(.plain)
                ProfileDivider()
                Button { confirmDelete = true } label: {
                    destructiveRow("trash", "Delete account")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Rows

    private func toggleRow(_ title: String, _ subtitle: String? = nil, symbol: String,
                           isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.gatherAccent)
                .frame(width: 32, height: 32)
                .background(Theme.lilac, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .scaledFont(16, maxScale: 1.25)
                        .foregroundStyle(Theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .scaledFont(13, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                    }
                }
            }
            .tint(Theme.tabSelected)
        }
    }

    private func destructiveRow(_ symbol: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.red)
                .frame(width: 32, height: 32)
                .background(Color.red.opacity(0.1), in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            Text(title)
                .scaledFont(16, maxScale: 1.25)
                .foregroundStyle(Color.red)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
    }
}

/// Chats the parent blocked, with a way to unblock them.
private struct BlockedChatsView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let blocked = state.chats.threads.filter(\.isBlocked)
        ScrollView {
            VStack(spacing: 18) {
                if blocked.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "nosign")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.tabIconInactive)
                        Text("No blocked chats")
                            .scaledFont(18, weight: .bold, maxScale: 1.2)
                            .foregroundStyle(Theme.ink)
                        Text("People you block can’t message you. They show up here so you can unblock them.")
                            .scaledFont(15, maxScale: 1.3)
                            .foregroundStyle(Theme.gatherText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 80)
                    .padding(.horizontal, 24)
                } else {
                    ProfileCard {
                        VStack(spacing: 12) {
                            ForEach(Array(blocked.enumerated()), id: \.element.id) { index, thread in
                                HStack(spacing: 14) {
                                    ChatAvatar(thread: thread, size: 44)
                                    Text(thread.title)
                                        .scaledFont(17, maxScale: 1.25)
                                        .foregroundStyle(Theme.ink)
                                        .lineLimit(1)
                                    Spacer(minLength: 8)
                                    Button { state.chats.toggleBlock(thread.id) } label: {
                                        Text("Unblock")
                                            .scaledFont(14, weight: .semibold, maxScale: 1.2)
                                            .foregroundStyle(Theme.ink)
                                            .padding(.horizontal, 14)
                                            .frame(height: 34)
                                            .background(Capsule().fill(Theme.lavender))
                                    }
                                    .buttonStyle(.plain)
                                }
                                if index < blocked.count - 1 { ProfileDivider() }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(Theme.background)
        .navigationTitle("Blocked chats")
        .navigationBarTitleDisplayMode(.inline)
    }
}
