import SwiftUI
import UserNotifications

// MARK: - AppInfo

/// Replace these before release. They are placeholders so the rows work in the prototype.
enum AppInfo {
    static let supportEmail = "support@example.com"
    static let helpURL = URL(string: "https://example.com/help")!
    static let termsURL = URL(string: "https://example.com/terms")!
    static let privacyURL = URL(string: "https://example.com/privacy")!
    static let shareURL = URL(string: "https://example.com/homeschool")!
}

// MARK: - SettingsSection

enum SettingsSection { case notifications, privacy, help, about, account }

// MARK: - SettingsTab

/// One page of settings: notifications, privacy, help, about or account.
struct SettingsTab: View {
    let section: SettingsSection
    @Binding var showLocationPicker: Bool

    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var confirmAddAccount = false
    @State private var confirmSignOut = false
    @State private var confirmDelete = false

    var body: some View {
        VStack(spacing: 18) {
            switch section {
            case .notifications: notificationsCard
            case .privacy:       privacyCard
            case .help:          helpCard
            case .about:         aboutCard
            case .account:       accountCard
            }
        }
        .task {
            notificationStatus = await ExamReminders.authorizationStatus()
            state.syncGatheringReminders()
        }
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
                            state.syncGatheringReminders()
                        }
                    } label: {
                        ProfileInfoRow(symbol: "bell.badge", title: "Allow notifications", value: "Turn on")
                    }
                    .buttonStyle(.plain)
                    ProfileDivider()
                default:
                    EmptyView()
                }

                toggleRow("Chat messages", symbol: "bubble.left", isOn: Binding(get: { state.preferences.notifyChats }, set: { state.preferences.notifyChats = $0 }))
                ProfileDivider()
                toggleRow("Connection requests", symbol: "person.badge.plus", isOn: Binding(get: { state.preferences.notifyCommunity }, set: { state.preferences.notifyCommunity = $0 }))
                ProfileDivider()
                toggleRow("Gathering reminders", "One hour before registered or saved events.",
                          symbol: "calendar", isOn: Binding(get: { state.preferences.notifyGatherings }, set: { state.preferences.notifyGatherings = $0 }))
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
                toggleRow("Show my profile to other parents", "Turn off to hide your profile and stop new connection requests.",
                          symbol: "person.crop.circle", isOn: Binding(get: { state.preferences.showProfile }, set: { state.preferences.showProfile = $0 }))
                ProfileDivider()
                NavigationLink {
                    BlockedChatsView()
                } label: {
                    ProfileInfoRow(symbol: "nosign", title: "Blocked chats",
                                   value: blocked == 0 ? "None" : "\(blocked)")
                }
                .buttonStyle(.plain)

                Label("Other parents only see your area, never where you are.", systemImage: "checkmark.shield")
                    .scaledFont(13, maxScale: 1.3)
                    .foregroundStyle(Theme.gatherText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
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
                .scaledFont(18, weight: .bold)
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
                .scaledFont(14, weight: .semibold)
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
                .scaledFont(14, weight: .semibold)
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
