import SwiftUI
import Security

// MARK: - Mock account database

struct Account: Codable, Equatable {
    var email: String
    var name: String
    var mobile: String? = nil
    // Optional so accounts saved by earlier versions still load.
    /// "A little about us" on the community profile.
    var bio: String? = nil
    /// What the family wants to connect for (see `CommunityOptions.lookingFor`).
    var lookingFor: [String]? = nil
}

/// Accounts kept on this device so the "existing vs new user" flow can be tested without a backend.
/// Replace every function here with calls to your real server.
enum AccountStore {
    /// Profiles of the mock accounts (stored with `@AppStorage`; a real server replaces this).
    @AppStorage("mock.accounts") private static var storedAccounts = Data()

    private static var all: [String: Account] {
        get { (try? JSONDecoder().decode([String: Account].self, from: storedAccounts)) ?? [:] }
        set { storedAccounts = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// The signed-in session lives in the Keychain, not in UserDefaults.
    private static let currentKey = "mock.currentEmail"

    /// The account that is signed in on this device.
    static var current: Account? {
        guard let email = Keychain.string(for: currentKey) else { return nil }
        return all[email]
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
        Keychain.set(key, for: currentKey)
    }

    /// Ends the session on this device. The account itself stays.
    static func signOut() {
        Keychain.set(nil, for: currentKey)
    }

    /// Removes the account and ends the session.
    static func delete(_ email: String) {
        var accounts = all
        accounts.removeValue(forKey: normalized(email))
        all = accounts
        Keychain.set(nil, for: currentKey)
    }

    static func normalized(_ email: String) -> String {
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
        Keychain.set(id, for: currentKey)
        return account
    }
}

// MARK: - Apple / Google (simulated)

enum SocialProvider {
    case google, apple

    var title: String {
        switch self {
        case .google: return "Google"
        case .apple:  return "Apple"
        }
    }
}

struct SocialProfile {
    let name: String
    let email: String
}

/// Simulated provider sign-in that returns a name and email, like the real SDKs do.
/// To go live:
///  - Apple: add the "Sign in with Apple" capability and use `ASAuthorizationAppleIDProvider`.
///    Apple only sends the name the first time, so save it right away.
///  - Google: add the GoogleSignIn package and call `GIDSignIn.sharedInstance.signIn(withPresenting:)`,
///    then read `user.profile?.name` and `user.profile?.email`.
enum SocialAuth {
    static func signIn(with provider: SocialProvider) async throws -> SocialProfile {
        try await Task.sleep(for: .milliseconds(700))
        switch provider {
        case .apple:  return SocialProfile(name: "Maya Sharma", email: "maya.sharma@icloud.com")
        case .google: return SocialProfile(name: "Maya Sharma", email: "maya.sharma@gmail.com")
        }
    }
}

// MARK: - Keychain

/// Minimal Keychain wrapper for small secrets such as the signed-in session.
enum Keychain {
    private static func baseQuery(_ key: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrAccount as String: key]
    }

    static func string(for key: String) -> String? {
        var query = baseQuery(key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Pass `nil` to remove the value.
    static func set(_ value: String?, for key: String) {
        SecItemDelete(baseQuery(key) as CFDictionary)
        guard let value else { return }
        var query = baseQuery(key)
        query[kSecValueData as String] = Data(value.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }
}
