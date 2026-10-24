import Foundation

// MARK: - Mock account database

struct Account: Codable, Equatable {
    var email: String
    var name: String
    var mobile: String? = nil
}

/// Accounts kept on this device so the "existing vs new user" flow can be tested without a backend.
/// Replace every function here with calls to your real server.
enum AccountStore {
    private static let key = "mock.accounts"

    private static var all: [String: Account] {
        get {
            guard let data = UserDefaults.standard.data(forKey: key),
                  let decoded = try? JSONDecoder().decode([String: Account].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            }
        }
    }

    private static let currentKey = "mock.currentEmail"

    /// The account that is signed in on this device.
    static var current: Account? {
        guard let email = UserDefaults.standard.string(forKey: currentKey) else { return nil }
        return all[email]
    }

    static func update(_ account: Account) {
        var accounts = all
        accounts[normalized(account.email)] = account
        all = accounts
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
        UserDefaults.standard.set(id, forKey: currentKey)
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
