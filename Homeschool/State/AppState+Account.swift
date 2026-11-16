import SwiftUI

/// Parent account, profile completeness and switching between accounts on one device.
extension AppState {
    /// Reloads the active account from the local AccountStore into observable app state.
    func refreshAccount() {
        account = AccountStore.current
    }

    /// Trims and saves the active parent name and mobile number, then updates observable account data.
    @discardableResult
    func updateAccount(name: String, mobile: String) -> Bool {
        guard var current = account ?? AccountStore.current else { return false }
        current.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        current.mobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        AccountStore.update(current)
        account = current
        return true
    }

    /// Saves what other parents see on the community profile.
    func updateCommunityProfile(bio: String? = nil, lookingFor: [String]? = nil) {
        guard var current = account else { return }
        if let bio { current.bio = bio }
        if let lookingFor { current.lookingFor = lookingFor }
        AccountStore.update(current)
        account = current
    }

    /// What is still missing before someone can host: the parent's name and mobile, and each child's name, level and birth date.
    var missingProfileItems: [String] {
        var missing: [String] = []
        if (account?.name ?? "").trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your name") }
        if (account?.mobile ?? "").trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your mobile number") }
        for child in children {
            let label = child.name.trimmingCharacters(in: .whitespaces).isEmpty ? "your child" : child.name
            if child.name.trimmingCharacters(in: .whitespaces).isEmpty { missing.append("Your child’s name") }
            if child.level.isEmpty { missing.append("NIOS level for \(label)") }
            if child.birthDate == nil { missing.append("Date of birth for \(label)") }
        }
        return missing
    }

    /// What one account keeps: its children, the saved events and the last registration details.
    private struct FamilySnapshot: Codable {
        /// Stores the account child profiles as encoded Data inside its family snapshot.
        var children: Data
        /// Stores the selected child UUID string within the account-specific snapshot.
        var selectedChildID: String
        /// Stores the account liked event keys as encoded Data within its snapshot.
        var bookmarks: Data
        /// Stores the last account registrant as encoded Data for later form prefilling.
        var registrant: Data
    }

    /// Exposes all local family snapshots keyed by normalised account email.
    private var snapshots: [String: FamilySnapshot] {
        get { Self.decode([String: FamilySnapshot].self, from: storedSnapshots) ?? [:] }
        set { storedSnapshots = Self.encode(newValue) }
    }

    /// Saves the current account family profile, selected child, bookmarks, and registrant under its normalised
    /// email.
    private func saveSnapshot() {
        guard let email = account?.email else { return }
        snapshots[AccountStore.normalized(email)] = FamilySnapshot(
            children: Self.encode(children),
            selectedChildID: selectedChildID.uuidString,
            bookmarks: Self.encode(bookmarkedKeys.sorted()),
            registrant: savedRegistrant.map { Self.encode($0) } ?? Data())
    }

    /// Loads an account's own family details. Returns false when it has none yet.
    @discardableResult
    private func restoreSnapshot(for email: String) -> Bool {
        guard let snapshot = snapshots[AccountStore.normalized(email)],
              let saved = Self.decode([Child].self, from: snapshot.children), !saved.isEmpty else {
            clearFamily()
            return false
        }
        children = saved
        let savedID = UUID(uuidString: snapshot.selectedChildID)
        selectedChildID = saved.contains { $0.id == savedID } ? (savedID ?? saved[0].id) : saved[0].id
        bookmarkedKeys = Set(Self.decode([String].self, from: snapshot.bookmarks) ?? [])
        storedBookmarks = Self.encode(bookmarkedKeys.sorted())
        savedRegistrant = Self.decode(Registrant.self, from: snapshot.registrant)
        storedRegistrant = snapshot.registrant
        return true
    }

    /// Empties the family details, for a different account that starts from scratch.
    private func clearFamily() {
        children = [Child.empty]
        selectedChildID = children[0].id
        bookmarkedKeys = []
        savedRegistrant = nil
        storedBookmarks = Data()
        storedRegistrant = Data()
        registrations = [:]
        for index in events.indices { events[index].updateRegistration(false) }
    }

    /// Called after a successful login. An account that already has family details goes straight to Home.
    func finishLogin(returning: Bool) {
        refreshAccount()
        restoreEvents()
        let hadFamily = account.map { restoreSnapshot(for: $0.email) } ?? false
        restoreBookings()
        setReturningUser(returning)
        advance(to: hadFamily ? .main : .setup)
    }

    /// Other accounts saved on this device.
    var otherAccounts: [Account] {
        let current = AccountStore.normalized(account?.email ?? "")
        return AccountStore.savedAccounts.filter { AccountStore.normalized($0.email) != current }
    }

    /// Switches to another saved account without signing in again.
    func switchAccount(to email: String) {
        saveSnapshot()
        AccountStore.switchTo(email)
        finishLogin(returning: true)
    }

    /// Signs out and goes back to the login page. The family's details are kept with the account.
    func signOut() {
        saveSnapshot()
        clearFamily()
        AccountStore.signOut()
        account = nil
        storedStage = nil
        stage = .login
    }

    /// Removes the account and everything saved on this device, then starts again from onboarding.
    func deleteAccount() {
        let childKeys = Set(children.map { $0.id.uuidString })
        weeklyPlans = weeklyPlans.filter { key, _ in
            !childKeys.contains(key) && !childKeys.contains(where: { key.hasPrefix("history|\($0)|") })
        }
        chats.deleteSavedChats()
        LocalArchive.remove("events", account: eventArchiveAccount)
        restoringEvents = true
        events = MockData.events.sorted { $0.start < $1.start }
        restoringEvents = false
        if let email = account?.email {
            snapshots.removeValue(forKey: AccountStore.normalized(email))
            bookingsByAccount.removeValue(forKey: AccountStore.normalized(email))
            AccountStore.delete(email)
        }
        account = nil
        storedChildren = Data()
        storedRegistrant = Data()
        storedBookmarks = Data()
        savedRegistrant = nil
        bookmarkedKeys = []
        registrations = [:]
        chats.reload(withSamples: false)
        resetOnboarding()
    }
}
