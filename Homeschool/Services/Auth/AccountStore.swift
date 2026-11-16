import SwiftUI

/// Accounts kept on this device so the "existing vs new user" flow can be tested without a backend.
/// Replace every function here with calls to your real server.
// TODO: Prototype only. Accounts are stored in UserDefaults and nothing is verified; swap in real authentication.
enum AccountStore {
    /// Profiles of the mock accounts (stored with `@AppStorage`; a real server replaces this).
    @AppStorage("mock.accounts") private static var storedAccounts = Data()

    private static var all: [String: Account] {
        get { (try? JSONDecoder().decode([String: Account].self, from: storedAccounts)) ?? [:] }
        set { storedAccounts = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// Keychain session email; the static prototype also retains its selected local profile.
    private static let currentKey = "mock.currentEmail"
    /// The local prototype also remembers the selected profile when Keychain is unavailable.
    @AppStorage("mock.selectedAccountEmail") private static var selectedEmail: String?
    @AppStorage("mock.hasSelectedAccount") private static var hasSelectedAccount = false

    /// The account that is signed in on this device.
    static var current: Account? {
        if hasSelectedAccount {
            guard let email = selectedEmail else { return nil }
            return all[normalized(email)]
        }
        guard let email = Keychain.string(for: currentKey) else { return nil }
        guard let account = all[normalized(email)] else { return nil }
        select(email)
        return account
    }

    /// Older builds could save a completed family without retaining its selected account.
    /// Recover only an unambiguous legacy profile; explicit sign-out must stay signed out.
    static func recoverLegacySession() -> Account? {
        if let current { return current }
        guard !hasSelectedAccount, all.count == 1, let account = all.values.first else { return nil }
        select(account.email)
        return account
    }

    private static func select(_ email: String?) {
        selectedEmail = email.map(normalized)
        hasSelectedAccount = true
        Keychain.set(selectedEmail, for: currentKey)
    }

    static func update(_ account: Account) {
        var accounts = all
        accounts[normalized(account.email)] = account
        all = accounts
    }

    /// Every account saved on this device.
    static var savedAccounts: [Account] {
        Array(all.values).sorted { $0.email < $1.email }
    }

    /// Makes another saved account the signed-in one.
    static func switchTo(_ email: String) {
        let key = normalized(email)
        guard all[key] != nil else { return }
        select(key)
    }

    /// Ends the session on this device. The account itself stays.
    static func signOut() {
        select(nil)
    }

    /// Removes the account and ends the session.
    static func delete(_ email: String) {
        var accounts = all
        accounts.removeValue(forKey: normalized(email))
        all = accounts
        select(nil)
    }

    /// Pure string clean-up with no shared state, so it is safe to call from any isolation context.
    /// (The project defaults every type to the main actor, which made this helper main-actor-only.)
    nonisolated static func normalized(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func exists(_ email: String) -> Bool {
        all[normalized(email)] != nil
    }

    /// Existing account: signs in (and fills a missing name). New email: creates the account automatically.
    @discardableResult
    static func signInOrCreate(email: String, name: String?) -> Account {
        let id = normalized(email)
        var accounts = all
        var account = accounts[id] ?? Account(email: id, name: "")
        if account.name.isEmpty, let name, !name.isEmpty { account.name = name }
        accounts[id] = account
        all = accounts
        select(id)
        return account
    }
}
