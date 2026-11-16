import SwiftUI

// MARK: - ProfilePage

/// Which page of the profile is shown. `hub` is the main Profile page: a short list of buttons,
/// each opening its own page, like most apps.
enum ProfilePage {
    case hub, parent, children, notifications, privacy, help, about, account
}

// MARK: - ProfileView

/// The family's profile. The main page is a small menu. Details live one tap away.
/// What other parents see on the community profile is edited here too.
struct ProfileView: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    struct EditTarget: Identifiable {
        let id = UUID()
        let child: Child
        let step: Int
        let singleStep: Bool
    }

    let page: ProfilePage

    init(page: ProfilePage = .hub) {
        self.page = page
    }

    @State var editTarget: EditTarget?
    @State var showAdd = false
    @State var showParentEdit = false
    @State var showLocationPicker = false
    @State var goToChildren = false
    @State var showRename = false
    @State var renameID: Child.ID?
    @State var renameText = ""
    @State var showRemove = false
    @State var showCannotRemove = false
    @State var removeID: Child.ID?
    @State var removeName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Room for the floating back button. There is no bar across the top.
                Color.clear.frame(height: 46)
                if page != .hub {
                    Text(pageTitle)
                        .scaledFont(32, weight: .bold, maxScale: 1.2)
                        .tracking(-0.8)
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                switch page {
                case .hub:           hubContent
                case .parent:        parentTab
                case .children:      childrenTab
                case .notifications: SettingsTab(section: .notifications, showLocationPicker: $showLocationPicker)
                case .privacy:       SettingsTab(section: .privacy, showLocationPicker: $showLocationPicker)
                case .help:          SettingsTab(section: .help, showLocationPicker: $showLocationPicker)
                case .about:         SettingsTab(section: .about, showLocationPicker: $showLocationPicker)
                case .account:       SettingsTab(section: .account, showLocationPicker: $showLocationPicker)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollTitleBar(pageTitle)
        .background(Theme.background)
        .overlay(alignment: .topLeading) { backButton }
        // No navigation bar at all: the page has its own heading and a floating back button.
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        // The tab bar (Home, Progress, Gather ...) is hidden here too, so Profile has the whole screen.
        .toolbarVisibility(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $goToChildren) { ProfileView(page: .children) }
        .fullScreenCover(item: $editTarget) { target in
            EditChildFlow(child: target.child, startStep: target.step, singleStep: target.singleStep)
        }
        .fullScreenCover(isPresented: $showAdd) { AddChildFlow() }
        .sheet(isPresented: $showParentEdit) { ParentEditSheet() }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerSheet(allowsWorld: false, selection: state.homeLocation,
                                home: state.homeLocation) { state.homeLocation = $0 }
        }
        .alert("Edit name", isPresented: $showRename) {
            TextField("Name", text: $renameText)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) {}
            Button("Save") { saveName() }
        } message: {
            Text("A nickname is absolutely fine.")
        }
        .alert("Can't remove this child", isPresented: $showCannotRemove) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Add another child first. At least one child is needed.")
        }
        .alert("Remove \(removeName)?", isPresented: $showRemove) {
            Button("Remove", role: .destructive) {
                if let id = removeID { state.removeChild(id) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Their plan, subjects and progress will be deleted from this device. This can't be undone.")
        }
        .onChange(of: state.locationService.status) { _, status in
            // If location access was refused, the switch goes back off and a city is needed.
            if status == .denied, state.usesLiveLocation {
                state.usesLiveLocation = false
                showLocationPicker = true
            }
        }
    }

    // MARK: Top bar and main menu

    var pageTitle: String {
        switch page {
        case .hub: "Profile"
        case .parent: "Your profile"
        case .children: "Children"
        case .notifications: "Notifications"
        case .privacy: "Privacy"
        case .help: "Help"
        case .about: "About"
        case .account: "Account"
        }
    }

    /// Just a round back button floating over the page. It has no bar behind it.
    var backButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "chevron.left").accessibilityHidden(true)
                .scaledFont(17, weight: .semibold)
                .foregroundStyle(Theme.ink)
                .frame(width: 44, height: 44)
                .gatherGlass(in: Circle(), tint: Theme.lilac.opacity(0.25))
        }
        .buttonStyle(.plain)
        .padding(.leading, 20)
        .padding(.top, 4)
        .accessibilityLabel("Back")
    }

    var parentName: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "Add your name" : name
    }

    var parentInitial: String {
        let name = state.account?.name.trimmingCharacters(in: .whitespaces) ?? ""
        return String((name.isEmpty ? (state.account?.email ?? "P") : name).prefix(1)).uppercased()
    }

    var hubContent: some View {
        VStack(spacing: 18) {
            examBanner

            // Who is signed in, with a short way to edit.
            HStack(spacing: 16) {
                Text(parentInitial)
                    .scaledFont(30, weight: .bold)
                    .foregroundStyle(Theme.ink)
                    .frame(width: 68, height: 68)
                    .background(Circle().fill(Theme.lavender))
                VStack(alignment: .leading, spacing: 3) {
                    Text(parentName)
                        .scaledFont(22, weight: .bold, maxScale: 1.2)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(state.account?.email ?? "")
                        .scaledFont(14, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 8)
                Button { showParentEdit = true } label: {
                    Image(systemName: "pencil")
                        .scaledFont(15, weight: .semibold)
                        .foregroundStyle(Theme.ink)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(Theme.chipFill))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit your name and mobile number")
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: 28))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 28)

            completenessCard

            menuGroup {
                menuRow(.parent, "person.crop.circle", "Your profile", "Details and what other parents see")
                ProfileDivider()
                menuRow(.children, "person.2", "Children",
                        state.children.map(\.displayName).joined(separator: ", "))
            }

            menuGroup {
                menuRow(.notifications, "bell", "Notifications", "Chats, requests and reminders")
                ProfileDivider()
                menuRow(.privacy, "lock", "Privacy", "Location and who can find you")
            }

            menuGroup {
                menuRow(.help, "questionmark.circle", "Help", "Support and sharing")
                ProfileDivider()
                menuRow(.about, "info.circle", "About", "Terms and privacy policy")
            }

            menuGroup {
                menuRow(.account, "person.crop.circle.badge.checkmark", "Account", "Switch, add or sign out")
            }
        }
    }

    func menuGroup<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: 26))
            .roundedStroke(Theme.lilacBorder, cornerRadius: 26)
    }

    func menuRow(_ target: ProfilePage, _ symbol: String, _ title: String, _ subtitle: String) -> some View {
        NavigationLink {
            ProfileView(page: target)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .scaledFont(16, weight: .semibold)
                    .foregroundStyle(Theme.gatherAccent)
                    .frame(width: 40, height: 40)
                    .background(Theme.lilac, in: .rect(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .scaledFont(17, weight: .semibold, maxScale: 1.25)
                        .foregroundStyle(Theme.ink)
                    Text(subtitle)
                        .scaledFont(13, maxScale: 1.3)
                        .foregroundStyle(Theme.gatherText)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right").accessibilityHidden(true)
                    .scaledFont(12, weight: .semibold)
                    .foregroundStyle(Theme.dotInactive)
            }
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    // MARK: Exam reminder

    @ViewBuilder var examBanner: some View {
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

    func bannerText(for child: Child) -> String {
        guard let days = child.daysUntilExamDeadline else { return "" }
        switch days {
        case ..<0: return "The last date passed \(-days) \(-days == 1 ? "day" : "days") ago. Check with NIOS."
        case 0:    return "The last date to register is today."
        case 1:    return "The last date to register is tomorrow."
        default:   return "\(days) days left to register for the exams."
        }
    }

}

#Preview("Profile") {
    ProfileView()
        .environment(AppState())
}
