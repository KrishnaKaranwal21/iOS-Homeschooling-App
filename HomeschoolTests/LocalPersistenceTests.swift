import Foundation
import XCTest
@testable import Homeschool

/// Saving and loading local archives per account, and the stored notification preferences.
@MainActor
final class LocalPersistenceTests: XCTestCase {
    func testLocalPersistence() throws {
        let account = "audit-" + UUID().uuidString
        let other = account + "-other"
        defer {
            LocalArchive.remove("checks", account: account)
            LocalArchive.remove("checks", account: other)
        }
        struct Record: Codable, Equatable { var id: UUID; var text: String; var bytes: Data }
        let record = Record(id: UUID(), text: "Saved learning notes", bytes: Data([0, 1, 255]))
        expect(LocalArchive.save([record], category: "checks", account: account), "Local file is saved atomically")
        expect(LocalArchive.load([Record].self, category: "checks", account: account) == [record], "IDs, text and attachment bytes survive reload")
        expect(LocalArchive.load([Record].self, category: "checks", account: other) == nil, "A different account cannot load this account's records")
        expect(LocalArchive.save([Record](), category: "checks", account: account), "An intentionally empty list is saved")
        expect(LocalArchive.load([Record].self, category: "checks", account: account) == [], "Deleted conversations stay deleted instead of reseeding samples")
        LocalArchive.remove("checks", account: account)
        expect(LocalArchive.load([Record].self, category: "checks", account: account) == nil, "Removing an account archive removes its records")
        let suite = "HomeschoolChecks." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        expect(preferences.notifyChats && preferences.notifyCommunity && preferences.notifyGatherings && preferences.showProfile, "Fresh preferences have the expected defaults")
        var reschedules = 0
        preferences.onGatheringChange = { reschedules += 1 }
        preferences.notifyChats = false
        preferences.notifyCommunity = false
        preferences.notifyGatherings = false
        preferences.showProfile = false
        expect(reschedules == 1, "Changing gathering reminders requests rescheduling")
        let restored = AppPreferences(defaults: defaults)
        expect(!restored.notifyChats && !restored.notifyCommunity && !restored.notifyGatherings && !restored.showProfile, "All switches survive reconstruction")
    }
}
