import Foundation
import Observation

/// Shared settings drive the local demo experience as well as the switches in Settings.
@MainActor @Observable final class AppPreferences {
    private let defaults: UserDefaults
    var notifyChats: Bool { didSet { defaults.set(notifyChats, forKey: "pref.notifyChats") } }
    var notifyCommunity: Bool { didSet { defaults.set(notifyCommunity, forKey: "pref.notifyCommunity") } }
    var notifyGatherings: Bool {
        didSet {
            defaults.set(notifyGatherings, forKey: "pref.notifyGatherings")
            onGatheringChange?()
        }
    }
    var showProfile: Bool { didSet { defaults.set(showProfile, forKey: "pref.showProfile") } }
    @ObservationIgnored var onGatheringChange: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        notifyChats = defaults.object(forKey: "pref.notifyChats") as? Bool ?? true
        notifyCommunity = defaults.object(forKey: "pref.notifyCommunity") as? Bool ?? true
        notifyGatherings = defaults.object(forKey: "pref.notifyGatherings") as? Bool ?? true
        showProfile = defaults.object(forKey: "pref.showProfile") as? Bool ?? true
    }
}
