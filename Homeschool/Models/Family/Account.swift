import SwiftUI

// MARK: - Account

struct Account: Codable, Equatable {
    var email: String
    var name: String
    var mobile: String? = nil
    /// Optional so accounts saved by earlier versions still load.
    /// "A little about us" on the community profile.
    var bio: String? = nil
    /// What the family wants to connect for (see `CommunityOptions.lookingFor`).
    var lookingFor: [String]? = nil
}

// MARK: - SocialProvider

enum SocialProvider {
    case google, apple

    var title: String {
        switch self {
        case .google: return "Google"
        case .apple:  return "Apple"
        }
    }
}

// MARK: - SocialProfile

struct SocialProfile {
    let name: String
    let email: String
}
