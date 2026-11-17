import SwiftUI
import Security

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
